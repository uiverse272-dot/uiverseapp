import 'package:flutter/widgets.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/mock/primitives.dart';

import 'fixtures.dart';

/// Reference values computed by running the web `noise` from primitives.tsx
/// under Node 22 (`node --experimental-strip-types`).
const _reference = <List<num>>[
  [0, 1, 0.7683],
  [1, 1, 0.6639],
  [0, 3, 0.5485],
  [5, 3, 0.9299],
  [27, 3, 0.1706],
  [0, 7, 0.6164],
  [33, 7, 0.1921],
  [12, 11, 0.7023],
  [4, 4, 0.2487],
  [3, 13, 0.1221],
  [2, 17, 0.2668],
  [4, 19, 0.9814],
  [1, 23, 0.6004],
  [2, 29, 0.4327],
  [4, 31, 0.6848],
  [6, 37, 0.6905],
  [7, 41, 0.6222],
  [3, 43, 0.7427],
  [-5, 2, 0.1262],
  [123456, -789, 0.5041],
  [2147483647, 2147483647, 0.1702],
  [-2147483648, 5, 0.193],
  [99, 9, 0.5136],
];

Widget _host(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    );

void main() {
  group('noise', () {
    test('matches the web hash bit for bit', () {
      for (final r in _reference) {
        expect(noise(r[0].toInt(), r[1].toInt()), r[2], reason: 'noise(${r[0]}, ${r[1]})');
      }
    });

    test('b defaults to 1', () {
      expect(noise(7), 0.2721);
      expect(noise(0), noise(0, 1));
    });
  });

  test('mockWeight maps variable weights to the nearest FontWeight', () {
    expect(mockWeight(430), FontWeight.w400);
    expect(mockWeight(450), FontWeight.w500);
    expect(mockWeight(520), FontWeight.w500);
    expect(mockWeight(550), FontWeight.w600);
    expect(mockWeight(560), FontWeight.w600);
    expect(mockWeight(600), FontWeight.w600);
  });

  group('CSS-style flex', () {
    final c = MockCtx(scale: 1, item: fixtureScreen(Archetype.dashboard, carbon), vp: Viewport.desktop);

    testWidgets('grow shares free space; explicit sizes survive stretch', (tester) async {
      const a = Key('a');
      const b = Key('b');
      const fixed = Key('fixed');
      await tester.pumpWidget(_host(SizedBox(
        width: 300,
        height: 200,
        child: MCol(c, children: [
          MRow(c, gap: 10, children: [
            B(c, key: a, w: 50, h: 20),
            MItem(grow: 1, child: B(c, key: b, h: 20)),
          ]),
          B(c, key: fixed, w: 40, h: 40),
          MItem(grow: 1, child: B(c)),
        ]),
      )));
      expect(tester.getSize(find.byKey(a)), const Size(50, 20));
      expect(tester.getSize(find.byKey(b)), const Size(240, 20));
      // Stretched slot is full width but the explicit box keeps its size.
      expect(tester.getSize(find.byKey(fixed)).height, 40);
      expect(tester.takeException(), isNull);
    });

    testWidgets('flex items split by factor with a zero basis', (tester) async {
      const a = Key('a');
      const b = Key('b');
      await tester.pumpWidget(_host(SizedBox(
        width: 300,
        child: MRow(c, children: [
          MItem(flex: 2, child: B(c, key: a, h: 10)),
          MItem(flex: 1, child: B(c, key: b, h: 10, child: T(c, 'long label text', size: 12))),
        ]),
      )));
      expect(tester.getSize(find.byKey(a)).width, 200);
      expect(tester.getSize(find.byKey(b)).width, 100);
    });

    testWidgets('overflow is painted, not reported', (tester) async {
      await tester.pumpWidget(_host(SizedBox(
        width: 100,
        height: 50,
        child: MCol(c, children: [
          for (var i = 0; i < 5; i++) B(c, w: 300, h: 30),
        ]),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('grid makes equal columns and stretches rows', (tester) async {
      const a = Key('a');
      const b = Key('b');
      await tester.pumpWidget(_host(SizedBox(
        width: 210,
        child: MGrid(c, cols: 2, gap: 10, children: [
          B(c, key: a, h: 30),
          B(c, key: b, child: const SizedBox(height: 10)),
        ]),
      )));
      expect(tester.getSize(find.byKey(a)), const Size(100, 30));
      expect(tester.getSize(find.byKey(b)), const Size(100, 30));
    });
  });
}
