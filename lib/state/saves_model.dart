import 'package:flutter/foundation.dart';

/// Id of the bucket every save had before boards. Reserved: old storage is
/// read as unsorted, and no board may take the id.
const String kRecentCollectionId = 'recent';

/// Ids that name views of the saves or the old default bucket, never boards.
const Set<String> kReservedCollectionIds = {'all', 'unsorted', kRecentCollectionId};

/// One saved design. JSON: `{slug, at, note?}` (`at` = epoch ms).
@immutable
class SaveEntry {
  const SaveEntry({required this.slug, required this.at, this.note});

  final String slug;
  final int at;
  final String? note;

  Map<String, Object?> toJson() => {
        'slug': slug,
        'at': at,
        if (note != null) 'note': note,
      };

  @override
  bool operator ==(Object other) =>
      other is SaveEntry && other.slug == slug && other.at == at && other.note == note;

  @override
  int get hashCode => Object.hash(slug, at, note);
}

/// A board. JSON: `{id, name, description?}`.
@immutable
class SaveCollection {
  const SaveCollection({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
      };

  @override
  bool operator ==(Object other) =>
      other is SaveCollection && other.id == id && other.name == name && other.description == description;

  @override
  int get hashCode => Object.hash(id, name, description);
}

/// A saved design on a board. One design can sit on many boards.
@immutable
class SavePin {
  const SavePin({required this.slug, required this.collectionId, required this.at});

  final String slug;
  final String collectionId;
  final int at;

  Map<String, Object?> toJson() => {'slug': slug, 'collectionId': collectionId, 'at': at};

  @override
  bool operator ==(Object other) =>
      other is SavePin && other.slug == slug && other.collectionId == collectionId && other.at == at;

  @override
  int get hashCode => Object.hash(slug, collectionId, at);
}

/// Saves, boards and pins, newest first. Same shape as the web store and the
/// `/api/v1/saves` payload (`docs/api-v1.md`).
@immutable
class SavesState {
  const SavesState({this.saves = const [], this.collections = const [], this.pins = const []});

  final List<SaveEntry> saves;
  final List<SaveCollection> collections;
  final List<SavePin> pins;

  int get count => saves.length;

  // Saved slugs per state, built on first use: every mounted SaveButton asks
  // [isSaved] on each change. An Expando keeps the constructor const.
  static final Expando<Set<String>> _slugSets = Expando<Set<String>>();

  bool isSaved(String slug) =>
      (_slugSets[this] ??= {for (final s in saves) s.slug}).contains(slug);

  bool isPinned(String slug, String collectionId) =>
      pins.any((p) => p.slug == slug && p.collectionId == collectionId);

  /// Saves on board [collectionId], most recently pinned first.
  List<SaveEntry> savesIn(String collectionId) {
    final Map<String, SaveEntry> bySlug = {for (final s in saves) s.slug: s};
    return [
      for (final p in pins)
        if (p.collectionId == collectionId) ?bySlug[p.slug],
    ];
  }

  /// Saves on no board, newest first.
  List<SaveEntry> get unsorted {
    final Set<String> pinned = {for (final p in pins) p.slug};
    return [for (final s in saves) if (!pinned.contains(s.slug)) s];
  }

  int countIn(String collectionId) => pins.where((p) => p.collectionId == collectionId).length;

  /// Name of [id], or null if it doesn't exist.
  String? collectionName(String id) {
    for (final c in collections) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  /// Storage and the network are outside our control, so anything that isn't
  /// the expected shape is dropped rather than trusted, as in the web store.
  /// Also reads the shape before boards: each save's `collectionId` becomes a
  /// pin, and `recent` (never a board) leaves it unsorted.
  factory SavesState.fromJson(Map<String, Object?> j) {
    final List<Map<String, Object?>> rawSaves = _objects(j['saves']).where((s) => s['slug'] is String).toList();
    final List<SaveCollection> collections = [
      for (final c in _objects(j['collections']))
        if (c['id'] case final String id when c['name'] is String && !kReservedCollectionIds.contains(id))
          SaveCollection(id: id, name: c['name']! as String, description: _text(c['description'])),
    ];
    final List<SaveEntry> saves = [
      for (final s in rawSaves)
        SaveEntry(slug: s['slug']! as String, at: _ms(s['at']), note: _text(s['note'])),
    ];

    final Set<String> boards = {for (final c in collections) c.id};
    final Set<String> saved = {for (final s in saves) s.slug};
    final Set<(String, String)> seen = {};
    final List<SavePin> pins = [
      for (final p in [
        ..._objects(j['pins']),
        ...rawSaves.where((s) => s['collectionId'] is String),
      ])
        if ((p['slug'], p['collectionId']) case (final String slug, final String id)
            when boards.contains(id) && saved.contains(slug) && seen.add((slug, id)))
          SavePin(slug: slug, collectionId: id, at: _ms(p['at'])),
    ];
    return SavesState(saves: saves, collections: collections, pins: pins);
  }

  Map<String, Object?> toJson() => {
        'saves': [for (final s in saves) s.toJson()],
        'collections': [for (final c in collections) c.toJson()],
        'pins': [for (final p in pins) p.toJson()],
      };

  SavesState copyWith({List<SaveEntry>? saves, List<SaveCollection>? collections, List<SavePin>? pins}) =>
      SavesState(
        saves: saves ?? this.saves,
        collections: collections ?? this.collections,
        pins: pins ?? this.pins,
      );

  @override
  bool operator ==(Object other) =>
      other is SavesState &&
      listEquals(other.saves, saves) &&
      listEquals(other.collections, collections) &&
      listEquals(other.pins, pins);

  @override
  int get hashCode => Object.hash(Object.hashAll(saves), Object.hashAll(collections), Object.hashAll(pins));
}

List<Map<String, Object?>> _objects(Object? list) => [
      if (list is List<Object?>)
        for (final o in list)
          if (o is Map<Object?, Object?>) o.cast<String, Object?>(),
    ];

int _ms(Object? v) => v is num ? v.toInt() : 0;

String? _text(Object? v) => v is String && v.isNotEmpty ? v : null;

/// Collection id from a display name — same rule as the web store:
/// lowercase, `[^a-z0-9]+` → `-`, one edge dash trimmed from each end, first
/// 40 chars, and `-board` after a reserved id. Empty result → null.
String? slugifyCollection(String name) {
  final id = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  final cut = id.length > 40 ? id.substring(0, 40) : id;
  if (cut.isEmpty) return null;
  return kReservedCollectionIds.contains(cut) ? '$cut-board' : cut;
}
