import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uiverse/widgets/core/bare_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uiverse/widgets/core/hover_tap.dart';
import '../core/back_dismiss.dart';
import '../../state/saves.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/ui_icon.dart';
import 'save_toast_controller.dart';
import '../core/entrance.dart';

/// Hosts the save toast above [child] (the app's navigator).
///
/// Install once via `MaterialApp.router(builder:)`. It carries its own
/// [Overlay] so the "New collection…" field has one to attach to.
class SaveToastLayer extends StatefulWidget {
  const SaveToastLayer({super.key, required this.child});

  final Widget child;

  @override
  State<SaveToastLayer> createState() => _SaveToastLayerState();
}

class _SaveToastLayerState extends State<SaveToastLayer> {
  final OverlayEntry _entry = OverlayEntry(builder: (_) => const SaveToastHost());

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned.fill(child: Overlay(initialEntries: [_entry])),
      ],
    );
  }
}

/// Positions the current toast: centred, bottom 80 (phone, above BottomNav) / 28 (≥768).
class SaveToastHost extends ConsumerWidget {
  const SaveToastHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(saveToastProvider);
    if (toast == null) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final width = math.min(420.0, w - 32);
    final bottom = w >= Bp.md ? 28.0 : 80.0 + mq.viewPadding.bottom;
    return Positioned(
      left: (w - width) / 2,
      width: width,
      bottom: bottom + mq.viewInsets.bottom,
      child: Material(
        type: MaterialType.transparency,
        child: SaveToast(key: ValueKey(toast.seq), toast: toast),
      ),
    );
  }
}

/// The toast card itself (§10.4): result row, or the "Move to collection" picker.
class SaveToast extends ConsumerStatefulWidget {
  const SaveToast({super.key, required this.toast});

  final SaveToastState toast;

  @override
  ConsumerState<SaveToast> createState() => _SaveToastState();
}

class _SaveToastState extends ConsumerState<SaveToast> {
  bool _picking = false;
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return FadeUp(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          boxShadow: [hardShadow(Lift.l3, c.border)],
        ),
        child: DefaultTextStyle(
          style: UiText.body.copyWith(color: c.text),
          // Esc / back close the "Move to collection" picker (§14).
          child: BackDismiss(
            active: _picking,
            onDismiss: () => setState(() => _picking = false),
            child: _picking ? _picker(context) : _result(context),
          ),
        ),
      ),
    );
  }

  Widget _result(BuildContext context) {
    final c = context.ui;
    final ctl = ref.read(saveToastProvider.notifier);
    final slug = widget.toast.slug;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: UiIcon(Ui.check, size: 13, color: c.accentFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.toast.text,
              // Web truncates to one line, but Space Mono at phone widths cuts
              // off the collection name; two lines keeps it readable.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.button.copyWith(color: c.text),
            ),
          ),
          if (slug != null) ...[
            const SizedBox(width: 12),
            HoverTap(
              onTap: () => setState(() => _picking = true),
              minSize: const Size(0, 48),
              builder: (context, hovered) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hovered ? c.bgSubtle : null,
                  border: Border.all(color: c.border),
                ),
                child: Text('Move to…', style: UiText.chip.copyWith(color: c.text)),
              ),
            ),
          ],
          const SizedBox(width: 8),
          HoverTap(
            onTap: ctl.dismiss,
            minSize: const Size(0, 48),
            builder: (context, hovered) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Dismiss',
                style: UiText.chip.copyWith(color: hovered ? c.text : c.text3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _picker(BuildContext context) {
    final c = context.ui;
    final ctl = ref.read(saveToastProvider.notifier);
    final slug = widget.toast.slug!;
    final collections = ref.watch(savesProvider.select((s) => s.collections));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text('Move to collection', style: UiText.small.copyWith(color: c.text3)),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 208),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final col in collections)
                HoverTap(
                  onTap: () => ctl.moveTo(slug, col.id),
                  minSize: const Size(double.infinity, 48),
                  builder: (context, hovered) => Container(
                    color: hovered ? c.bgSubtle : null,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Text(col.name, style: UiText.body.copyWith(color: c.text)),
                  ),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: Row(
            children: [
              UiIcon(Ui.plus, size: 14, color: c.text),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: true,
                  style: UiText.body.copyWith(color: c.text),
                  cursorColor: c.text,
                  textInputAction: TextInputAction.done,
                  decoration: bareInput(
                    hintText: 'New collection…',
                    hintStyle: UiText.body.copyWith(color: c.text3),
                  ),
                  onSubmitted: (v) => ctl.createAndMove(slug, v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
