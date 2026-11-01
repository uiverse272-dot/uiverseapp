import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'auth.dart';
import 'saves.dart';

/// Tries a change this many times on server errors before dropping it, so one
/// bad op can't block the queue behind it.
const int kMaxOpAttempts = 3;

/// Waits between retries. Tests make it instant.
final syncDelayProvider = Provider<Future<void> Function(Duration)>((ref) => Future<void>.delayed);

/// The sync loop, or null without a backend.
final savesSyncProvider = Provider<SavesSync?>((ref) {
  if (ref.watch(apiProvider) == null) return null;
  final sync = SavesSync(ref);
  final lifecycle = AppLifecycleListener(onResume: () => sync.run(full: true));
  ref.listen(authProvider.select((a) => (a.user?.id, a.expired)), (_, _) => sync.accountChanged());
  ref.listen(savesProvider, (_, _) {
    if (ref.read(savesProvider.notifier).outbox.isNotEmpty) sync.run();
  });
  ref.onDispose(() {
    lifecycle.dispose();
    sync.dispose();
  });
  if (ref.read(authProvider).signedIn) sync.run(full: true);
  return sync;
});

/// Moves the outbox to the server, one serial loop per app: merge a guest's
/// saves, send changes in order, then adopt the server's state.
class SavesSync {
  SavesSync(this._ref);

  final Ref _ref;
  bool _running = false;
  bool _again = false;
  bool _full = false;
  bool _disposed = false;
  int _generation = 0;
  int _failures = 0;
  Future<void>? _loop;

  /// Sends what's waiting; [full] also fetches the server's state.
  void run({bool full = false}) {
    _full = _full || full;
    if (_running) {
      _again = true;
      return;
    }
    _loop = _runLoop();
  }

  /// The running loop has finished: for a last send before signing out.
  Future<void> settle() => _loop ?? Future<void>.value();

  /// A different account, or the same one back from an expired session. Work
  /// in flight belongs to the old one, and its answers get discarded.
  void accountChanged() {
    _generation++;
    _failures = 0;
    run(full: true);
  }

  void dispose() => _disposed = true;

  Future<void> _runLoop() async {
    _running = true;
    try {
      do {
        _again = false;
        await _cycle();
      } while (_again && !_disposed);
    } finally {
      _running = false;
    }
  }

  Future<void> _cycle() async {
    final AuthNotifier auth = _ref.read(authProvider.notifier);
    final AuthState account = _ref.read(authProvider);
    final String? userId = account.user?.id;
    final UiverseApi? api = _ref.read(apiProvider);
    if (userId == null || account.expired || api == null) return;
    final int generation = _generation;
    bool stale() => _disposed || generation != _generation || _ref.read(authProvider).user?.id != userId;

    try {
      final String? token = await auth.token();
      if (stale()) return;
      if (token == null) {
        auth.sessionExpired();
        return;
      }
      final SavesNotifier saves = _ref.read(savesProvider.notifier);
      if (saves.pendingMerge case final SavesState guest) {
        await api.mergeSaves(token, guest);
        if (stale()) return;
        saves.mergeDone();
        _full = true;
      }
      if (!await _flush(api, token, saves, stale)) return;
      if (_full) {
        final SavesState server = await api.loadSaves(token);
        if (stale()) return;
        _full = false;
        saves.adopt(server);
      }
    } on ApiException catch (e) {
      debugPrint('saves: sync stopped ($e)');
      // Nothing is lost: the outbox waits for the next resume or change.
      if (e.status == 401 && !stale()) auth.sessionExpired();
    } on PlatformException catch (e) {
      debugPrint('saves: secure storage failed ($e)');
    }
  }

  /// Sends the outbox in order; false if the work went stale. Rethrows what
  /// should stop the loop: signed out, offline or accounts switched off.
  Future<bool> _flush(UiverseApi api, String token, SavesNotifier saves, bool Function() stale) async {
    while (true) {
      final List<SaveOp> ops = saves.outbox;
      if (ops.isEmpty) return true;
      try {
        await api.sendOp(token, ops.first);
        if (stale()) return false;
        _failures = 0;
        saves.ack();
      } on ApiException catch (e) {
        if (e.status == 0 || e.status == 401 || e.status == 503) rethrow;
        if (e.status == 429) {
          await _ref.read(syncDelayProvider)(e.retryAfter ?? const Duration(seconds: 30));
          if (stale()) return false;
          continue;
        }
        if (e.isTransient && ++_failures < kMaxOpAttempts) {
          await _ref.read(syncDelayProvider)(Duration(seconds: 1 << _failures));
          if (stale()) return false;
          continue;
        }
        // Refused for good, or given up on: drop it, and fetch what's true.
        if (stale()) return false;
        debugPrint('saves: dropped ${ops.first.toJson()['type']} ($e)');
        _failures = 0;
        _full = true;
        saves.ack();
      }
    }
  }
}
