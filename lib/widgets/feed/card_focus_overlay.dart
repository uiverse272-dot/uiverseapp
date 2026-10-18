import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../detail/prompt_dialog.dart';
import '../../mock/mock_screen.dart';
import '../../router/detail.dart';
import '../../state/saves.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/ui_icon.dart';
import '../save/save_toast_controller.dart';

/// Wraps [child] (a feed card's preview plate) with a Pinterest-style
/// long-press focus gesture: holding the card lifts it into a blurred,
/// dimmed overlay and fans a ring of quick actions out from the hold point.
/// Dragging onto an action arms it (with a tactile tick); releasing there
/// runs it. Releasing elsewhere, or tapping the backdrop, cancels.
///
/// The overlay paints its own preview of [item] (rather than reusing
/// [child]'s widget instance) so nothing is ever mounted in two places at
/// once — [child] keeps rendering normally in the grid throughout.
class CardFocusOverlay extends StatefulWidget {
  const CardFocusOverlay({super.key, required this.item, required this.child});

  final Item item;
  final Widget child;

  @override
  State<CardFocusOverlay> createState() => _CardFocusOverlayState();
}

class _CardFocusOverlayState extends State<CardFocusOverlay> {
  GlobalKey<_FocusedCardState>? _key;
  OverlayEntry? _entry;

  void _start(LongPressStartDetails details) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final origin = box.localToGlobal(Offset.zero) & box.size;

    HapticFeedback.mediumImpact().ignore();
    final key = GlobalKey<_FocusedCardState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FocusedCard(
        key: key,
        item: widget.item,
        origin: origin,
        holdPoint: details.globalPosition,
        onClosed: () {
          entry.remove();
          if (identical(_entry, entry)) {
            _entry = null;
            _key = null;
          }
        },
      ),
    );
    _entry = entry;
    _key = key;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _start,
      onLongPressMoveUpdate: (d) => _key?.currentState?.updatePointer(d.globalPosition),
      onLongPressEnd: (_) => _key?.currentState?.release().ignore(),
      onLongPressCancel: () => _key?.currentState?.release(runAction: false).ignore(),
      child: widget.child,
    );
  }
}

/// Centres of [count] action buttons fanned on a [radius] arc around [hold],
/// kept at least [margin] inside [screen].
///
/// Neighbouring buttons are always the same distance apart: the arc swings
/// toward the screen's horizontal centre near the side edges, flips below the
/// finger when there's no headroom above, and any remaining overflow shifts
/// the whole ring — buttons are never clamped one by one.
@visibleForTesting
List<Offset> radialTargets({
  required Offset hold,
  required int count,
  required Size screen,
  double radius = 100,
  double margin = 34,
  double sweep = 2 * math.pi / 3,
}) {
  if (count <= 0) return const [];
  final half = screen.width / 2;
  final lean = half <= 0 ? 0.0 : ((hold.dx - half) / half).clamp(-1.0, 1.0);
  var centre = -math.pi / 2 - lean * math.pi / 4;
  final below = hold.dy - radius - margin < 0;
  if (below) centre = -centre;

  // Walk left to right whichever way the arc faces, so action order holds.
  final step = count == 1 ? 0.0 : sweep / (count - 1);
  final first = count == 1 ? centre : (below ? centre + sweep / 2 : centre - sweep / 2);
  final points = [
    for (var i = 0; i < count; i++)
      hold + Offset(math.cos(first + (below ? -i : i) * step), math.sin(first + (below ? -i : i) * step)) * radius,
  ];

  double shift(Iterable<double> values, double max) {
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    if (lo < margin) return margin - lo;
    if (hi > max - margin) return max - margin - hi;
    return 0;
  }

  final delta = Offset(
    shift(points.map((p) => p.dx), screen.width),
    shift(points.map((p) => p.dy), screen.height),
  );
  return [for (final p in points) p + delta];
}

typedef _RadialAction = ({String label, Ui icon, VoidCallback onSelect});

class _FocusedCard extends ConsumerStatefulWidget {
  const _FocusedCard({
    super.key,
    required this.item,
    required this.origin,
    required this.holdPoint,
    required this.onClosed,
  });

  final Item item;
  final Rect origin;
  final Offset holdPoint;
  final VoidCallback onClosed;

  @override
  ConsumerState<_FocusedCard> createState() => _FocusedCardState();
}

