import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../data/models.dart';
import '../../mock/mock_screen.dart';
import '../../router/detail.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/lift_on_press.dart';
import '../core/ui_icon.dart';
import '../save/save_button.dart';
import 'item_aspect.dart';

/// Feed plate (§10.2): matted preview, PRO badge, hover corner badges (≥768),
/// catalogue caption and an icon [SaveButton] bottom-right.
///
/// [crop] (width / height) fixes the plate's aspect so cards line up in a row.
/// Tapping opens the detail overlay.
class FeedCard extends StatefulWidget {
  const FeedCard(this.item, {super.key, this.crop});

  final Item item;
  final double? crop;

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  final ValueNotifier<bool> _lifted = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _lifted.dispose();
    super.dispose();
  }

  void _open() => openDetail(context, widget.item).ignore();

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final c = context.ui;
    final wide = MediaQuery.sizeOf(context).width >= Bp.md;
    final preview = widget.crop == null ? item : withAspect(item, widget.crop!);

    final plate = DecoratedBox(
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border)),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(border: Border.all(color: c.border)),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Stack(
              children: [
                MockScreen(item: preview),
                if (item.isPremium) const Positioned(left: 6, top: 6, child: _ProBadge()),
                if (wide)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _lifted,
                      builder: (context, lifted, child) => AnimatedOpacity(
                        opacity: lifted ? 1 : 0,
                        duration: motion(context, kTransition),
                        child: child,
                      ),
                      child: _CornerBadges(item: item),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              LiftOnPress(
                onTap: _open,
                semanticLabel: item.title,
                onLiftChanged: (v) => _lifted.value = v,
                child: plate,
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _open,
                child: ExcludeSemantics(child: _Caption(item: item)),
              ),
            ],
          ),
          // 48dp hit area centred on the 28px icon, which sits flush bottom-right.
          Positioned(right: -10, bottom: -10, child: SaveButton(item.slug)),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.cardTitle.copyWith(color: c.text),
          ),
          const SizedBox(height: 2),
          Text(
            item.kind == Kind.component ? '${item.source.name} · component' : item.source.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.meta.copyWith(color: c.text2),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.palette.accent,
                  border: Border.all(color: c.border),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${compact(item.saves)} saves',
                style: UiText.meta.copyWith(color: c.text, fontFeatures: UiText.tabular),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.signal, border: Border.all(color: c.onSignal)),
      child: Text('PRO', style: UiText.badge.copyWith(color: c.onSignal)),
    );
  }
}

/// Code / 3D / Component badges: fixed paper + ink, theme independent.
class _CornerBadges extends StatelessWidget {
  const _CornerBadges({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final badges = <(Ui, String)>[
      if (item.hasCode) (Ui.code, 'Code available'),
      if (item.has3d) (Ui.sparkle, '3D / WebGL'),
      if (item.kind == Kind.component) (Ui.layers, 'Component'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (int i, (Ui icon, String title)) in badges.indexed) ...[
          if (i > 0) const SizedBox(width: 4),
          Tooltip(
            message: title,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: UiverseColors.paperBadge,
                border: Border.all(color: UiverseColors.ink),
              ),
              child: UiIcon(icon, size: 12, color: UiverseColors.ink),
            ),
          ),
        ],
      ],
    );
  }
}
