import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/router.dart';
import 'state/theme.dart';
import 'theme/uiverse_colors.dart';
import 'theme/uiverse_theme.dart';
import 'widgets/core/back_dismiss.dart';
import 'widgets/save/save_toast.dart';

final ThemeData _lightTheme = uiverseTheme(Brightness.light);
final ThemeData _darkTheme = uiverseTheme(Brightness.dark);

/// Root widget. Needs `sharedPreferencesProvider` overridden in its [ProviderScope].
class UiverseApp extends ConsumerWidget {
  const UiverseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Uiverse',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      // No cross-fade: lerping the tokens rebuilds every themed widget (all
      // cards and previews) on each frame of the default 200ms animation.
      themeAnimationDuration: Duration.zero,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      // Esc goes through BackDismissRoot (same path as Android back).
      shortcuts: kEscapeShortcutOverride,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemBars(context),
        child: BackDismissRoot(
          backButtonDispatcher: router.backButtonDispatcher,
          child: SaveToastLayer(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Status/navigation bars painted in `bg` with icons in the opposite brightness,
/// so they follow the in-app theme rather than the system one.
SystemUiOverlayStyle systemBars(BuildContext context) {
  final c = context.ui;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final icons = dark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: c.bg,
    statusBarIconBrightness: icons,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light, // iOS
    systemNavigationBarColor: c.bg,
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarDividerColor: c.bg,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );
}
