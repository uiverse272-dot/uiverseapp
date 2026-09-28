import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/spec.dart';
import '../../detail/breakdown.dart' show cssVariables, tailwindTheme;
import '../../router/routes.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/copy_value.dart';
import '../../widgets/core/hover_tap.dart';
import '../directory/directory_page.dart';

/// `/palettes` (§12): palette cards in a 1/2/3/4-column grid.
class PalettesScreen extends StatelessWidget {
  const PalettesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DirectoryPage(
      title: 'Palettes',
      sub: 'Extracted from captures, with roles already assigned. Nothing here was hand-authored '
          '— it is a by-product of indexing screens.',
      itemCount: kPaletteItems.length,
      itemBuilder: (context, i) => PaletteCard(entry: kPaletteItems[i]),
    );
  }
}

/// The five roles a palette card shows, in strip order, as copyable roles
/// (token = web role name, e.g. `--bg`).
List<ColorRole> paletteSwatches(Palette p) => [
      for (final (String role, Color color) in [
        ('bg', p.bg),
        ('surface', p.surface),
        ('raised', p.raised),
        ('accent', p.accent),
        ('text', p.text),
      ])
        ColorRole(key: role, label: role, token: role, color: color),
    ];

/// One palette: 112-tall 5-band strip, name + saves, source link, hex list
/// and "CSS vars" / "Tailwind" copy buttons.
class PaletteCard extends StatelessWidget {
  const PaletteCard({super.key, required this.entry});

  final PaletteEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final List<ColorRole> swatches = paletteSwatches(entry.palette);
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border)),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 112,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final ColorRole s in swatches) Expanded(child: ColoredBox(color: s.color))],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          entry.palette.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.mono(14, bold: true, color: c.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        compact(entry.saves),
                        style: UiText.caption.copyWith(color: c.text3, fontFeatures: UiText.tabular),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: HoverTap(
                      onTap: () => context.go(Routes.source(entry.source.slug)),
                      link: true,
                      minSize: const Size(0, 28),
                      builder: (context, hovered) => Text(
                        'from ${entry.source.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.small.copyWith(color: hovered ? c.text : c.text3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _HexGrid(swatches: swatches),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _CopyBox(label: 'CSS vars', value: cssVariables(swatches))),
                      const SizedBox(width: 6),
                      Expanded(child: _CopyBox(label: 'Tailwind', value: tailwindTheme(swatches))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column list of 12px swatches with copyable hex values.
class _HexGrid extends StatelessWidget {
  const _HexGrid({required this.swatches});

  final List<ColorRole> swatches;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget cell(ColorRole s) => SizedBox(
          height: 30,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: s.color, border: Border.all(color: c.border)),
              ),
              const SizedBox(width: 6),
              Flexible(child: CopyValue(s.value, mono: true)),
            ],
          ),
        );
    return Column(
      children: [
        for (int i = 0; i < swatches.length; i += 2)
          Row(
            children: [
              Expanded(child: cell(swatches[i])),
              const SizedBox(width: 8),
              Expanded(child: i + 1 < swatches.length ? cell(swatches[i + 1]) : const SizedBox.shrink()),
            ],
          ),
      ],
    );
  }
}

/// Full-width bordered copy button ("CSS vars", "Tailwind").
class _CopyBox extends StatelessWidget {
  const _CopyBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(border: Border.all(color: context.ui.border)),
      alignment: Alignment.center,
      child: CopyValue(value, label: label),
    );
  }
}
