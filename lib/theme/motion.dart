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

/// Distance a lifted plate or button moves up (and left, for plates) (§6).
const double kLiftOffset = 2;

/// Device-frame and scroll-into-view animations on the detail page (§6, §10.9).
const Duration kFrameSwitch = Duration(milliseconds: 200);
const Duration kReveal = Duration(milliseconds: 300);

/// Breakpoints (§4.3).
abstract final class Bp {
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1536;
}

/// Tailwind-style responsive column count: the value of the widest breakpoint
/// [width] reaches, falling back to [base] (`grid-cols-2 sm:grid-cols-3 …`).
int bpColumns(double width, {required int base, int? sm, int? md, int? lg, int? xl}) {
  if (xl != null && width >= Bp.xl) return xl;
  if (lg != null && width >= Bp.lg) return lg;
  if (md != null && width >= Bp.md) return md;
  if (sm != null && width >= Bp.sm) return sm;
  return base;
}

extension ResponsiveContext on BuildContext {
  /// Tablet/desktop shell (rail instead of bottom nav): window width ≥ 768.
  bool get isWide => MediaQuery.sizeOf(this).width >= Bp.md;
}
