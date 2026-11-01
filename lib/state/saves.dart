import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';
import 'prefs.dart';
import 'save_ops.dart';
import 'saves_model.dart';

export 'save_ops.dart';
export 'saves_model.dart';

/// localStorage key shared with the web app (§15). A guest's saves live here.
const String kSavesKey = 'uiv.saves.v1';

/// Signed in, the account on the server is the source of truth and this is
/// its copy on the device. Same key as the web store.
String accountSavesKey(String userId) => 'uiv.saves.u:$userId';

/// Changes the server hasn't confirmed, oldest first. Same key as the web store.
String outboxKey(String userId) => 'uiv.saves.outbox:$userId';

/// A guest's saves waiting to be merged into [userId]'s account. Kept until the
/// server has them, so a killed app retries; the web store has no such retry.
String pendingMergeKey(String userId) => 'uiv.saves.merge:$userId';

final RegExp _accountKeys = RegExp(r'^uiv\.saves\.(u|outbox|merge):');

/// [a] plus whatever of [b] it lacks: the account wins, as in `importSaves`.
SavesState unionSaves(SavesState a, SavesState b) {
  final Set<String> boards = {for (final c in a.collections) c.id};
  return SavesState(
    saves: [...a.saves, for (final s in b.saves) if (!a.isSaved(s.slug)) s],
    collections: [...a.collections, for (final c in b.collections) if (!boards.contains(c.id)) c],
    pins: [
      ...a.pins,
      for (final p in b.pins) if (!a.isPinned(p.slug, p.collectionId)) p,
    ],
  );
}

final savesProvider = NotifierProvider<SavesNotifier, SavesState>(SavesNotifier.new);

class SavesNotifier extends Notifier<SavesState> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  String? get _userId => ref.read(authProvider).user?.id;

  @override
  SavesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final userId = ref.watch(authProvider.select((a) => a.user?.id));
    _settleStorage(prefs, userId);
    if (userId == null) return _parse(prefs.getString(kSavesKey), kSavesKey);
    final cached = _parse(prefs.getString(accountSavesKey(userId)), accountSavesKey(userId));
    final merge = prefs.getString(pendingMergeKey(userId));
    return merge == null ? cached : unionSaves(cached, _parse(merge, pendingMergeKey(userId)));
  }

  /// Puts storage in order for [userId]. Runs whenever the account changes, and
  /// is safe to repeat, so a kill at any point just runs it again next launch.
  void _settleStorage(SharedPreferences prefs, String? userId) {
    final String? mine = userId == null ? null : ':$userId';
    for (final String key in prefs.getKeys().toList()) {
      if (!_accountKeys.hasMatch(key) || (mine != null && key.endsWith(mine))) continue;
      // Another account's copy goes, but a merge that never reached the server
      // is the guest's own saves: they go back.
      if (key.startsWith('uiv.saves.merge:') && !prefs.containsKey(kSavesKey)) {
        prefs.setString(kSavesKey, prefs.getString(key)!).ignore();
      }
      prefs.remove(key).ignore();
    }
    final String? guest = prefs.getString(kSavesKey);
    if (userId == null || guest == null) return;
    final String key = pendingMergeKey(userId);
    final SavesState parsed = _parse(guest, kSavesKey);
    if (parsed.saves.isNotEmpty || parsed.collections.isNotEmpty) {
      final merged = unionSaves(_parse(prefs.getString(key), key), parsed);
      prefs.setString(key, jsonEncode(merged.toJson())).ignore();
    }
    prefs.remove(kSavesKey).ignore();
  }

  SavesState _parse(String? raw, String key) {
    if (raw == null) return const SavesState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return SavesState.fromJson(decoded);
      debugPrint('$key: expected an object, got ${decoded.runtimeType}; starting empty');
    } on Object catch (e) {
      // Corrupt storage must not brick the app — start fresh, like the web store.
      debugPrint('$key: could not parse stored saves ($e); starting empty');
    }
    return const SavesState();
  }

  int _now() => ref.read(clockProvider)().millisecondsSinceEpoch;

  void _write(SavesState next) {
    state = next;
    final userId = _userId;
    // Fire-and-forget: SharedPreferences updates its cache synchronously.
    _prefs
        .setString(userId == null ? kSavesKey : accountSavesKey(userId), jsonEncode(next.toJson()))
        .ignore();
  }

  void _commit(SaveOp op) {
    final next = applyOp(state, op);
    if (identical(next, state)) return;
    final userId = _userId;
    if (userId != null) _writeOutbox(userId, [...outbox, op]);
    _write(next);
  }

  void _writeOutbox(String userId, List<SaveOp> ops) {
    final key = outboxKey(userId);
    if (ops.isEmpty) {
      _prefs.remove(key).ignore();
    } else {
      _prefs.setString(key, jsonEncode([for (final op in ops) op.toJson()])).ignore();
    }
  }

  /// Changes not yet confirmed by the server, oldest first. Storage isn't
  /// trusted: anything that isn't an op is dropped.
  List<SaveOp> get outbox {
    final userId = _userId;
    final raw = userId == null ? null : _prefs.getString(outboxKey(userId));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      return [
        if (decoded is List<Object?>)
          for (final o in decoded)
            if (o is Map<Object?, Object?>) ?SaveOp.fromJson(o.cast()),
      ];
    } on FormatException catch (e) {
      debugPrint('outbox: could not parse ($e); starting empty');
      return const [];
    }
  }

  /// The server has the oldest change, or refused it for good.
  void ack() {
    final userId = _userId;
    if (userId == null) return;
    final ops = outbox;
    if (ops.isNotEmpty) _writeOutbox(userId, ops.sublist(1));
  }

  /// A guest's saves still waiting to be merged, if any.
  SavesState? get pendingMerge {
    final userId = _userId;
    final raw = userId == null ? null : _prefs.getString(pendingMergeKey(userId));
    return raw == null ? null : _parse(raw, 'pending merge');
  }

  void mergeDone() {
    final userId = _userId;
    if (userId != null) _prefs.remove(pendingMergeKey(userId)).ignore();
  }

  /// Takes the server's state, with changes it hasn't seen yet replayed on top.
  void adopt(SavesState server) {
    if (_userId == null) return;
    _write(outbox.fold(server, applyOp));
  }

  bool isSaved(String slug) => state.isSaved(slug);

  /// Saves [slug] or removes it if already saved; true when it is now saved.
  bool toggle(String slug) {
    final saved = !state.isSaved(slug);
    _commit(SetSaved(slug, saved: saved, at: _now()));
    return saved;
  }

  /// Puts [slug] on board [collectionId], saving it if needed, or takes it
  /// off. It stays saved either way.
  void pin(String slug, String collectionId, {bool pinned = true}) =>
      _commit(SetPinned(slug, collectionId, pinned: pinned, at: _now()));

  /// Creates a board named [name] (no-op if its id exists) and returns its id.
  String createCollection(String name, {String description = ''}) {
    final id = slugifyCollection(name) ?? 'c${_now()}';
    _commit(CreateCollection(id, name, description: description));
    return id;
  }

  void updateCollection(String id, String name, {String description = ''}) =>
      _commit(UpdateCollection(id, name, description: description));

  /// Deletes a board and its pins. The designs stay saved.
  void deleteCollection(String id) => _commit(DeleteCollection(id));

  /// The note on a saved design; empty clears it.
  void setNote(String slug, String note) => _commit(SetNote(slug, note));
}
