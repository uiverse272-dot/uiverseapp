import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/mock/mock_screen.dart';
import 'package:uiverse/widgets/feed/feed.dart';
import 'package:uiverse/widgets/feed/feed_card.dart';

import 'themed_harness.dart';

void main() {
  testWidgets('a rebuilt FeedCard keeps the same MockScreen instance', (tester) async {
    final item = kItems.first;
    late StateSetter rebuild;
    await pumpThemed(
      tester,
      StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return SingleChildScrollView(child: FeedCard(item, crop: 3 / 4));
      }),
    );
    final before = tester.widget<MockScreen>(find.byType(MockScreen));
    rebuild(() {});
    await tester.pump();
    expect(identical(tester.widget<MockScreen>(find.byType(MockScreen)), before), isTrue);
  });

  testWidgets('appending items keeps the mocks of cards already shown', (tester) async {
    var items = kItems.take(2).toList();
    late StateSetter rebuild;
    await pumpThemed(
      tester,
      StatefulBuilder(builder: (context, setState) {
        rebuild = setState;
        return CustomScrollView(slivers: [Feed(items: items)]);
      }),
    );
    final before = tester.widget<MockScreen>(find.byType(MockScreen).first);
    rebuild(() => items = kItems.take(4).toList());
    await tester.pumpAndSettle();
    expect(identical(tester.widget<MockScreen>(find.byType(MockScreen).first), before), isTrue);
  });
}
