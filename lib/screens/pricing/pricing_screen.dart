import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/ui_icon.dart';
import '../directory/box_button.dart';
import '../directory/directory_page.dart';

/// A plan card's content.
typedef Plan = ({String name, String price, String note});

const List<Plan> kPlans = [
  (name: 'Free', price: '£0', note: 'Everything you need to browse and keep references.'),
  (name: 'Pro', price: '£12', note: 'For people who ship interfaces every week.'),
  (name: 'Team', price: '£9', note: 'Per seat. Shared boards, libraries and roles.'),
];

/// Comparison rows: feature, Free, Pro, Team. `✓` renders as a Check icon.
const List<List<String>> kPlanRows = [
  ['Browse everything', '✓', '✓', '✓'],
  ['Save', 'Unlimited', 'Unlimited', 'Unlimited'],
  ['Collections', '5, public', 'Unlimited, private', 'Unlimited'],
  ['Filters', 'Core', 'All', 'All'],
  ['Breakdown tab', 'Colours + type', 'Full', 'Full'],
  ['Full screen sets', 'First 3', 'Full', 'Full'],
  ['AI prompt generation', '3 / month', 'Unlimited', 'Unlimited'],
  ['Palette export', 'Copy hex', 'CSS + Tailwind', '+ team palettes'],
  ['Layouts', '1', 'Unlimited', 'Unlimited'],
  ['Team workspaces', '—', '—', '✓'],
  ['Shared collections + roles', '—', '—', '✓'],
];

/// `/pricing` (§12): centred intro, three plan cards (stacked below 1024),
/// comparison table (scrolls sideways when narrow) and a footer line.
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    // Side by side from lg: at md the rail leaves ~160px per card, too tight
    // for the 38px price row in Space Mono.
    final bool row = MediaQuery.sizeOf(context).width >= Bp.lg;
    final List<Widget> cards = [
      for (int i = 0; i < kPlans.length; i++) PlanCard(plan: kPlans[i], popular: i == 1, first: i == 0, fill: row),
    ];
    return NarrowPage(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Simple, honest pricing',
                  textAlign: TextAlign.center,
                  style: UiText.mono(34, bold: true, height: 1.2, track: -0.03, color: c.text),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Text(
                  'Depth and output are paid for. Discovery never is — browsing and saving stay '
                  'unlimited on Free, because that loop is the product.',
                  textAlign: TextAlign.center,
                  style: UiText.mono(14.5, height: 1.625, color: c.text2),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: row
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      cards[i],
                    ],
                  ],
                ),
        ),
        const ComparisonTable(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No countdown timers, no fake scarcity, cancel in one click.',
            textAlign: TextAlign.center,
            style: UiText.chip.copyWith(color: c.text3),
          ),
        ),
      ],
    );
  }
}

/// One plan. [popular] gets the `text` border, surface fill, "Popular" badge
/// and an accent button.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, this.popular = false, this.first = false, this.fill = false});

  final Plan plan;
  final bool popular;
  final bool first;

  /// Push the button to the bottom (cards side by side at equal height).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: popular ? c.surface : null,
        border: Border.all(color: popular ? c.text : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(plan.name, style: UiText.mono(15, bold: true, color: c.text))),
              if (popular) const PopularBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(plan.price, style: UiText.mono(38, bold: true, height: 1.1, track: -0.03, color: c.text)),
              const SizedBox(width: 6),
              Flexible(child: Text('/month', maxLines: 1, style: UiText.body.copyWith(color: c.text3))),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.note, style: UiText.mono(13, height: 1.625, color: c.text2)),
          if (fill) const Spacer(),
          // 40-tall button in a 48 hit area: 16 + 4 keeps the 20 gap.
          const SizedBox(height: 16),
          BoxButton(first ? 'Start free' : 'Choose plan', onTap: () {}, accent: popular),
        ],
      ),
    );
  }
}

/// "Popular" badge (§10.14): accent fill, 11px bold, 8×2.
class PopularBadge extends StatelessWidget {
  const PopularBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: c.accent,
      child: Text('Popular', style: UiText.mono(11, bold: true, color: c.accentFg)),
    );
  }
}

/// Minimum table width before it scrolls sideways.
const double kComparisonMinWidth = 600;

/// Feature comparison (§10.14 "Table (pricing)").
class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget cell(String v, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: v == '✓'
              ? Align(alignment: Alignment.centerLeft, child: UiIcon(Ui.check, size: 14, color: c.text, semanticLabel: 'Included'))
              : Text(v, style: UiText.body.copyWith(color: color ?? c.text)),
        );
    BoxDecoration rule(bool last) =>
        BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.border)));

    return LayoutBuilder(
      builder: (context, box) {
        final double width = math.max(box.maxWidth, kComparisonMinWidth);
        final table = Container(
          width: width,
          decoration: BoxDecoration(border: Border.all(color: c.border)),
          child: Table(
            columnWidths: const {0: FlexColumnWidth(1.5)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: c.bgSubtle, border: Border(bottom: BorderSide(color: c.border))),
                children: [
                  cell('Feature', color: c.text3),
                  for (final Plan p in kPlans) cell(p.name),
                ],
              ),
              for (int r = 0; r < kPlanRows.length; r++)
                TableRow(
                  decoration: rule(r == kPlanRows.length - 1),
                  children: [
                    cell(kPlanRows[r][0], color: c.text2),
                    for (final String v in kPlanRows[r].skip(1)) cell(v),
                  ],
                ),
            ],
          ),
        );
        if (width <= box.maxWidth) return table;
        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
      },
    );
  }
}
