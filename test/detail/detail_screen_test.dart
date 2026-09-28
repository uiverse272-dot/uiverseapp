import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/format.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/detail/detail_screen.dart';
import 'package:uiverse/detail/detail_tabs.dart';
import 'package:uiverse/mock/mock_screen.dart';
import 'package:uiverse/widgets/core/hover_tap.dart';
import 'package:uiverse/widgets/core/lift_on_press.dart';

import 'detail_harness.dart';

Finder _tab(String label) =>
    find.descendant(of: find.byType(DetailTabBar), matching: find.text(label));

/// Scrolls [f] into view, taps it and settles.
Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// A [HoverTap] / [LiftOnPress] by its accessible label (works off screen,
/// where semantics nodes are pruned).
Finder _labelled(String label) => find.byWidgetPredicate(
  (w) => (w is HoverTap && w.label == label) || (w is LiftOnPress && w.semanticLabel == label),
);

Finder _frame(Viewport vp) =>
    find.byWidgetPredicate((w) => w is MockScreen && w.viewport == vp && w.key == ValueKey(vp));

void main() {
  const screenSlug = 's001-ledgerly-homepage';
  const componentSlug = 'c0011-ledgerly-navbar';

  testWidgets('screen detail shows title, byline, meta and similar designs', (tester) async {
    await pumpDetail(tester, const DetailScreen(slug: screenSlug));
    final item = bySlug(screenSlug)!;

    expect(find.text(item.title), findsOneWidget);
    expect(find.bySemanticsLabel('By: ${item.source.name}'), findsOneWidget);
    expect(
      find.text('Captured ${timeAgo(item.daysAgo)} · ${compact(item.views)} views'),
      findsOneWidget,
    );
    for (final label in ['Type', 'Industry', 'Style', 'Platform', 'Stack', 'Saves']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(compact(item.saves)), findsOneWidget);
    expect(find.text('Open live site'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Similar designs'), findsOneWidget);
    expect(find.text('What this screen does'), findsOneWidget);
    // Sibling strip: screens from the same source.
    expect(find.bySemanticsLabel(item.title), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('component detail says "Related components" and has no sibling strip', (
    tester,
  ) async {
    await pumpDetail(tester, const DetailScreen(slug: componentSlug));
    final item = bySlug(componentSlug)!;
    expect(find.text(item.title), findsOneWidget);
    expect(find.text('Related components'), findsOneWidget);
    expect(find.text('Similar designs'), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is MockScreen && w.full),
      findsNothing,
      reason: 'the sibling strip renders full MockScreens; components have none',
    );
  });

  testWidgets('unknown slug shows a not-found message', (tester) async {
    await pumpDetail(tester, const DetailScreen(slug: 'nope'));
    expect(find.text('Not found'), findsOneWidget);
    expect(find.text('Back to the feed'), findsOneWidget);
  });

  testWidgets('device toggle switches the frame and caption', (tester) async {
    await pumpDetail(tester, const DetailScreen(slug: screenSlug));
    expect(_frame(Viewport.desktop), findsOneWidget);
    expect(
      find.text('Laptop · 1440 × 900 · original design · scroll inside the frame'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Tablet'));
    await tester.pumpAndSettle();
    expect(_frame(Viewport.tablet), findsOneWidget);
    expect(_frame(Viewport.desktop), findsNothing);
    expect(
      find.text('Tablet · 834 × 1194 · adapted from the laptop design · scroll inside the frame'),
      findsOneWidget,
    );
    // The tablet frame is drawn at its real width inside the column.
    expect(tester.getSize(_frame(Viewport.tablet)).width, closeTo(832, 1));

    await tester.tap(find.bySemanticsLabel('Mobile'));
    await tester.pumpAndSettle();
    expect(_frame(Viewport.mobile), findsOneWidget);
  });

  testWidgets('tabs switch content; Similar hides the trailing section', (tester) async {
    await pumpDetail(tester, const DetailScreen(slug: screenSlug));
    final item = bySlug(screenSlug)!;

    await _tap(tester, _tab('Breakdown'));
    expect(find.text('Section outline'), findsOneWidget);
    expect(find.text('${item.blocks.length} blocks detected'), findsOneWidget);
    expect(find.text('What this screen does'), findsNothing);

    await _tap(tester, _tab('Responsive'));
    expect(find.text('How it adapts'), findsOneWidget);
    expect(find.text('1440px · original'), findsOneWidget);

    await _tap(tester, _tab('Code'));
    expect(item.hasCode, isTrue);
    expect(find.text('MIT · contributed'), findsOneWidget);

    await _tap(tester, _tab('Similar'));
    expect(find.text('Similar designs'), findsNothing);
    expect(find.byType(MiniCard), findsNWidgets(12));
  });

  testWidgets('responsive tile switches the device', (tester) async {
    await pumpDetail(tester, const DetailScreen(slug: screenSlug));
    await _tap(tester, _tab('Responsive'));
    await _tap(tester, _labelled('Show Mobile preview'));
    expect(_frame(Viewport.mobile), findsOneWidget);
  });

  testWidgets('action trio Code / Breakdown switch tabs', (tester) async {
    await pumpDetail(tester, const DetailScreen(slug: componentSlug));
    await _tap(tester, _labelled('Code'));
    final item = bySlug(componentSlug)!;
    expect(
      find.text(item.hasCode ? 'MIT · contributed' : 'No code for this capture'),
      findsOneWidget,
    );

    await _tap(tester, _labelled('Breakdown'));
    expect(find.text('Section outline'), findsOneWidget);
  });

  testWidgets('custom cardBuilder renders the similar cards', (tester) async {
    await pumpDetail(
      tester,
      DetailScreen(slug: screenSlug, cardBuilder: (context, item) => Text('card:${item.slug}')),
    );
    expect(find.textContaining('card:'), findsNWidgets(6));
    expect(find.byType(MiniCard), findsNothing);
  });

  for (final width in [390.0, 800.0]) {
    testWidgets('lays out at $width wide without overflow', (tester) async {
      await pumpDetail(tester, const DetailScreen(slug: screenSlug), width: width, height: 844);
      expect(find.text(bySlug(screenSlug)!.title), findsOneWidget);
      for (final t in ['Breakdown', 'Responsive', 'Code']) {
        await _tap(tester, _tab(t));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a capture without code offers the prompt instead', (tester) async {
    final noCode = kItems.firstWhere((i) => !i.hasCode);
    await pumpDetail(tester, DetailScreen(slug: noCode.slug));
    await _tap(tester, _tab('Code'));
    expect(find.text('No code for this capture'), findsOneWidget);
    expect(find.text('Generate an implementation prompt instead'), findsOneWidget);
  });
}
