import 'package:flutter/widgets.dart';

import '../../theme/motion.dart';

/// Entrance animations (§6 keyframes), shared so every sheet, toast and
/// popover animates the same way and honours reduced motion.
///
/// They drive `FadeTransition` and a transform straight from the animation, so
/// the animated subtree is never rebuilt per frame.

/// Fade + rise [rise] px + scale [fromScale] → 1, driven by [animation].
/// Use for route and dialog transitions (`anim-sheet`).
Widget sheetTransition(Animation<double> animation, Widget child) =>
    _EntranceTransition(animation: CurvedAnimation(parent: animation, curve: kEase), rise: 24, fromScale: 0.99, child: child);

/// `anim-sheet`: fade + rise 24 + scale 0.99 → 1 over 240ms.
class SheetIn extends StatelessWidget {
  const SheetIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _Entrance(duration: kSheet, curve: kEase, rise: 24, fromScale: 0.99, child: child);
}

/// `anim-fade-up`: fade + rise 6 over 220ms.
class FadeUp extends StatelessWidget {
  const FadeUp({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => _Entrance(duration: kFadeUp, curve: kEase, rise: 6, child: child);
}

/// `anim-fade-in`: fade over 160ms.
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => _Entrance(duration: kFadeIn, curve: Curves.linear, child: child);
}

/// Runs once on mount.
class _Entrance extends StatefulWidget {
  const _Entrance({
    required this.duration,
    required this.curve,
    required this.child,
    this.rise = 0,
    this.fromScale = 1,
  });

  final Duration duration;
  final Curve curve;
  final double rise;
  final double fromScale;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final CurvedAnimation _curved = CurvedAnimation(parent: _controller, curve: widget.curve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final d = motion(context, widget.duration);
    if (d == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = d
        ..forward();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _EntranceTransition(animation: _curved, rise: widget.rise, fromScale: widget.fromScale, child: widget.child);
}

class _EntranceTransition extends StatelessWidget {
  const _EntranceTransition({
    required this.animation,
    required this.child,
    this.rise = 0,
    this.fromScale = 1,
  });

  final Animation<double> animation;
  final double rise;
  final double fromScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget faded = FadeTransition(opacity: animation, child: child);
    if (rise == 0 && fromScale == 1) return faded;
    return AnimatedBuilder(
      animation: animation,
      child: faded,
      builder: (context, child) {
        final double t = animation.value;
        final double s = fromScale + (1 - fromScale) * t;
        return Transform(
          transform: Matrix4.translationValues(0, rise * (1 - t), 0)..scaleByDouble(s, s, 1, 1),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }
}
