import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/widgets/feed/feed.dart';
import 'package:uiverse/widgets/feed/feed_card.dart';

import 'themed_harness.dart';

void main() {
  FeedState feedState(WidgetTester tester) => tester.state<FeedState>(find.byType(Feed));

  Future<void> scrollToEnd(WidgetTester tester) async {
    final scrollable = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(scrollable).position;
    // Extents below the built range are estimates: repeat until the end is real.
    for (var i = 0; i < 20; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      if (position.pixels == position.maxScrollExtent) break;
    }
    await tester.pumpAndSettle();
  }

  testWidgets('shows 28, auto-loads up to 5 pages, then Load more, then the end line', (tester) async {
    await pumpThemed(tester, CustomScrollView(slivers: [Feed(items: kItems)]));
    expect(feedState(tester).shown, 28);
    expect(find.byType(FeedCard), findsWidgets);
    expect(find.text('Load more'), findsNothing);

    // Scrolling towards the end loads one page at a time, up to 5 pages (140).
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final seen = <int>[28];
    for (var i = 0; i < 60 && seen.last < 140; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      if (feedState(tester).shown != seen.last) seen.add(feedState(tester).shown);
    }
    expect(seen, [28, 56, 84, 112, 140]);
    await scrollToEnd(tester);
    expect(feedState(tester).shown, 140, reason: 'no auto-load past 5 pages');
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(feedState(tester).shown, 168);

    await scrollToEnd(tester);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(feedState(tester).shown, kItems.length);

    await scrollToEnd(tester);
    expect(find.text('Load more'), findsNothing);
    expect(find.text('${kItems.length} results · end of feed'), findsOneWidget);
  });

  testWidgets('a short list shows the end line straight away', (tester) async {
    await pumpThemed(tester, CustomScrollView(slivers: [Feed(items: kItems.take(3).toList())]));
    expect(find.byType(FeedCard), findsNWidgets(3));
    expect(find.text('3 results · end of feed'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    await pumpThemed(tester, const CustomScrollView(slivers: [Feed(items: [])]));
    expect(find.text('Nothing matches those filters'), findsOneWidget);
    expect(
      find.text('Try removing a filter, or browse Explore to start from a category instead.'),
      findsOneWidget,
    );
  });

  testWidgets('a new item list resets to the first page', (tester) async {
    var items = kItems;
    late StateSetter set;
    await pumpThemed(
      tester,
      StatefulBuilder(builder: (context, s) {
        set = s;
        return CustomScrollView(slivers: [Feed(items: items)]);
      }),
    );
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    while (feedState(tester).shown == 28) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(feedState(tester).shown, greaterThan(28));
    tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
    await tester.pumpAndSettle();
    set(() => items = kItems.reversed.toList());
    await tester.pumpAndSettle();
    expect(feedState(tester).shown, 28);
  });
}
