import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/saves.dart';

/// What the save toast is showing. [slug] is set after a toggle, enabling
/// "Undo" either way and "Move to…" when [saved] is true.
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
    final landedIn = ref.read(savesProvider.notifier).toggle(slug);
    if (landedIn != null) {
      show('Saved to $landedIn', slug: slug, saved: true);
    } else {
      show('Removed', slug: slug);
    }
  }

  /// Files [slug] under [collectionId] and closes the toast.
  void moveTo(String slug, String collectionId) {
    ref.read(savesProvider.notifier).move(slug, collectionId);
    dismiss();
  }

  /// Creates a collection called [name] (trimmed) and moves [slug] into it.
  void createAndMove(String slug, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = ref.read(savesProvider.notifier).createCollection(trimmed);
    moveTo(slug, id);
  }
}
