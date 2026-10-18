import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/spec.dart';
import '../router/routes.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/copy_value.dart';
import '../widgets/core/hover_tap.dart';
import '../widgets/core/ink_box.dart';
import 'parts.dart';
import '../widgets/core/links.dart';

/// `:root`-style CSS custom properties for [roles] (web "Copy as CSS variables").
String cssVariables(List<ColorRole> roles) =>
    roles.map((r) => '  --${r.token}: ${r.value};').join('\n');

/// A Tailwind v4 `@theme` block for [roles] (web "Copy as Tailwind theme").
String tailwindTheme(List<ColorRole> roles) =>
    '@theme {\n${roles.map((r) => '  --color-${r.token}: ${r.value};').join('\n')}\n}';

/// `accent-fg` -> `accentFg`, for a Swift identifier.
String _swiftIdentifier(String token) {
  final parts = token.split('-');
  return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// A `Color` extension block for [roles] (free "Copy as SwiftUI colors").
String swiftUiTheme(List<ColorRole> roles) {
  String channel(String hex, int start) => (int.parse(hex.substring(start, start + 2), radix: 16) / 255)
      .toStringAsFixed(3);
  final lines = roles.map((r) {
    final hex = r.value.substring(1); // drop '#'
    return '  static let ${_swiftIdentifier(r.token)} = '
        'Color(red: ${channel(hex, 0)}, green: ${channel(hex, 2)}, blue: ${channel(hex, 4)})';
  }).join('\n');
  return 'extension Color {\n$lines\n}';
}

/// The "Understand" step (§10.10): section outline, derived layout, colour
/// roles, type scale and spacing rhythm, all derived from the capture.
class Breakdown extends StatelessWidget {
  const Breakdown({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SplitRow(first: _Outline(item: item), second: _DerivedLayout(item: item)),
        const SizedBox(height: 16),
        SplitRow(
          first: _ColourRoles(item: item),
          second: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TypeScale(item: item),
              const SizedBox(height: 16),
              _Spacing(item: item),
            ],
          ),
        ),
      ],
    );
  }
}

class _Outline extends StatelessWidget {
  const _Outline({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final p = item.palette;
    final list = sections(item);
    return Panel(
      title: 'Section outline',
      note: '${list.length} blocks detected',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in list)
            HoverTap(
              link: true,
              label: '${s.label}, ${s.type}',
              onTap: () => goTo(
                context,
                Uri(path: Routes.components, queryParameters: {'component': s.type}).toString(),
              ),
              builder: (context, hovered) => AnimatedContainer(
                duration: motion(context, kTransition),
                width: double.infinity,
                color: hovered ? c.bgSubtle : null,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        s.index.toString().padLeft(2, '0'),
                        style: UiText.meta.copyWith(color: c.text3, fontFeatures: UiText.tabular),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: s.index == 1
                            ? p.surface
                            : (s.index - 1) % 3 == 1
                                ? p.raised
                                : p.bg,
                        border: Border.all(color: c.border),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(s.type, style: UiText.meta.copyWith(color: c.text3)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DerivedLayout extends StatelessWidget {
  const _DerivedLayout({required this.item});

  final Item item;

  static double _height(String type) =>
      22 + (type == 'hero' ? 36 : type == 'footer' ? 18 : 10);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Panel(
      title: 'Derived layout',
      note: 'the page as a reusable structure',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < item.blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            InkBox(
              dashed: true,
              color: Colors.transparent,
              child: SizedBox(
                height: _height(item.blocks[i].type),
                child: Center(
                  child: Text(
                    item.blocks[i].label,
                    style: UiText.caption.copyWith(color: c.text2),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: LinkInk.quiet('Save as a layout →', onTap: () => goTo(context, Routes.layouts)),
          ),
        ],
      ),
    );
  }
}

class _ColourRoles extends StatelessWidget {
  const _ColourRoles({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final roles = colorRoles(item);
    return Panel(
      title: 'Colour roles',
      note: 'extracted from computed styles',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in roles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: r.color, border: Border.all(color: c.border)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.label, style: UiText.chip.copyWith(color: c.text))),
                  CopyValue(r.value, mono: true),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
            child: Wrap(
              spacing: 8,
              children: [
                CopyValue(cssVariables(roles), label: 'Copy as CSS variables', bordered: true),
                CopyValue(tailwindTheme(roles), label: 'Copy as Tailwind theme', bordered: true),
                CopyValue(swiftUiTheme(roles), label: 'Copy as SwiftUI colors', bordered: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Panel(
      title: 'Type scale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in typeScale(item))
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(t.name, style: UiText.caption.copyWith(color: c.text3)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.use,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // Space Mono only ships 400/700: 600+ renders bold (§3.1).
                    style: UiText.mono(
                      math.min(t.size, 26),
                      bold: t.weight >= 600,
                      height: 1.25,
                      track: -0.02,
                      color: c.text,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CopyValue('${jsNum(t.size)}px / ${t.weight}', mono: true),
              ],
            ),
        ],
      ),
    );
  }
}

class _Spacing extends StatelessWidget {
  const _Spacing({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final layout = layoutSpec(item);
    Widget fact(String label, String value) => Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(label, style: UiText.chip.copyWith(color: c.text3)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: UiText.monoValue.copyWith(color: c.text),
              ),
            ),
          ],
        );
    return Panel(
      title: 'Spacing rhythm',
      note: '4px base',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (final s in kSpacing)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: math.min(s, 40).toDouble(),
                      height: 26,
                      color: c.text.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 6),
                    Text('$s', style: UiText.mono(10.5, color: c.text3)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: fact('Radius', layout.radius)),
                  const SizedBox(width: 16),
                  Expanded(child: fact('Grid', '${layout.columns}, ${layout.gutter}')),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: fact('Body', layout.body)),
                  const SizedBox(width: 16),
                  Expanded(child: fact('Container', layout.container)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
