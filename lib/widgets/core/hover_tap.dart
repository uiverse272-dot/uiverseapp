import 'package:flutter/material.dart';

import '../../theme/uiverse_colors.dart';

/// Tappable region without Material ink: hover state for pointers, keyboard
/// activation, a 2px accent focus outline (§14) and a minimum hit size.
///
/// [builder] receives whether the pointer is hovering so callers can swap
/// colours (`hover → accent`, `hover → bg-subtle`).
class HoverTap extends StatefulWidget {
  const HoverTap({
    super.key,
    required this.onTap,
    required this.builder,
    this.label,
    this.selected,
    this.toggled,
    this.expanded,
    this.minSize = const Size(48, 48),
    this.link = false,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hovered) builder;

  /// Accessible name. When set, the child's own semantics are replaced by it.
  final String? label;
  final bool? selected;
  final bool? toggled;
  final bool? expanded;

  /// Minimum tappable size; the visual stays centred inside it.
  final Size minSize;

  /// Announce as a link (navigation) rather than a button.
  final bool link;

  @override
  State<HoverTap> createState() => _HoverTapState();
}

class _HoverTapState extends State<HoverTap> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: !widget.link,
      link: widget.link,
      label: widget.label,
      selected: widget.selected,
      toggled: widget.toggled,
      expanded: widget.expanded,
      // With a label the child's semantics (including the GestureDetector's
      // tap action) are excluded, so re-expose the tap here. Without one the
      // detector's own action merges into this node.
      onTap: widget.label != null ? widget.onTap : null,
      excludeSemantics: widget.label != null,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        mouseCursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call()),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.minSize.width,
              minHeight: widget.minSize.height,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: _focused
                    ? BoxDecoration(border: Border.all(color: context.ui.focus, width: 2))
                    : const BoxDecoration(),
                child: widget.builder(context, _hovered),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
