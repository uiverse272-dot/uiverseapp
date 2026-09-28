import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// localStorage key shared with the web app (§15).
const String kThemeKey = 'uiv.theme';

/// Light / dark / system (default when nothing is stored).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return switch (ref.watch(sharedPreferencesProvider).getString(kThemeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Flips to the opposite of what is currently [shown] and persists it.
  ///
  /// Pass `Theme.of(context).brightness`, which already resolves system mode
  /// against platform brightness. There is no "back to system" control (§15).
  Future<void> toggle(Brightness shown) =>
      set(shown == Brightness.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(kThemeKey, 'light');
      case ThemeMode.dark:
        await prefs.setString(kThemeKey, 'dark');
      case ThemeMode.system:
        await prefs.remove(kThemeKey);
    }
  }
}

/// The brightness actually shown for [mode] given the platform's [platform] brightness.
Brightness resolveBrightness(ThemeMode mode, Brightness platform) => switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };
