import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/saves.dart';

/// What the save toast is showing. [slug] is set after a toggle, enabling
/// "Undo" either way and "Add to board" when [saved] is true.
@immutable
class SaveToastState {
  const SaveToastState({required this.text, this.slug, this.saved = false, required this.seq});

  final String text;
  final String? slug;
  final bool saved;

  /// Bumps on every show so a replaced toast replays its entrance.
  final int seq;
}

/// The single app-wide save toast (§10.4). Rendered by `SaveToastLayer`.
final saveToastProvider =
    NotifierProvider<SaveToastController, SaveToastState?>(SaveToastController.new);

class SaveToastController extends Notifier<SaveToastState?> {
  int _seq = 0;

  @override
  SaveToastState? build() => null;

  void show(String text, {String? slug, bool saved = false}) =>
      state = SaveToastState(text: text, slug: slug, saved: saved, seq: ++_seq);

  void dismiss() => state = null;

  /// Toggles [slug] and reports the result — what every save control does.
  /// [slug] is always attached so the toast can offer "Undo" either way.
  void toggle(String slug) {
    if (ref.read(savesProvider.notifier).toggle(slug)) {
      show('Saved', slug: slug, saved: true);
    } else {
      show('Removed', slug: slug);
    }
  }

  /// Puts [slug] on board [collectionId] or takes it off.
  void pin(String slug, String collectionId, {required bool pinned}) =>
      ref.read(savesProvider.notifier).pin(slug, collectionId, pinned: pinned);

  /// Creates a board called [name] (trimmed) with [slug] already on it.
  void createAndPin(String slug, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final notifier = ref.read(savesProvider.notifier);
    notifier.pin(slug, notifier.createCollection(trimmed));
  }
}
