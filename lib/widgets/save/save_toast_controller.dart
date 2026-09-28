import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/saves.dart';

/// What the save toast is showing. [slug] is set only after a save (enables "Move to…").
@immutable
class SaveToastState {
  const SaveToastState({required this.text, this.slug, required this.seq});

  final String text;
  final String? slug;

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

  void show(String text, {String? slug}) =>
      state = SaveToastState(text: text, slug: slug, seq: ++_seq);

  void dismiss() => state = null;

  /// Toggles [slug] and reports the result — what every save control does.
  void toggle(String slug) {
    final landedIn = ref.read(savesProvider.notifier).toggle(slug);
    if (landedIn != null) {
      show('Saved to $landedIn', slug: slug);
    } else {
      show('Removed');
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
