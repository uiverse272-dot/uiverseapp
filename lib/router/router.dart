import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/logo_mark.dart';

/// Placeholder — Phase 1 agent B replaces this with the full ShellRoute tree (§12).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _Placeholder()),
    ],
  );
});

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(size: 56),
            const SizedBox(height: 16),
            Text('Uiverse', style: UiText.pageTitle.copyWith(color: context.ui.text)),
          ],
        ),
      ),
    );
  }
}
