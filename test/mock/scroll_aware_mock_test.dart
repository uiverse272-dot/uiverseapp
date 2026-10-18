import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/mock/mock_screen.dart';
import 'package:uiverse/mock/scroll_aware_mock.dart';

/// Forces the deferral decision instead of depending on fling velocity.
class _Physics extends ClampingScrollPhysics {
  const _Physics(this.defer, {super.parent});

  final ValueNotifier<bool> defer;

  @override
  _Physics applyTo(ScrollPhysics? ancestor) => _Physics(defer, parent: buildParent(ancestor));

  @override
  bool recommendDeferredLoading(double velocity, ScrollMetrics metrics, BuildContext context) => defer.value;
}

void main() {
  testWidgets('defers the mock while scrolling fast, builds it once slowed', (tester) async {
    final defer = ValueNotifier<bool>(true);
    addTearDown(defer.dispose);
    final item = kItems.first;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
        physics: _Physics(defer),
        children: [SizedBox(width: 200, child: ScrollAwareMock(item: item))],
      ),
    ));

    expect(find.byType(MockScreen), findsNothing);
    final placeholder = tester.getSize(find.byType(ScrollAwareMock));

    await tester.pump();
    expect(find.byType(MockScreen), findsNothing, reason: 'still flinging');

    defer.value = false;
    await tester.pump();
    await tester.pump();
    expect(find.byType(MockScreen), findsOneWidget);
    expect(tester.getSize(find.byType(ScrollAwareMock)), placeholder, reason: 'no layout jump');
  });

  testWidgets('builds immediately when not scrolling', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(children: [ScrollAwareMock(item: kItems.first)]),
    ));
    expect(find.byType(MockScreen), findsOneWidget);
  });
}
