import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/widgets/feed/masonry.dart';
import 'package:uiverse/widgets/feed/masonry_layout.dart';

void main() {
  group('columnsFor (useColumns thresholds)', () {
    test('window width → columns', () {
      expect(columnsFor(0), 2);
      expect(columnsFor(759), 2);
      expect(columnsFor(760), 3);
      expect(columnsFor(1179), 3);
      expect(columnsFor(1180), 4);
      expect(columnsFor(1539), 4);
      expect(columnsFor(1540), 5);
      expect(columnsFor(1899), 5);
      expect(columnsFor(1900), 6);
      expect(columnsFor(3000), 6);
    });

    test('maxCols override (phones stay ≤ 2)', () {
      expect(columnsFor(1900, maxCols: 3), 3);
      expect(columnsFor(800, maxCols: 5), 5);
      expect(columnsFor(400, maxCols: 3), 2);
      expect(columnsFor(400, maxCols: 1), 1);
    });
  });

  group('assignColumns', () {
    test('hand-computed: shortest column first, ties go left', () {
      // weights: 1.14, 2.14, 0.64, 1.14, 0.64
      // i0→c0 (0,0) h=[1.14,0]; i1→c1 h=[1.14,2.14]; i2→c0 h=[1.78,2.14];
      // i3→c0 h=[2.92,2.14]; i4→c1.
      expect(assignColumns([1, 0.5, 2, 1, 2], 2), [0, 1, 0, 0, 1]);
      // Three equal items across three columns fill left → right.
      expect(assignColumns([1, 1, 1, 1], 3), [0, 1, 2, 0]);
    });

    test('matches the web algorithm on the catalogue (3 columns)', () {
      // Independent re-statement of Masonry.tsx over the first 12 items.
      final aspects = [for (final i in kItems.take(12)) i.aspect];
      final heights = [0.0, 0.0, 0.0];
      final expected = <int>[];
      for (final a in aspects) {
        var t = 0;
        for (var c = 1; c < 3; c++) {
          if (heights[c] < heights[t]) t = c;
        }
        expected.add(t);
        heights[t] += 1 / a + 0.14;
      }
      expect(assignColumns(aspects, 3), expected);
    });

    test('appending items never moves earlier ones', () {
      final all = [for (final i in kItems) i.aspect];
      for (final cols in [2, 3, 4, 5, 6]) {
        final full = assignColumns(all, cols);
        for (final n in [28, 56, 84, 140]) {
          expect(assignColumns(all.sublist(0, n), cols), full.sublist(0, n), reason: '$cols cols, $n items');
        }
      }
    });
  });

  group('SliverMasonry layout', () {
    Widget host(List<Item> items) => MaterialApp(
          home: CustomScrollView(
            slivers: [
              Masonry(
                items: items,
                itemBuilder: (context, item, _) => SizedBox(height: 100 / item.aspect + 30),
              ),
            ],
          ),
        );

    testWidgets('places children by assigned column, and appending keeps positions', (tester) async {
      tester.view
        ..physicalSize = const Size(400, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final items = kItems.take(12).toList();
      await tester.pumpWidget(host(items));
      final cols = assignColumns([for (final i in items) i.aspect], 2);
      const colW = (400 - 16) / 2;
      final colH = [0.0, 0.0];
      final before = <String, Offset>{};
      for (var i = 0; i < items.length; i++) {
        final pos = tester.getTopLeft(find.byKey(ValueKey<String>(items[i].slug)));
        expect(pos, Offset(cols[i] * (colW + 16), colH[cols[i]]), reason: items[i].slug);
        colH[cols[i]] += 100 / items[i].aspect + 30 + 16;
        before[items[i].slug] = pos;
      }

      await tester.pumpWidget(host(kItems.take(20).toList()));
      for (final e in before.entries) {
        expect(tester.getTopLeft(find.byKey(ValueKey<String>(e.key))), e.value);
      }
    });

    testWidgets('builds lazily', (tester) async {
      tester.view
        ..physicalSize = const Size(400, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(kItems));
      expect(find.byKey(ValueKey<String>(kItems.first.slug)), findsOneWidget);
      expect(find.byKey(ValueKey<String>(kItems.last.slug), skipOffstage: false), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(ValueKey<String>(kItems.last.slug)),
        2000,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byKey(ValueKey<String>(kItems.last.slug)), findsOneWidget);
      expect(find.byKey(ValueKey<String>(kItems.first.slug), skipOffstage: false), findsNothing);
    });
  });
}