class _FocusedCardState extends ConsumerState<_FocusedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  static const int _actionCount = 4;

  /// One staggered entrance curve per action button, built once rather than
  /// per build so a drag mid-entrance doesn't churn through throwaway
  /// [CurvedAnimation] listeners. The overshoot carries each button slightly
  /// past its slot before it settles.
  late final List<CurvedAnimation> _entranceCurves = List.generate(
    _actionCount,
    (i) => CurvedAnimation(
      parent: _controller,
      curve: Interval(0.12 + i * 0.07, 0.72 + i * 0.07, curve: const Cubic(0.34, 1.4, 0.64, 1)),
      reverseCurve: const Interval(0, 0.8, curve: Curves.easeInCubic),
    ),
  );
  late final CurvedAnimation _cardCurve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final CurvedAnimation _backdropCurve = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );
  late final CurvedAnimation _anchorCurve = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
    reverseCurve: Curves.easeIn,
  );

  Duration _closeDuration = kFocusClose;
  bool _started = false;
  List<Offset> _targets = const [];
  Offset? _pointer;
  int? _armed;
  int? _fired;
  bool _closing = false;

  static const double _ringRadius = 100;
  static const double _buttonDiameter = 52;
  static const double _armThreshold = _buttonDiameter * 0.9;
  static const double _magnetPull = 8;

  // Reading `motion(context, ...)` needs an inherited-widget lookup, which
  // isn't allowed yet in initState — seed the controller here instead, once.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _targets = radialTargets(
      hold: widget.holdPoint,
      count: _actionCount,
      screen: MediaQuery.sizeOf(context),
      radius: _ringRadius,
      margin: _buttonDiameter / 2 + 8,
    );
    if (_started) return;
    _started = true;
    _closeDuration = motion(context, kFocusClose);
    final openDuration = motion(context, kFocusOpen);
    if (openDuration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = openDuration
        ..forward();
    }
  }

  @override
  void dispose() {
    for (final curve in [..._entranceCurves, _cardCurve, _backdropCurve, _anchorCurve]) {
      curve.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Rect get _focusRect {
    final size = MediaQuery.sizeOf(context);
    final maxWidth = math.min(size.width - 48, 420.0);
    final aspect = widget.origin.width / widget.origin.height;
    final width = math.min(maxWidth, widget.origin.width);
    final height = width / aspect;
    final center = Offset(size.width / 2, size.height / 2);
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  /// Built fresh on every call (build, or a drag/release handler) from a
  /// plain [Ref.read] — never [Ref.watch], which Riverpod only allows during
  /// build. The save toggle always closes the overlay right after running,
  /// so staying non-reactive here costs nothing in practice.
  List<_RadialAction> _actions(BuildContext context) {
    final item = widget.item;
    final saved = ref.read(savesProvider).isSaved(item.slug);
    return [
      (
        label: saved ? 'Unsave' : 'Save',
        icon: saved ? Ui.bookmarkFilled : Ui.bookmark,
        onSelect: () => ref.read(saveToastProvider.notifier).toggle(item.slug),
      ),
      (
        label: 'Open',
        icon: Ui.external,
        onSelect: () => openDetail(context, item).ignore(),
      ),
      (
        label: 'Prompt',
        icon: Ui.sparkle,
        onSelect: () => showPromptDialog(context, item).ignore(),
      ),
      (
        label: 'Share',
        icon: Ui.share,
        onSelect: () =>
            SharePlus.instance.share(ShareParams(text: '${item.title} — captured on Uiverse')).ignore(),
      ),
    ];
  }

  void updatePointer(Offset global) {
    if (_closing) return;
    setState(() {
      _pointer = global;
      int? nearest;
      double best = _armThreshold;
      for (final (i, target) in _targets.indexed) {
        final d = (target - global).distance;
        if (d < best) {
          best = d;
          nearest = i;
        }
      }
      if (nearest != _armed) {
        _armed = nearest;
        if (nearest != null) HapticFeedback.selectionClick().ignore();
      }
    });
  }

  Future<void> release({bool runAction = true}) async {
    if (_closing) return;
    _closing = true;
    final armed = _armed;
    if (runAction && armed != null) {
      HapticFeedback.heavyImpact().ignore();
      setState(() => _fired = armed);
      _actions(context)[armed].onSelect();
    }
    if (_closeDuration == Duration.zero) {
      _controller.value = 0;
    } else {
      _controller.duration = _closeDuration;
      await _controller.reverse();
    }
    widget.onClosed();
  }

  /// Up to [_magnetPull] px from [target] toward the finger.
  Offset _pull(Offset target) {
    final pointer = _pointer;
    if (pointer == null) return Offset.zero;
    final delta = pointer - target;
    final d = delta.distance;
    return d == 0 ? Offset.zero : delta / d * math.min(d, _magnetPull);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final actions = _actions(context);
    final armDuration = motion(context, kFocusArm);
    final armed = _armed;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => release(runAction: false).ignore(),
          child: AnimatedBuilder(
            animation: _backdropCurve,
            builder: (context, _) {
              final t = _backdropCurve.value;
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
                child: Container(color: c.overlay.withValues(alpha: c.overlay.a * t)),
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: _cardCurve,
          builder: (context, child) {
            final t = _cardCurve.value;
            return Positioned.fromRect(
              rect: Rect.lerp(widget.origin, _focusRect, t)!,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  boxShadow: [hardShadow(lerpDouble(Lift.l1, Lift.l5, t)!, c.border)],
                ),
                child: child,
              ),
            );
          },
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border.all(color: c.border)),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: MockScreen(item: widget.item),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: armed == null ? 0 : 1),
            duration: armDuration,
            curve: Curves.easeOut,
            builder: (context, t, _) => CustomPaint(
              painter: _TetherPainter(
                from: widget.holdPoint,
                to: armed == null ? null : _targets[armed] + _pull(_targets[armed]),
                color: c.accent.withValues(alpha: c.accent.a * t),
              ),
            ),
          ),
        ),
        _HoldAnchor(center: widget.holdPoint, progress: _anchorCurve),
        for (final (i, action) in actions.indexed)
          _ActionButton(
            origin: widget.holdPoint,
            center: _targets[i],
            pull: _pull(_targets[i]),
            action: action,
            armed: armed == i,
            muted: armed != null && armed != i,
            fired: _fired == i,
            armDuration: armDuration,
            progress: _entranceCurves[i],
            closing: _controller,
          ),
        if (armed != null && _fired == null)
          _ArmedLabel(
            key: ValueKey<int>(armed),
            anchor: _targets[armed],
            label: actions[armed].label,
            duration: armDuration,
          ),
      ],
    );
  }
}

