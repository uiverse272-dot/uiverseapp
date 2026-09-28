import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/router.dart';
import 'state/theme.dart';
import 'theme/uiverse_theme.dart';

class UiverseApp extends ConsumerWidget {
  const UiverseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Uiverse',
      debugShowCheckedModeBanner: false,
      theme: uiverseTheme(Brightness.light),
      darkTheme: uiverseTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
