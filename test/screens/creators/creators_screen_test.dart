import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/format.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/screens/creators/creators_screen.dart';

import '../directory/directory_harness.dart';

void main() {
  final Creator first = kCreators.first;

  test('creatorWork is up to three screens from the creator source', () {
    final work = creatorWork(first);
    expect(work, isNotEmpty);
    expect(work.length, lessThanOrEqualTo(3));
    expect(work.every((i) => i.kind == Kind.screen && i.source.slug == first.source.slug), isTrue);
  });

  for (final double width in [390, 1024]) {
    testWidgets('renders creator cards without overflow at $width', (tester) async {
      await pumpDirectory(tester, location: '/creators', width: width);
      expect(find.text(first.name), findsOneWidget);
      expect(find.text(first.role), findsWidgets);
      expect(find.text('${first.screens} screens'), findsWidgets);
      expect(find.text('${compact(first.followers)} followers'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('available creators show the Available tag', (tester) async {
    expect(first.available, isTrue, reason: 'creator 0 is available (i % 4 == 0)');
    await pumpDirectory(tester, location: '/creators', width: 1024);
    expect(find.text('Available'), findsWidgets);
  });

  testWidgets('a card opens the creator source page', (tester) async {
    final router = await pumpDirectory(tester, location: '/creators', width: 1024);
    await tapVisible(tester, find.text(first.name));
    expect(locationOf(router), '/source/${first.handle}');
  });
}
