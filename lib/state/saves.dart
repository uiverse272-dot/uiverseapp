import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// localStorage key shared with the web app (§15).
const String kSavesKey = 'uiv.saves.v1';

/// Id of the default collection every save lands in.
const String kRecentCollectionId = 'recent';
const String kRecentCollectionName = 'Recently saved';

/// One saved item. JSON: `{slug, collectionId, at, note?}` (`at` = epoch ms).
@immutable
class SaveEntry {
  const SaveEntry({required this.slug, required this.collectionId, required this.at, this.note});

  final String slug;
  final String collectionId;
  final int at;
  final String? note;

  factory SaveEntry.fromJson(Map<String, Object?> j) => SaveEntry(
        slug: j['slug']! as String,
        collectionId: (j['collectionId'] as String?) ?? kRecentCollectionId,
        at: (j['at'] as num?)?.toInt() ?? 0,
        note: j['note'] as String?,
      );

  Map<String, Object?> toJson() => {
        'slug': slug,
        'collectionId': collectionId,
        'at': at,
        if (note != null) 'note': note,
      };

  @override
  bool operator ==(Object other) =>
      other is SaveEntry &&
      other.slug == slug &&
      other.collectionId == collectionId &&
      other.at == at &&
      other.note == note;

  @override
  int get hashCode => Object.hash(slug, collectionId, at, note);
}

/// A user collection. JSON: `{id, name, sections[]}`.
@immutable
class SaveCollection {
  const SaveCollection({required this.id, required this.name, this.sections = const []});

  final String id;
  final String name;
  final List<String> sections;

  factory SaveCollection.fromJson(Map<String, Object?> j) => SaveCollection(
        id: j['id']! as String,
        name: j['name']! as String,
        sections: [for (final s in (j['sections'] as List<Object?>?) ?? const <Object?>[]) '$s'],
      );

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'sections': sections};

  @override
  bool operator ==(Object other) =>
      other is SaveCollection &&
      other.id == id &&
      other.name == name &&
      listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(sections));
}

const List<SaveCollection> kDefaultCollections = [
  SaveCollection(id: kRecentCollectionId, name: kRecentCollectionName),
];

/// Saves + collections, newest save first.
@immutable
class SavesState {
  const SavesState({this.saves = const [], this.collections = kDefaultCollections});

  final List<SaveEntry> saves;
  final List<SaveCollection> collections;

  int get count => saves.length;

  bool isSaved(String slug) => saves.any((s) => s.slug == slug);

  /// Saves in [collectionId], newest first.
  List<SaveEntry> savesIn(String collectionId) =>
      [for (final s in saves) if (s.collectionId == collectionId) s];

  int countIn(String collectionId) => savesIn(collectionId).length;

  /// Name of [id], or null if it doesn't exist.
  String? collectionName(String id) {
    for (final c in collections) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  factory SavesState.fromJson(Map<String, Object?> j) {
    final saves = [
      for (final s in (j['saves'] as List<Object?>?) ?? const <Object?>[])
        SaveEntry.fromJson((s! as Map<Object?, Object?>).cast<String, Object?>()),
    ];
    final cols = [
      for (final c in (j['collections'] as List<Object?>?) ?? const <Object?>[])
        SaveCollection.fromJson((c! as Map<Object?, Object?>).cast<String, Object?>()),
    ];
    return SavesState(saves: saves, collections: cols.isEmpty ? kDefaultCollections : cols);
  }

  Map<String, Object?> toJson() => {
        'saves': [for (final s in saves) s.toJson()],
        'collections': [for (final c in collections) c.toJson()],
      };

  SavesState copyWith({List<SaveEntry>? saves, List<SaveCollection>? collections}) =>
      SavesState(saves: saves ?? this.saves, collections: collections ?? this.collections);

  @override
  bool operator ==(Object other) =>
      other is SavesState &&
      listEquals(other.saves, saves) &&
      listEquals(other.collections, collections);

  @override
  int get hashCode => Object.hash(Object.hashAll(saves), Object.hashAll(collections));
}

/// Collection id from a display name — same rule as the web store:
/// lowercase, `[^a-z0-9]+` → `-`, first 40 chars. Empty result → null.
String? slugifyCollection(String name) {
  final id = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
  final cut = id.length > 40 ? id.substring(0, 40) : id;
  return cut.isEmpty ? null : cut;
}

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

  void _commit(SavesState next) {
    state = next;
    // Fire-and-forget: SharedPreferences updates its cache synchronously.
    ref.read(sharedPreferencesProvider).setString(kSavesKey, jsonEncode(next.toJson())).ignore();
  }

  bool isSaved(String slug) => state.isSaved(slug);

  /// Saves [slug] (prepended) or removes it if already saved.
  ///
  /// Returns the collection name it landed in, or null when it was removed.
  String? toggle(String slug, {String collectionId = kRecentCollectionId}) {
    if (state.isSaved(slug)) {
      _commit(state.copyWith(saves: [for (final s in state.saves) if (s.slug != slug) s]));
      return null;
    }
    _commit(state.copyWith(
      saves: [SaveEntry(slug: slug, collectionId: collectionId, at: _now()), ...state.saves],
    ));
    return state.collectionName(collectionId) ?? kRecentCollectionName;
  }

  /// Moves (or saves) [slug] into [collectionId], bumping it to the top.
  void move(String slug, String collectionId) {
    final rest = [for (final s in state.saves) if (s.slug != slug) s];
    _commit(state.copyWith(
      saves: [SaveEntry(slug: slug, collectionId: collectionId, at: _now()), ...rest],
    ));
  }

  /// Creates a collection named [name] (no-op if its id exists) and returns its id.
  String createCollection(String name) {
    final id = slugifyCollection(name) ?? 'c${_now()}';
    if (state.collectionName(id) == null) {
      _commit(state.copyWith(
        collections: [...state.collections, SaveCollection(id: id, name: name)],
      ));
    }
    return id;
  }
}
