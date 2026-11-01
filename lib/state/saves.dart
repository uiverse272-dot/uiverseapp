import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';
import 'save_ops.dart';
import 'saves_model.dart';

export 'save_ops.dart';
export 'saves_model.dart';

/// localStorage key shared with the web app (§15).
const String kSavesKey = 'uiv.saves.v1';

final savesProvider = NotifierProvider<SavesNotifier, SavesState>(SavesNotifier.new);

class SavesNotifier extends Notifier<SavesState> {
  @override
  SavesState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(kSavesKey);
    if (raw == null) return const SavesState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return SavesState.fromJson(decoded);
      debugPrint('uiv.saves.v1: expected an object, got ${decoded.runtimeType}; starting empty');
    } on Object catch (e) {
      // Corrupt storage must not brick the app — start fresh, like the web store.
      debugPrint('uiv.saves.v1: could not parse stored saves ($e); starting empty');
    }
    return const SavesState();
  }

  int _now() => ref.read(clockProvider)().millisecondsSinceEpoch;

  void _commit(SaveOp op) {
    final next = applyOp(state, op);
    if (identical(next, state)) return;
    state = next;
    // Fire-and-forget: SharedPreferences updates its cache synchronously.
    ref.read(sharedPreferencesProvider).setString(kSavesKey, jsonEncode(next.toJson())).ignore();
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
