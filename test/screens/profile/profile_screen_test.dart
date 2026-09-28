import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/screens/profile/profile_screen.dart';

import '../directory/directory_harness.dart';

void main() {
  final String sourceSlug = kSources.first.slug;

  test('profileRedirect sends known source handles to their source page', () {
    expect(profileRedirect(sourceSlug), '/source/$sourceSlug');
    expect(profileRedirect('me'), isNull);
    expect(profileRedirect('someone-else'), isNull);
  });

  for (final double width in [390, 1024]) {
    testWidgets('/u/me shows the profile hub without overflow at $width', (tester) async {
      await pumpDirectory(tester, location: '/u/me', width: width);
      expect(find.text('Your profile'), findsOneWidget);
      for (final (String label, _, String note) in kProfileLinks) {
        expect(find.text(label), findsWidgets);
        expect(find.text(note), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('link cards are two columns on tablets, one on phones', (tester) async {
    await pumpDirectory(tester, location: '/u/me', width: 1024);
    final collections = find.text('Boards, sections, private notes.');
    final settings = find.text('Plan, profile, notifications.');
    expect(tester.getTopLeft(collections).dy, tester.getTopLeft(settings).dy);

    await pumpDirectory(tester, location: '/u/me', width: 390);
    expect(tester.getTopLeft(settings).dy, greaterThan(tester.getTopLeft(collections).dy));
  });

  testWidgets('a link card navigates', (tester) async {
    final router = await pumpDirectory(tester, location: '/u/me', width: 1024);
    await tapVisible(tester, find.text('Plan, profile, notifications.'));
    expect(locationOf(router), '/pricing');
  });

  testWidgets('a source handle redirects to /source', (tester) async {
    final router = await pumpDirectory(tester, location: '/u/$sourceSlug');
    expect(locationOf(router), '/source/$sourceSlug');
    expect(find.text('source $sourceSlug'), findsOneWidget);
  });

  testWidgets('any other handle shows the same hub (web behaviour)', (tester) async {
    await pumpDirectory(tester, location: '/u/somebody');
    expect(find.text('Your profile'), findsOneWidget);
  });
}
