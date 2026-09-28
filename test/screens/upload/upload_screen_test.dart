import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/screens/upload/upload_screen.dart';

import '../directory/directory_harness.dart';

void main() {
  for (final double width in [390, 1024]) {
    testWidgets('upload form renders without overflow at $width', (tester) async {
      await pumpDirectory(tester, location: '/upload', width: width, height: 2000);
      expect(find.text('Submit a design'), findsOneWidget);
      expect(find.text('Site or app URL'), findsOneWidget);
      expect(find.text('https://'), findsOneWidget);
      expect(find.text('or drop an image'), findsOneWidget);
      expect(find.text('Drop a PNG, JPG or MP4'), findsOneWidget);
      expect(find.text('Suggested metadata'), findsOneWidget);
      expect(find.text('Components found'), findsOneWidget);
      expect(find.text('Attribution'), findsOneWidget);
      expect(find.bySemanticsLabel('Submit for review'), findsOneWidget);
      expect(find.text('Usually reviewed within 24 hours.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('metadata label sits beside its chips on wide screens', (tester) async {
    await pumpDirectory(tester, location: '/upload', width: 1024, height: 2000);
    expect(
      tester.getTopLeft(find.text('Industry')).dy,
      closeTo(tester.getTopLeft(find.text('Fintech')).dy, 8),
    );
  });

  testWidgets('metadata label stacks above its chips on phones', (tester) async {
    await pumpDirectory(tester, location: '/upload', width: 390, height: 2000);
    expect(
      tester.getTopLeft(find.text('Fintech')).dy,
      greaterThan(tester.getTopLeft(find.text('Industry')).dy + 10),
    );
  });

  testWidgets('tapping a chip removes it', (tester) async {
    await pumpDirectory(tester, location: '/upload', width: 390, height: 2000);
    expect(find.text('Logo cloud'), findsOneWidget);
    await tapVisible(tester, find.bySemanticsLabel('Remove Logo cloud'));
    expect(find.text('Logo cloud'), findsNothing);
    expect(find.text('Navbar'), findsOneWidget);
  });

  testWidgets('submit shows a local confirmation; Submit another resets', (tester) async {
    await pumpDirectory(tester, location: '/upload', width: 390, height: 2000);
    await tester.enterText(find.descendant(of: find.byType(UploadScreen), matching: find.byType(EditableText)), 'https://example.test');
    await tapVisible(tester, find.bySemanticsLabel('Remove SaaS'));
    await tapVisible(tester, find.bySemanticsLabel('Submit for review'));
    expect(find.text('Submitted for review'), findsOneWidget);
    expect(find.textContaining('https://example.test is in the queue.'), findsOneWidget);
    expect(find.text('Suggested metadata'), findsNothing);

    await tapVisible(tester, find.text('Submit another'));
    expect(find.text('Suggested metadata'), findsOneWidget);
    expect(find.text('SaaS'), findsOneWidget);
    expect(find.text('https://example.test'), findsNothing);
  });
}