/// Ring and dot under the finger that the action fan grows out of.
class _HoldAnchor extends StatelessWidget {
  const _HoldAnchor({required this.center, required this.progress});

  final Offset center;
  final Animation<double> progress;

  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Positioned(
      left: center.dx - _size / 2,
      top: center.dy - _size / 2,
      width: _size,
      height: _size,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, child) => Opacity(
            opacity: progress.value.clamp(0.0, 1.0),
            child: Transform.scale(scale: math.max(0, progress.value), child: child),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface.withValues(alpha: 0.35),
              border: Border.all(color: c.accent, width: 2),
            ),
            child: Center(
              child: SizedBox.square(
                dimension: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent,
                    border: Border.all(color: c.border),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TetherPainter extends CustomPainter {
  const _TetherPainter({required this.from, required this.to, required this.color});

  final Offset from;
  final Offset? to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final to = this.to;
    if (to == null || color.a == 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);
  }

  @override
  bool shouldRepaint(_TetherPainter old) => old.from != from || old.to != to || old.color != color;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.origin,
    required this.center,
    required this.pull,
    required this.action,
    required this.armed,
    required this.muted,
    required this.fired,
    required this.armDuration,
    required this.progress,
    required this.closing,
  });

  /// Where the button grows out of (the finger) and its resting slot.
  final Offset origin, center;

  /// Magnetic offset toward the finger, applied in proportion to arming.
  final Offset pull;
  final _RadialAction action;
  final bool armed, muted, fired;
  final Duration armDuration;
  final Animation<double> progress;

  /// The overlay's own controller: a fired button blooms out as it reverses
  /// instead of shrinking back into the finger.
  final Animation<double> closing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    const d = _FocusedCardState._buttonDiameter;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: armed ? 1 : 0),
      duration: armDuration,
      curve: Curves.easeOutBack,
      builder: (context, arm, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: muted ? 0.55 : 1),
        duration: armDuration,
        builder: (context, fade, _) => AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            final t = progress.value;
            final double opacity;
            final double scale;
            final Offset at;
            if (fired) {
              final open = closing.value;
              opacity = open.clamp(0.0, 1.0);
              scale = 1.18 + 0.3 * (1 - open);
              at = center + pull;
            } else {
              opacity = t.clamp(0.0, 1.0) * fade;
              scale = (0.35 + 0.65 * t).clamp(0.0, 1.08) * (1 + 0.18 * arm);
              at = Offset.lerp(origin, center, t)! + pull * arm.clamp(0.0, 1.0);
            }
            return Positioned(
              left: at.dx - d / 2,
              top: at.dy - d / 2,
              width: d,
              height: d,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Semantics(
                    button: true,
                    label: action.label,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(c.surface, c.accent, arm.clamp(0.0, 1.0)),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.border, width: 1.5),
                        boxShadow: [hardShadow(lerpDouble(Lift.l2, Lift.l4, arm.clamp(0.0, 1.0))!, c.border)],
                      ),
                      child: Center(
                        child: UiIcon(
                          action.icon,
                          size: 20,
                          color: Color.lerp(c.text, c.accentFg, arm.clamp(0.0, 1.0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Name of the armed action, in a square ink chip just above its button
/// (below it when the button sits near the top of the screen).
class _ArmedLabel extends StatelessWidget {
  const _ArmedLabel({super.key, required this.anchor, required this.label, required this.duration});

  final Offset anchor;
  final String label;
  final Duration duration;

  static const double _width = 120;
  static const double _gap = _FocusedCardState._buttonDiameter / 2 + 16;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final above = anchor.dy - _gap - 32 > MediaQuery.paddingOf(context).top;
    final top = above ? anchor.dy - _gap - 28 : anchor.dy + _gap;
    final maxLeft = math.max(8.0, MediaQuery.sizeOf(context).width - _width - 8);
    final left = (anchor.dx - _width / 2).clamp(8.0, maxLeft);
    return Positioned(
      left: left,
      top: top,
      width: _width,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, (above ? 6 : -6) * (1 - t)), child: child),
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                boxShadow: [hardShadow(Lift.l2, c.border)],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExcludeSemantics(child: Text(label, style: UiText.chip.copyWith(color: c.text))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
