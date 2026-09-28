import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/screens/explore/explore_groups.dart';
import 'package:uiverse/screens/explore/explore_screen.dart';

import '../search/discovery_harness.dart';

void main() {
  group('exploreGroups', () {
    final groups = exploreGroups();

    test('keeps the web group order and drops empty tiles', () {
      expect(groups.map((g) => g.title), [
        'By type',
        'By component',
        'By industry',
        'By style',
        'By technology',
        'By platform',
      ]);
      expect(groups[1].note, 'cropped from real screens');
      for (final g in groups) {
        expect(g.tiles, isNotEmpty);
        expect(g.tiles.every((t) => t.count > 0), isTrue, reason: g.title);
      }
    });

    test('tiles link to filtered feeds with web query params', () {
      final type = groups[0].tiles.first;
      expect(type.label, 'Landing page');
      expect(type.href, '/web?category=landing-page');
      expect(type.count, kItems.where((i) => i.category == 'landing-page').length);
      expect(groups[1].tiles.first.href, startsWith('/components?component='));
      expect(groups[4].tiles.first.href, '/web?tech=react');
      expect(groups[5].tiles.first.href, '/apps?platform=web');
    });

    test('component tiles use component covers, others screens', () {
      for (final t in groups[1].tiles) {
        expect(t.cover?.kind, Kind.component);
      }
      for (final t in groups[0].tiles) {
        expect(t.cover?.kind, Kind.screen);
      }
    });
  });

  test('exploreColumns: 2 / 3 / 4 / 6', () {
    expect(exploreColumns(390), 2);
    expect(exploreColumns(700), 3);
    expect(exploreColumns(1024), 4);
    expect(exploreColumns(1400), 6);
  });

  for (final double width in <double>[390, 1024]) {
    testWidgets('renders header, groups and tiles ($width)', (tester) async {
      await pumpDiscovery(tester, width: width, location: '/explore');
      expect(find.text('Explore'), findsWidgets);
      expect(find.text('By type'), findsOneWidget);
      expect(find.text('Landing page'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('By platform'), 400, scrollable: find.byType(Scrollable).last);
      expect(find.text('By platform'), findsOneWidget);
    });
  }

  testWidgets('a tile opens its filtered feed', (tester) async {
    final app = await pumpDiscovery(tester, location: '/explore');
    await tester.tap(find.text('Landing page'));
    await tester.pumpAndSettle();
    expect(locationOf(app.router), '/web?category=landing-page');
    expect(find.text('stub /web?category=landing-page'), findsOneWidget);
  });
}
