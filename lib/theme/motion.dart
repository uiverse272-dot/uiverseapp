import 'package:flutter/widgets.dart';

/// Motion tokens from design-system.md §6.
const Duration kDur = Duration(milliseconds: 140);
const Cubic kEase = Cubic(0.2, 0, 0, 1);

/// Tailwind default transition (`transition-colors`, `-transform`).
const Duration kTransition = Duration(milliseconds: 150);
const Cubic kTransitionEase = Cubic(0.4, 0, 0.2, 1);

const Duration kFadeUp = Duration(milliseconds: 220);
const Duration kFadeIn = Duration(milliseconds: 160);
const Duration kSheet = Duration(milliseconds: 240);

/// Offset-shadow lift levels (§5).
abstract final class Lift {
  static const double l1 = 2;
  static const double l2 = 3;
  static const double l3 = 4;
  static const double l4 = 5;
  static const double l5 = 6;
}

/// Solid, un-blurred shadow offset down-right by [d].
BoxShadow hardShadow(double d, Color c) =>
    BoxShadow(color: c, offset: Offset(d, d), blurRadius: 0, spreadRadius: 0);

/// [d] or [Duration.zero] when the platform asks for reduced motion.
Duration motion(BuildContext context, Duration d) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;

/// Breakpoints (§4.3).
abstract final class Bp {
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1536;
}
