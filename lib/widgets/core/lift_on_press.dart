import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';

/// Card/tile lift: up-left 2px + hard shadow on hover or press (§6).
///
/// Shows an accent shadow while keyboard-focused.
class LiftOnPress extends StatefulWidget {
  const LiftOnPress({
    super.key,
    required this.child,
    required this.onTap,
    this.shadow = Lift.l3,
    this.semanticLabel,
    this.onLiftChanged,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double shadow;
  final String? semanticLabel;

  /// Fires when the lifted state changes (e.g. to fade in card badges).
  final ValueChanged<bool>? onLiftChanged;

  @override
  State<LiftOnPress> createState() => _LiftOnPressState();
}

class _LiftOnPressState extends State<LiftOnPress> {
  bool _up = false;
  bool _focused = false;

  void _set(bool v) {
    if (_up == v) return;
    setState(() => _up = v);
    widget.onLiftChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final lifted = _up || _focused;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call()),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _set(true),
          onExit: (_) => _set(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _set(true),
            onTapCancel: () => _set(false),
            onTapUp: (_) => _set(false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: motion(context, kTransition),
              curve: kEase,
              transform: Matrix4.translationValues(lifted ? -kLiftOffset : 0, lifted ? -kLiftOffset : 0, 0),
              decoration: BoxDecoration(
                boxShadow: [
                  hardShadow(lifted ? widget.shadow : 0, _focused ? c.accent : c.border),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
