import 'package:flutter/material.dart';

import '../../data/query.dart';
import '../../data/taxonomy.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/hover_tap.dart';
import '../core/ui_icon.dart';
import '../section/link_ink.dart';
import 'option_popover.dart';

/// One popover filter: web param name (`category`, `component`, …), trigger
/// label and options.
class FilterDef {
  const FilterDef({required this.param, required this.label, required this.options});

  final String param;
  final String label;
  final List<Tax> options;
}

/// Device options for the websites feed.
const List<Tax> kDeviceOptions = <Tax>[
  Tax('desktop', 'Desktop'),
  Tax('tablet', 'Tablet'),
  Tax('mobile', 'Mobile'),
];

/// Web `set(param, value)`: selecting the current value (or `null`) clears it.
Filters toggleParam(Filters f, String param, String? value) =>
    f.withParam(param, value == null || f.param(param) == value ? null : value);

/// Feed filter row (§10.5): popover triggers for [defs], a "Code" toggle, the
/// sort popover pushed right (default "Trending") and "Clear" while anything
/// is active. Stateless: [value] holds the URL filters, [onChanged] gets the
/// next ones (the screen syncs them to the URL).
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.defs,
    required this.value,
    required this.onChanged,
    this.sorts = kSorts,
  });

  final List<FilterDef> defs;
  final Filters value;
  final ValueChanged<Filters> onChanged;

  /// Sort options; `null` hides the sort popover.
  final List<Tax>? sorts;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final wide = context.isWide;
    final bool code = value.param('code') == 'true';
    final bool active = code || defs.any((d) => value.param(d.param) != null);
    final String? sort = value.param('sort');

    final left = <Widget>[
      if (wide)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: UiIcon(Ui.filter, size: 14, color: c.text),
        ),
      for (final d in defs)
        OptionPopover(
          label: d.label,
          options: d.options,
          selected: value.param(d.param),
          onSelect: (slug) => onChanged(toggleParam(value, d.param, slug)),
        ),
      _Toggle(
        label: 'Code',
        on: code,
        onTap: () => onChanged(value.withParam('code', code ? null : 'true')),
      ),
    ];
    final right = <Widget>[
      if (sorts != null)
        OptionPopover(
          label: 'Trending',
          title: 'Sort',
          options: sorts!,
          selected: sort,
          onSelect: (slug) => onChanged(toggleParam(value, 'sort', slug)),
        ),
      if (active)
        LinkInk(
          'Clear',
          onTap: () => onChanged(const Filters()),
          leading: (color) => UiIcon(Ui.close, size: 13, color: color),
        ),
    ];

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: box.maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _gapped(left),
              if (right.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 16), child: _gapped(right)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _gapped(List<Widget> children) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      );
}

/// "Code"-style toggle: 32 tall, border, accent fill when on.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      toggled: on,
      label: label,
      minSize: const Size(0, 48),
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? c.accent : (hovered ? c.bgSubtle : null),
          border: Border.all(color: c.border),
        ),
        child: Text(label, style: UiText.chip.copyWith(color: on ? c.accentFg : c.text)),
      ),
    );
  }
}

/// A home category chip: label and `?chip=` value (`null` = "For You").
class ChipDef {
  const ChipDef(this.label, [this.value]);

  final String label;
  final String? value;
}

/// Horizontally scrolling chip row (§10.5). The chip whose value equals
/// [selected] is filled accent; with nothing selected, "For You" is.
/// Tapping the selected chip again calls [onSelect] with `null`.
class ChipRail extends StatelessWidget {
  const ChipRail({super.key, required this.chips, required this.selected, required this.onSelect});

  final List<ChipDef> chips;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Builder(builder: (context) {
              final chip = chips[i];
              final on = chip.value != null ? selected == chip.value : selected == null && chip.label == 'For You';
              return HoverTap(
                onTap: () => onSelect(chip.value == null || chip.value == selected ? null : chip.value),
                selected: on,
                label: chip.label,
                minSize: const Size(0, 48),
                builder: (context, hovered) => AnimatedContainer(
                  duration: motion(context, kTransition),
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? c.accent : (hovered ? c.bgSubtle : c.surface),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(chip.label, style: UiText.chip.copyWith(color: on ? c.accentFg : c.text)),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
