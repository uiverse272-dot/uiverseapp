import 'package:flutter/foundation.dart';

import 'saves_model.dart';

/// One change to the saves. Every mutation is an op, so the same change can
/// run here, wait in the outbox and go to the server unchanged. Ops say what
/// they want ("saved", not "toggle"), so a repeat can't flip anything back.
/// JSON is the `POST /api/v1/saves/op` body (`docs/api-v1.md`).
@immutable
sealed class SaveOp {
  const SaveOp();

  /// The op in [j], or null when it isn't one: outbox storage isn't trusted.
  static SaveOp? fromJson(Map<String, Object?> j) => switch (j) {
        {'type': 'set', 'slug': final String slug, 'saved': final bool saved, 'at': final num at} =>
          SetSaved(slug, saved: saved, at: at.toInt()),
        {
          'type': 'pin',
          'slug': final String slug,
          'collectionId': final String id,
          'pinned': final bool pinned,
          'at': final num at,
        } =>
          SetPinned(slug, id, pinned: pinned, at: at.toInt()),
        {'type': 'create', 'id': final String id, 'name': final String name} =>
          CreateCollection(id, name, description: (j['description'] as String?) ?? ''),
        {'type': 'update', 'id': final String id, 'name': final String name} =>
          UpdateCollection(id, name, description: (j['description'] as String?) ?? ''),
        {'type': 'delete', 'id': final String id} => DeleteCollection(id),
        {'type': 'note', 'slug': final String slug, 'note': final String note} => SetNote(slug, note),
        _ => null,
      };

  Map<String, Object?> toJson();
}

class SetSaved extends SaveOp {
  const SetSaved(this.slug, {required this.saved, required this.at});

  final String slug;
  final bool saved;
  final int at;

  @override
  Map<String, Object?> toJson() => {'type': 'set', 'slug': slug, 'saved': saved, 'at': at};
}

class SetPinned extends SaveOp {
  const SetPinned(this.slug, this.collectionId, {required this.pinned, required this.at});

  final String slug;
  final String collectionId;
  final bool pinned;
  final int at;

  @override
  Map<String, Object?> toJson() =>
      {'type': 'pin', 'slug': slug, 'collectionId': collectionId, 'pinned': pinned, 'at': at};
}

class CreateCollection extends SaveOp {
  const CreateCollection(this.id, this.name, {this.description = ''});

  final String id;
  final String name;
  final String description;

  @override
  Map<String, Object?> toJson() => {'type': 'create', 'id': id, 'name': name, 'description': description};
}

class UpdateCollection extends SaveOp {
  const UpdateCollection(this.id, this.name, {this.description = ''});

  final String id;
  final String name;
  final String description;

  @override
  Map<String, Object?> toJson() => {'type': 'update', 'id': id, 'name': name, 'description': description};
}

class DeleteCollection extends SaveOp {
  const DeleteCollection(this.id);

  final String id;

  @override
  Map<String, Object?> toJson() => {'type': 'delete', 'id': id};
}

class SetNote extends SaveOp {
  const SetNote(this.slug, this.note);

  final String slug;
  final String note;

  @override
  Map<String, Object?> toJson() => {'type': 'note', 'slug': slug, 'note': note};
}

/// [state] after [op]: `identical` to [state] when the op changes nothing.
SavesState applyOp(SavesState state, SaveOp op) => switch (op) {
      SetSaved(saved: true) when state.isSaved(op.slug) => state,
      SetSaved(saved: true) => state.copyWith(saves: [SaveEntry(slug: op.slug, at: op.at), ...state.saves]),
      SetSaved() when !state.isSaved(op.slug) => state,
      // Unsaving takes a design off every board.
      SetSaved() => state.copyWith(
          saves: [for (final s in state.saves) if (s.slug != op.slug) s],
          pins: [for (final p in state.pins) if (p.slug != op.slug) p],
        ),
      SetPinned() when state.collectionName(op.collectionId) == null => state,
      SetPinned() when state.isPinned(op.slug, op.collectionId) == op.pinned => state,
      SetPinned(pinned: false) => state.copyWith(pins: [
          for (final p in state.pins)
            if (p.slug != op.slug || p.collectionId != op.collectionId) p,
        ]),
      // Pinning saves the design if it wasn't.
      SetPinned() => state.copyWith(
          saves: state.isSaved(op.slug) ? null : [SaveEntry(slug: op.slug, at: op.at), ...state.saves],
          pins: [SavePin(slug: op.slug, collectionId: op.collectionId, at: op.at), ...state.pins],
        ),
      CreateCollection() when state.collectionName(op.id) != null => state,
      CreateCollection() => state.copyWith(collections: [
          ...state.collections,
          SaveCollection(id: op.id, name: op.name, description: op.description.isEmpty ? null : op.description),
        ]),
      UpdateCollection() when state.collectionName(op.id) == null || op.name.trim().isEmpty => state,
      UpdateCollection() => state.copyWith(collections: [
          for (final c in state.collections)
            if (c.id == op.id)
              SaveCollection(
                id: c.id,
                name: op.name.trim(),
                description: op.description.trim().isEmpty ? null : op.description.trim(),
              )
            else
              c,
        ]),
      // A deleted board's designs stay saved.
      DeleteCollection() when state.collectionName(op.id) == null => state,
      DeleteCollection() => state.copyWith(
          collections: [for (final c in state.collections) if (c.id != op.id) c],
          pins: [for (final p in state.pins) if (p.collectionId != op.id) p],
        ),
      SetNote() when !state.isSaved(op.slug) => state,
      SetNote() => state.copyWith(saves: [
          for (final s in state.saves)
            if (s.slug == op.slug)
              SaveEntry(slug: s.slug, at: s.at, note: op.note.trim().isEmpty ? null : op.note.trim())
            else
              s,
        ]),
    };
