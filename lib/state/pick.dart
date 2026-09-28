import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// localStorage key shared with the web app (§15): `"tab"` when folded.
const String kPickKey = 'uiv.pick';

/// Whether Pick of the week is folded down to its tab.
final pickFoldedProvider = NotifierProvider<PickFoldedNotifier, bool>(PickFoldedNotifier.new);

class PickFoldedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPreferencesProvider).getString(kPickKey) == 'tab';

  void set(bool folded) {
    state = folded;
    final prefs = ref.read(sharedPreferencesProvider);
    (folded ? prefs.setString(kPickKey, 'tab') : prefs.remove(kPickKey)).ignore();
  }

  void toggle() => set(!state);
}
