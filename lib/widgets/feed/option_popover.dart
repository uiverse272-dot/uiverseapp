import 'package:flutter/material.dart';

import '../../data/taxonomy.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/back_dismiss.dart';
import '../core/hover_tap.dart';
import '../core/ui_icon.dart';
import '../core/entrance.dart';

/// Popover panel width and max height (§4.2).
const double kPopoverWidth = 224;
const double kPopoverMaxHeight = 320;

/// A filter trigger (§10.5): 32 tall, label + chevron; accent fill showing
/// the chosen option's name when [selected] is set.
///
/// Opens an anchored panel below the trigger at ≥768, a bottom sheet on
/// phones. Picking an option calls [onSelect] (the caller clears when it is
/// already selected) and closes.
class OptionPopover extends StatefulWidget {
  const OptionPopover({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.title,
  });

  /// Trigger label while nothing is selected.
  final String label;
  final List<Tax> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  /// Bottom-sheet heading; defaults to [label].
  final String? title;

  @override
  State<OptionPopover> createState() => _OptionPopoverState();
}

class _OptionPopoverState extends State<OptionPopover> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _alignRight = false;

  String? get _selectedName {
    for (final o in widget.options) {
      if (o.slug == widget.selected) return o.name;
    }
    return null;
  }

  void _pick(String slug) {
    _close();
    widget.onSelect(slug);
  }

  void _toggle() {
    if (_portal.isShowing) {
      setState(_portal.hide);
      return;
    }
    if (MediaQuery.sizeOf(context).width < Bp.md) {
      _openSheet();
      return;
    }
    final box = context.findRenderObject()! as RenderBox;
    final x = box.localToGlobal(Offset.zero).dx;
    setState(() {
      _alignRight = x + kPopoverWidth > MediaQuery.sizeOf(context).width - 8;
      _portal.show();
    });
  }

  void _close() {
    if (_portal.isShowing) setState(_portal.hide);
  }

  Future<void> _openSheet() async {
    final c = context.ui;
    // anim-sheet timing; zero under reduced motion (§6).
    final d = motion(context, kSheet);
    final slug = await showModalBottomSheet<String>(
      context: context,
      sheetAnimationStyle: AnimationStyle(duration: d, reverseDuration: d),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      barrierColor: c.overlay,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => OptionSheet(
        title: widget.title ?? widget.label,
        options: widget.options,
        selected: widget.selected,
        onPick: (slug) => Navigator.of(context).pop(slug),
      ),
    );
    if (slug != null && mounted) widget.onSelect(slug);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final name = _selectedName;
    final on = name != null;
    final trigger = HoverTap(
      onTap: _toggle,
      label: name ?? widget.label,
      selected: on,
      expanded: _portal.isShowing,
      minSize: const Size(0, 48),
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: on ? c.accent : (hovered ? c.bgSubtle : null),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name ?? widget.label, style: UiText.chip.copyWith(color: on ? c.accentFg : c.text)),
            const SizedBox(width: 6),
            UiIcon(Ui.chevron, size: 13, color: on ? c.accentFg : c.text),
          ],
        ),
      ),
    );

    return BackDismiss(
      active: _portal.isShowing,
      onDismiss: _close,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: 'Close',
                button: true,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close),
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              // Trigger is 32 tall inside a 48 hit box: 36 below its top = 4 below its bottom.
              targetAnchor: _alignRight ? Alignment.bottomRight : Alignment.bottomLeft,
              followerAnchor: _alignRight ? Alignment.topRight : Alignment.topLeft,
              offset: const Offset(0, -4),
              child: Align(
                alignment: _alignRight ? Alignment.topRight : Alignment.topLeft,
                widthFactor: 1,
                heightFactor: 1,
                child: _Panel(
                  child: OptionList(options: widget.options, selected: widget.selected, onPick: _pick),
                ),
              ),
            ),
          ],
        ),
        child: CompositedTransformTarget(link: _link, child: trigger),
      ),
    );
  }
}

/// Anchored popover panel: 224 wide, max 320 tall, surface, border, L3
/// shadow, fades in. Esc / back close it via [BackDismiss].
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Focus(
      autofocus: true,
      child: FadeIn(
        child: Container(
          width: kPopoverWidth,
          constraints: const BoxConstraints(maxHeight: kPopoverMaxHeight),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            boxShadow: [hardShadow(Lift.l3, c.border)],
          ),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}

/// Option rows: 12.5px, 12×8 padding, `rule` dividers, check on the
/// current value, hover bg-subtle.
class OptionList extends StatelessWidget {
  const OptionList({
    super.key,
    required this.options,
    required this.selected,
    required this.onPick,
    this.rowHeight = 48,
  });

  final List<Tax> options;
  final String? selected;
  final ValueChanged<String> onPick;

  /// Minimum row height; defaults to 48 so every option is a 48dp target (§14).
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < options.length; i++)
          HoverTap(
            onTap: () => onPick(options[i].slug),
            label: options[i].name,
            selected: options[i].slug == selected,
            minSize: Size(0, rowHeight),
            builder: (context, hovered) => Container(
              constraints: BoxConstraints(minHeight: rowHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hovered ? c.bgSubtle : null,
                border: i == options.length - 1 ? null : Border(bottom: BorderSide(color: c.rule)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(options[i].name, style: UiText.chip.copyWith(color: c.text)),
                  ),
                  if (options[i].slug == selected) UiIcon(Ui.check, size: 13, color: c.text),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Phone variant of the popover: a square, ink-bordered bottom sheet with a
/// heading and the same option rows.
class OptionSheet extends StatelessWidget {
  const OptionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final List<Tax> options;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
              child: Semantics(
                header: true,
                child: Text(title, style: UiText.sectionHead.copyWith(color: c.text)),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: OptionList(options: options, selected: selected, onPick: onPick),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
