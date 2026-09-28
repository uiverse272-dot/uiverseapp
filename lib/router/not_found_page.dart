import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:uiverse/widgets/core/hover_tap.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/logo_mark.dart';
import 'routes.dart';

/// 404 (§12): logo, "Not found", "Back to the feed".
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(size: 56),
            const SizedBox(height: 20),
            Text('Not found', style: UiText.mono(22, bold: true, color: c.text)),
            const SizedBox(height: 8),
            Text("That page doesn't exist.", style: UiText.body.copyWith(color: c.text2)),
            const SizedBox(height: 20),
            HoverTap(
              onTap: () => context.go(Routes.home),
              link: true,
              builder: (context, hovered) => Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hovered ? c.bgSubtle : c.surface,
                  border: Border.all(color: c.border),
                ),
                child: Text('Back to the feed', style: UiText.body.copyWith(color: c.text)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
