import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uiverse/widgets/core/hover_tap.dart';
import '../../state/saves.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/ui_icon.dart';
import 'save_toast_controller.dart';

enum SaveButtonVariant { icon, solid, inline }

/// Bookmark toggle (§10.3). Toggling always shows the save toast.
class SaveButton extends ConsumerWidget {
  const SaveButton(this.slug, {super.key, this.variant = SaveButtonVariant.icon, this.expand = false});

  final String slug;
  final SaveButtonVariant variant;

  /// Solid variant only: fill the available width (detail rail, §10.9).
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savesProvider.select((s) => s.isSaved(slug)));
    void toggle() => ref.read(saveToastProvider.notifier).toggle(slug);
    final c = context.ui;
    final mark = saved ? Ui.bookmarkFilled : Ui.bookmark;

    return switch (variant) {
      SaveButtonVariant.icon => HoverTap(
          onTap: toggle,
          label: saved ? 'Remove from saves' : 'Save',
          toggled: saved,
          builder: (context, hovered) => SizedBox.square(
            dimension: 28,
            child: Center(
              child: UiIcon(mark, size: 17, color: saved || hovered ? c.accent : c.text),
            ),
          ),
        ),
      SaveButtonVariant.solid => HoverTap(
          onTap: toggle,
          toggled: saved,
          minSize: const Size(48, 44),
          builder: (context, hovered) {
            final fg = saved ? c.text : c.accentFg;
            final bg = saved ? (hovered ? c.bgSubtle : c.surface) : c.accent;
            return AnimatedContainer(
              duration: motion(context, kTransition),
              width: expand ? double.infinity : null,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: bg, border: Border.all(color: c.border)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiIcon(mark, size: 15, color: fg),
                  const SizedBox(width: 8),
                  Text(saved ? 'Saved' : 'Save', style: UiText.button.copyWith(color: fg)),
                ],
              ),
            );
          },
        ),
      SaveButtonVariant.inline => HoverTap(
          onTap: toggle,
          toggled: saved,
          builder: (context, hovered) {
            final fg = hovered ? c.text : c.text2;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiIcon(mark, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(saved ? 'Saved' : 'Save', style: UiText.body.copyWith(color: fg)),
              ],
            );
          },
        ),
    };
  }
}
