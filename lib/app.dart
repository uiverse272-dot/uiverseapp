import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/router.dart';
import 'state/theme.dart';
import 'theme/uiverse_theme.dart';
import 'widgets/core/back_dismiss.dart';
import 'widgets/save/save_toast.dart';

/// Root widget. Needs `sharedPreferencesProvider` overridden in its [ProviderScope].
class UiverseApp extends ConsumerWidget {
  const UiverseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Uiverse',
      debugShowCheckedModeBanner: false,
      theme: uiverseTheme(Brightness.light),
      darkTheme: uiverseTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      // Esc goes through BackDismissRoot (same path as Android back).
      shortcuts: kEscapeShortcutOverride,
      builder: (context, child) => BackDismissRoot(
        backButtonDispatcher: router.backButtonDispatcher,
        child: SaveToastLayer(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
