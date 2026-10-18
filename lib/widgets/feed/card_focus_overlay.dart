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

  /// One staggered entrance curve per action button (there are always 4),
  /// built once rather than per build so a drag mid-entrance doesn't churn
  /// through throwaway [CurvedAnimation] listeners.
  late final List<CurvedAnimation> _entranceCurves = List.generate(
    4,
    (i) => CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (i * 0.08).clamp(0.0, 1.0),
        (0.55 + i * 0.08).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    ),
  );

  Duration _closeDuration = kFocusClose;
  bool _started = false;
  int? _armed;
  bool _closing = false;

  static const double _ringRadius = 92;
  static const double _buttonDiameter = 52;
  static const double _armThreshold = _buttonDiameter;

  // Reading `motion(context, ...)` needs an inherited-widget lookup, which
  // isn't allowed yet in initState — seed the controller here instead, once.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    for (final curve in _entranceCurves) {
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

  /// Target centre of action [i] of [n], fanned above the hold point.
  Offset _target(int i, int n) {
    const start = -5 * math.pi / 6; // -150°
    const end = -math.pi / 6; // -30°
    final angle = n == 1 ? (start + end) / 2 : lerpDouble(start, end, i / (n - 1))!;
    var target = widget.holdPoint + Offset(math.cos(angle), math.sin(angle)) * _ringRadius;

    // Keep the ring on-screen.
    final size = MediaQuery.sizeOf(context);
    const margin = _buttonDiameter;
    target = Offset(
      target.dx.clamp(margin, size.width - margin),
      target.dy.clamp(margin, size.height - margin),
    );
    return target;
  }

  void updatePointer(Offset global) {
    if (_closing) return;
    setState(() {
      final actions = _actions(context);
      int? nearest;
      double best = _armThreshold;
      for (var i = 0; i < actions.length; i++) {
        final d = (_target(i, actions.length) - global).distance;
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
      HapticFeedback.mediumImpact().ignore();
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

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final actions = _actions(context);
    final rect = RectTween(begin: widget.origin, end: _focusRect).evaluate(_controller)!;
    final blur = Tween<double>(begin: 0, end: 14).evaluate(_controller);
    final dim = Tween<double>(begin: 0, end: 1).evaluate(_controller);

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => release(runAction: false).ignore(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(color: c.overlay.withValues(alpha: c.overlay.a * dim)),
          ),
        ),
        Positioned.fromRect(
          rect: rect,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                boxShadow: [hardShadow(Lift.l5, c.border)],
              ),
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
        ),
        for (final (i, action) in actions.indexed)
          _ActionButton(
            center: _target(i, actions.length),
            action: action,
            armed: _armed == i,
            progress: _entranceCurves[i],
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.center,
    required this.action,
    required this.armed,
    required this.progress,
  });

  final Offset center;
  final _RadialAction action;
  final bool armed;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    const d = _FocusedCardState._buttonDiameter;
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final raw = progress.value;
        final opacity = raw.clamp(0.0, 1.0);
        final scale = raw.clamp(0.0, 1.3) * (armed ? 1.18 : 1.0);
        return Positioned(
          left: center.dx - d / 2,
          top: center.dy - d / 2,
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
                    color: armed ? c.accent : c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border, width: 1.5),
                    boxShadow: [hardShadow(armed ? Lift.l4 : Lift.l2, c.border)],
                  ),
                  child: Center(
                    child: UiIcon(action.icon, size: 20, color: armed ? c.accentFg : c.text),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
