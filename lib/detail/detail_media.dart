/// Media column of the detail view (§10.9): device toggle, framed preview,
/// caption and the strip of sibling screens.
library;

import 'package:flutter/material.dart' hide Viewport;

import '../data/catalog.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../mock/mock_screen.dart';
import '../router/detail.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/hover_tap.dart';

class DetailMedia extends StatelessWidget {
  const DetailMedia({
    super.key,
    required this.item,
    required this.device,
    required this.onDevice,
    required this.topRightGap,
    this.showSiblings = true,
  });

  final Item item;
  final Viewport device;
  final ValueChanged<Viewport> onDevice;
  final double topRightGap;

  /// Build the strip of sibling screens (each is a full mock preview).
  final bool showSiblings;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final size = MediaQuery.sizeOf(context);
    final native = MockScreen.nativeViewport(item);
    final siblings = item.kind == Kind.component || !showSiblings
        ? const <Item>[]
        : kItems
            .where((i) => i.source.slug == item.source.slug && i.kind == Kind.screen)
            .take(6)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // The toggle's 48 hit area overhangs its 34 box by 7: 5 + 7 keeps the 12 gap.
          padding: EdgeInsets.only(bottom: 5, right: topRightGap),
          child: Row(
            children: [
              _DeviceToggle(device: device, onChanged: onDevice),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Captured ${timeAgo(item.daysAgo)} · ${compact(item.views)} views',
                  textAlign: TextAlign.right,
                  style: UiText.small.copyWith(color: c.text3),
                ),
              ),
            ],
          ),
        ),
        // Long captures scroll inside the frame rather than making the page enormous.
        Container(
          padding: EdgeInsets.all(size.width >= Bp.md ? 20 : 12),
          decoration: BoxDecoration(color: c.bgSubtle, border: Border.all(color: c.border)),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = device == Viewport.desktop ? box.maxWidth : device.w.clamp(0, box.maxWidth).toDouble();
              return Center(
                child: AnimatedContainer(
                  duration: motion(context, kFrameSwitch),
                  curve: kEase,
                  width: w,
                  constraints: BoxConstraints(maxHeight: size.height * 0.76),
                  decoration: BoxDecoration(border: Border.all(color: c.border)),
                  child: Semantics(
                    label: '${item.title} preview, ${device.label}',
                    child: SingleChildScrollView(
                      child: MockScreen(key: ValueKey(device), item: item, viewport: device),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${device.label} · ${device.w.toInt()} × ${device.h.toInt()} · '
            '${device == native ? 'original design' : 'adapted from the ${native.label.toLowerCase()} design'}'
            ' · scroll inside the frame',
            textAlign: TextAlign.center,
            style: UiText.caption.copyWith(color: c.text3),
          ),
        ),
        if (siblings.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in siblings) ...[
                  if (s != siblings.first) const SizedBox(width: 8),
                  _SiblingTile(item: s, current: s.slug == item.slug),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DeviceToggle extends StatelessWidget {
  const _DeviceToggle({required this.device, required this.onChanged});

  final Viewport device;
  final ValueChanged<Viewport> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    // The bordered strip stays 34 tall (28 segments + 2 padding + 1 border);
    // each segment's hit area extends to 48 above and below it (§14).
    return Semantics(
      container: true,
      label: 'Device',
      child: Stack(
        children: [
          Positioned.fill(
            top: 7,
            bottom: 7,
            child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.border))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final vp in Viewport.values) ...[
                  if (vp != Viewport.values.first) const SizedBox(width: 4),
                  HoverTap(
                    onTap: () => onChanged(vp),
                    toggled: vp == device,
                    label: vp.label,
                    builder: (context, hovered) {
                      final on = vp == device;
                      return AnimatedContainer(
                        duration: motion(context, kTransition),
                        height: 28,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        color: on ? c.accent : null,
                        child: Text(
                          vp.label,
                          style: UiText.small.copyWith(
                            color: on ? c.accentFg : (hovered ? c.text : c.text2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SiblingTile extends StatelessWidget {
  const _SiblingTile({required this.item, required this.current});

  final Item item;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: current ? () {} : () => openDetail(context, item),
      link: true,
      label: item.title,
      selected: current,
      builder: (context, hovered) => Container(
        width: 112,
        decoration: BoxDecoration(
          border: Border.all(color: current ? c.text : (hovered ? c.borderStrong : c.border)),
        ),
        child: AspectRatio(
          aspectRatio: 1.5,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: MockScreen(item: item, full: true),
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------- rail */
