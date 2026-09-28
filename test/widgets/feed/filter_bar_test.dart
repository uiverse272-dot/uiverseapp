import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/query.dart';
import 'package:uiverse/data/taxonomy.dart';
import 'package:uiverse/widgets/feed/filter_bar.dart';
import 'package:uiverse/widgets/feed/option_popover.dart';

import 'themed_harness.dart';

const _defs = <FilterDef>[
  FilterDef(param: 'industry', label: 'Industry', options: kIndustries),
  FilterDef(param: 'style', label: 'Style', options: kStyles),
];

void main() {
  late Filters value;

  Future<void> pumpBar(WidgetTester tester, {required double width, Filters initial = const Filters()}) async {
    value = initial;
    await pumpThemed(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 52,
            child: FilterBar(
              defs: _defs,
              value: value,
              onChanged: (f) => setState(() => value = f),
            ),
          ),
        ),
      ),
      width: width,
    );
  }

  test('toggleParam sets, replaces and clears on reselect', () {
    var f = toggleParam(const Filters(), 'industry', 'fintech');
    expect(f.industry, 'fintech');
    f = toggleParam(f, 'industry', 'ai');
    expect(f.industry, 'ai');
    f = toggleParam(f, 'industry', 'ai');
    expect(f.industry, isNull);
    expect(toggleParam(const Filters(style: 'dark'), 'style', null).style, isNull);
  });

  testWidgets('phone: trigger opens a bottom sheet; picking sets, picking again clears', (tester) async {
    await pumpBar(tester, width: 400);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);

    await tester.tap(find.text('Industry'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionSheet), findsOneWidget);
    await tester.tap(find.text('Fintech'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionSheet), findsNothing);
    expect(value, const Filters(industry: 'fintech'));
    // Trigger now shows the chosen option; Clear appears.
    expect(find.text('Industry'), findsNothing);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Fintech'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(OptionSheet), matching: find.text('Fintech')));
    await tester.pumpAndSettle();
    expect(value, const Filters());
    expect(find.text('Industry'), findsOneWidget);
  });

  testWidgets('wide: trigger opens an anchored popover, not a sheet', (tester) async {
    await pumpBar(tester, width: 1024);
    await tester.tap(find.text('Style'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionSheet), findsNothing);
    expect(find.byType(OptionList), findsOneWidget);
    // Panel sits below the trigger.
    final trigger = tester.getRect(find.text('Style'));
    final panel = tester.getRect(find.byType(OptionList));
    expect(panel.top, greaterThan(trigger.bottom));

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionList), findsNothing);
    expect(value.style, 'dark');
  });

  testWidgets('wide: tapping outside closes the popover without changes', (tester) async {
    await pumpBar(tester, width: 1024);
    await tester.tap(find.text('Industry'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionList), findsOneWidget);
    await tester.tapAt(const Offset(900, 600));
    await tester.pumpAndSettle();
    expect(find.byType(OptionList), findsNothing);
    expect(value, const Filters());
  });

  testWidgets('sort popover, Code toggle and Clear', (tester) async {
    await pumpBar(tester, width: 1024);
    await tester.tap(find.text('Trending'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest'));
    await tester.pumpAndSettle();
    expect(value.sort, 'new');
    expect(find.text('Newest'), findsOneWidget);
    // Sort alone does not count as an active filter.
    expect(find.text('Clear'), findsNothing);

    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    expect(value.code, 'true');
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(value, const Filters());
  });

  testWidgets('ChipRail: For You selected by default; tapping selected chip clears', (tester) async {
    String? selected;
    await pumpThemed(
      tester,
      StatefulBuilder(
        builder: (context, setState) => ChipRail(
          chips: const [ChipDef('For You'), ChipDef('Dark', 'dark')],
          selected: selected,
          onSelect: (v) => setState(() => selected = v),
        ),
      ),
    );
    final handle = tester.ensureSemantics();
    expect(tester.getSemantics(find.text('For You')), isSemantics(isSelected: true));
    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(selected, 'dark');
    expect(tester.getSemantics(find.text('Dark')), isSemantics(isSelected: true));
    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(selected, isNull);
    handle.dispose();
  });
}
