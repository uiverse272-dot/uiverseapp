import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/taxonomy.dart';
import '../../mock/mock_screen.dart';
import '../../router/detail.dart';
import '../../router/routes.dart';
import '../../state/pick.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/hover_tap.dart';
import '../core/ui_icon.dart';
import '../save/save_button.dart';
import '../section/link_ink.dart';
import 'item_aspect.dart';

/// Delay before the card auto-opens on ≥768 (§6).
const Duration kPickAutoOpen = Duration(milliseconds: 700);

enum _Mode { tab, card, open }

/// Pick of the week (§10.8), floating over the home feed — the caller
/// positions it (right 16 / bottom 24 above the BottomNav on phones,
/// 24 / 24 ≥768).
///
/// Starts as a tab; on ≥768 it opens as a card 700ms after load unless folded.
/// Folding is persisted via [pickFoldedProvider].
class PickOfTheWeek extends ConsumerStatefulWidget {
  const PickOfTheWeek({super.key, required this.item});

  final Item item;

  @override
  ConsumerState<PickOfTheWeek> createState() => _PickOfTheWeekState();
}

class _PickOfTheWeekState extends ConsumerState<PickOfTheWeek> {
  _Mode _mode = _Mode.tab;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final folded = ref.read(pickFoldedProvider);
      final wide = MediaQuery.sizeOf(context).width >= Bp.md;
      if (folded || !wide) return;
      _timer = Timer(kPickAutoOpen, () {
        if (mounted && _mode == _Mode.tab) setState(() => _mode = _Mode.card);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fold() {
    _timer?.cancel();
    ref.read(pickFoldedProvider.notifier).set(true);
    setState(() => _mode = _Mode.tab);
  }

  void _unfold() {
    _timer?.cancel();
    ref.read(pickFoldedProvider.notifier).set(false);
    setState(() => _mode = _Mode.card);
  }

  void _open() => openDetail(context, widget.item).ignore();

  @override
  Widget build(BuildContext context) {
    if (_mode == _Mode.tab) return _PickTab(onTap: _unfold);
    final open = _mode == _Mode.open;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (open) setState(() => _mode = _Mode.card);
        },
      },
      child: _PickCard(
        item: widget.item,
        open: open,
        onToggle: () => setState(() => _mode = open ? _Mode.card : _Mode.open),
        onFold: _fold,
        onOpen: _open,
      ),
    );
  }
}

/// Folded tab: yellow, border, L2 shadow; hover lifts 2.
class _PickTab extends StatelessWidget {
  const _PickTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return _FadeUp(
      child: HoverTap(
        onTap: onTap,
        label: 'Pick of the week',
        builder: (context, hovered) => AnimatedContainer(
          duration: motion(context, kTransition),
          transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: c.signal,
            border: Border.all(color: c.border),
            boxShadow: [hardShadow(Lift.l2, c.border)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UiIcon(Ui.sparkle, size: 14, color: c.onSignal),
              const SizedBox(width: 8),
              Text('Pick of the week', style: UiText.mono(12, bold: true).copyWith(color: c.onSignal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({
    required this.item,
    required this.open,
    required this.onToggle,
    required this.onFold,
    required this.onOpen,
  });

  final Item item;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onFold;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final size = MediaQuery.sizeOf(context);
    return Semantics(
      container: true,
      label: 'Pick of the week',
      explicitChildNodes: true,
      child: _SheetIn(
        child: Container(
          width: math.min(340, size.width - 32),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            boxShadow: [hardShadow(Lift.l4, c.border)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(open: open, onToggle: onToggle, onFold: onFold),
              _Body(item: item, onOpen: onOpen),
              if (open)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: size.height * 0.45),
                  child: _Details(item: item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.open, required this.onToggle, required this.onFold});

  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onFold;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final divider = BorderSide(color: c.onSignal.withValues(alpha: 0.4));
    Widget button(String label, Widget Function(Color) icon, VoidCallback onTap, {bool? expanded}) => HoverTap(
          onTap: onTap,
          label: label,
          expanded: expanded,
          minSize: const Size(32, 32),
          builder: (context, hovered) => Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hovered ? Colors.black.withValues(alpha: 0.1) : null,
              border: Border(left: divider),
            ),
            child: icon(c.onSignal),
          ),
        );
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(color: c.signal, border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          UiIcon(Ui.sparkle, size: 13, color: c.onSignal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'PICK OF THE WEEK',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.eyebrow.copyWith(color: c.onSignal),
            ),
          ),
          button(
            open ? 'Show less' : 'Show details',
            (color) => UiIcon(Ui.chevron, size: 15, color: color, turns: open ? 0 : 0.5),
            onToggle,
            expanded: open,
          ),
          button('Hide pick of the week', (color) => UiIcon(Ui.close, size: 14, color: color), onFold),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item, required this.onOpen});

  final Item item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: Container(
              width: 68,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: c.bg, border: Border.all(color: c.border)),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border.all(color: c.border)),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ExcludeSemantics(child: MockScreen(item: withAspect(item, 3 / 4))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                HoverTap(
                  onTap: onOpen,
                  link: true,
                  minSize: Size.zero,
                  builder: (context, hovered) => Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.mono(14, bold: true, height: 1.375).copyWith(color: hovered ? c.accent : c.text),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('By: ', style: UiText.caption.copyWith(color: c.text)),
                    Flexible(
                      child: LinkInk(
                        item.source.name,
                        size: 11.5,
                        onTap: () => context.go(Routes.source(item.source.slug)),
                      ),
                    ),
                  ],
                ),
                Text(
                  item.source.domain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.caption.copyWith(color: c.text2),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: HoverTap(
                        onTap: onOpen,
                        minSize: const Size(0, 32),
                        builder: (context, hovered) => Container(
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: hovered ? Color.lerp(c.accent, Colors.white, 0.05) : c.accent,
                            border: Border.all(color: c.border),
                          ),
                          child: Text('Open breakdown', style: UiText.small.copyWith(color: c.accentFg)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(border: Border.all(color: c.border)),
                      child: SaveButton(item.slug),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final rows = <(String, String)>[
      ('Saves', compact(item.saves)),
      ('Type', taxName(kCategories, item.category)),
      ('Industry', taxName(kIndustries, item.industry)),
      ('Style', taxName(kStyles, item.style)),
      ('Stack', item.tech.map((t) => taxName(kTechnologies, t)).join(', ')),
      ('Captured', timeAgo(item.daysAgo)),
    ];
    return _FadeIn(
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rule))),
                child: Column(
                  children: [
                    for (final (int i, (String k, String v)) in rows.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 76,
                              child: Text(k, style: UiText.caption.copyWith(color: c.text2)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                v.isEmpty ? '—' : v,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.caption.copyWith(color: c.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(item.source.about, style: UiText.mono(12, height: 1.7).copyWith(color: c.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// `anim-sheet`: fade + rise 24 + scale 0.99 → 1 over 240ms.
class _SheetIn extends StatelessWidget {
  const _SheetIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: motion(context, kSheet),
        curve: kEase,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: Transform.scale(scale: 0.99 + 0.01 * t, child: child),
          ),
        ),
        child: child,
      );
}

/// `anim-fade-up`: fade + rise 6 over 220ms.
class _FadeUp extends StatelessWidget {
  const _FadeUp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: motion(context, kFadeUp),
        curve: kEase,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
        ),
        child: child,
      );
}

/// `anim-fade-in`: fade over 160ms.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: motion(context, kFadeIn),
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: child,
      );
}
