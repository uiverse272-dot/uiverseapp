/// Rail of the detail view (§10.9): title, byline, actions, meta list, about,
/// tags and the attribution note.
library;

import 'package:flutter/material.dart' hide Viewport;

import '../data/format.dart';
import '../data/models.dart';
import '../data/taxonomy.dart';
import '../router/routes.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/hover_tap.dart';
import '../widgets/core/links.dart';
import '../widgets/core/ui_icon.dart';
import '../widgets/save/save_button.dart';
import 'detail_tabs.dart';
import 'parts.dart';

class DetailRail extends StatelessWidget {
  const DetailRail({super.key, 
    required this.item,
    required this.topRightGap,
    required this.onPrompt,
    required this.onTab,
  });

  final Item item;
  final double topRightGap;
  final VoidCallback onPrompt;
  final ValueChanged<DetailTab> onTab;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final tags = <String>[item.category, item.industry, item.style, ...item.tech];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(right: topRightGap),
          child: Semantics(
            header: true,
            child: Text(item.title, style: UiText.detailTitle.copyWith(color: c.text)),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: HoverTap(
            onTap: () => goTo(context, Routes.source(item.source.slug)),
            link: true,
            label: 'By: ${item.source.name}',
            builder: (context, hovered) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.palette.accent,
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(width: 8),
                Text('By: ', style: UiText.chip.copyWith(color: c.text)),
                Text(
                  item.source.name,
                  style: UiText.chip.copyWith(
                    color: hovered ? c.accent : c.text,
                    decoration: TextDecoration.underline,
                    decorationColor: hovered ? c.accent : c.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 44-tall buttons below sit in 48 hit areas; the gaps shrink by the overhang.
        const SizedBox(height: 8),
        Tooltip(
          message: 'This would open ${item.source.domain}',
          child: HoverTap(
            // Deliberately inert: captures are indexed, not linked out, in this demo.
            onTap: () {},
            label: 'Open live site',
            builder: (context, hovered) => Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hovered ? c.bgSubtle : c.surface,
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiIcon(Ui.external, size: 15, color: c.text),
                  const SizedBox(width: 8),
                  Text('Open live site', style: UiText.button.copyWith(color: c.text)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SaveButton(item.slug, variant: SaveButtonVariant.solid, expand: true),
        const SizedBox(height: 10),
        _ActionTrio(
          onPrompt: onPrompt,
          onCode: () => onTab(DetailTab.code),
          onBreakdown: () => onTab(DetailTab.breakdown),
        ),
        const SizedBox(height: 24),
        _MetaList(item: item),
        const SizedBox(height: 16),
        Text(item.source.about, style: UiText.mono(12.5, height: 1.625, color: c.text)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final t in tags)
              HoverTap(
                onTap: () => goTo(context, Routes.searchFor(t)),
                link: true,
                builder: (context, hovered) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hovered ? c.bgSubtle : null,
                    border: Border.all(color: c.border),
                  ),
                  child: Text(t, style: UiText.caption.copyWith(color: hovered ? c.text : c.text2)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: InlineLinkText(
            before: 'Preview rendered from the capture. Attribution links to the source; ',
            link: 'attribution policy',
            after: '.',
            onTap: () => goTo(context, Routes.legal('attribution')),
            style: UiText.mono(11.5, height: 1.625, color: c.text3),
          ),
        ),
      ],
    );
  }
}

class _ActionTrio extends StatelessWidget {
  const _ActionTrio({required this.onPrompt, required this.onCode, required this.onBreakdown});

  final VoidCallback onPrompt;
  final VoidCallback onCode;
  final VoidCallback onBreakdown;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final actions = <(String, Ui, VoidCallback)>[
      ('Prompt', Ui.sparkle, onPrompt),
      ('Code', Ui.code, onCode),
      ('Breakdown', Ui.layers, onBreakdown),
    ];
    return Container(
      decoration: BoxDecoration(border: Border.all(color: c.border)),
      child: Row(
        children: [
          for (final (i, (label, icon, run)) in actions.indexed)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(left: BorderSide(color: c.border)),
                ),
                child: HoverTap(
                  onTap: run,
                  label: label,
                  builder: (context, hovered) => AnimatedContainer(
                    duration: motion(context, kTransition),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: hovered ? c.bgSubtle : null,
                    child: Column(
                      children: [
                        UiIcon(icon, size: 19, color: c.text),
                        const SizedBox(height: 6),
                        Text(label, style: UiText.meta.copyWith(color: c.text)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaList extends StatelessWidget {
  const _MetaList({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    String web(String param, String value) =>
        Uri(path: Routes.web, queryParameters: {param: value}).toString();
    final rows = <(String, String, String?)>[
      ('Type', taxName(kCategories, item.category), web('category', item.category)),
      ('Industry', taxName(kIndustries, item.industry), web('industry', item.industry)),
      ('Style', taxName(kStyles, item.style), web('style', item.style)),
      ('Platform', item.platform == 'web' ? 'Web' : item.platform.toUpperCase(), null),
      (
        'Stack',
        item.tech.map((t) => taxName(kTechnologies, t)).join(', '),
        item.tech.isEmpty ? null : web('tech', item.tech.first),
      ),
      ('Saves', compact(item.saves), null),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border), bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value, href) in rows)
            _MetaRow(label: label, value: value, onTap: href == null ? null : () => goTo(context, href)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget row(bool hovered) => Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 32),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SizedBox(width: 88, child: Text(label, style: UiText.small.copyWith(color: c.text2))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.small.copyWith(color: hovered ? c.accent : c.text),
                ),
              ),
            ],
          ),
        );
    if (onTap == null) return row(false);
    return HoverTap(
      onTap: onTap,
      link: true,
      label: '$label: $value',
      minSize: const Size(48, 32),
      builder: (context, hovered) => row(hovered),
    );
  }
}
