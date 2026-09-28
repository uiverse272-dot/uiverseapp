import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/screens/legal/legal_screen.dart';

import '../directory/directory_harness.dart';

void main() {
  test('legalDoc falls back to "Legal" / "Not found." like the web', () {
    expect(legalDoc('attribution').title, 'Attribution policy');
    expect(legalDoc('takedown').body, hasLength(2));
    final unknown = legalDoc('nope');
    expect(unknown.title, 'Legal');
    expect(unknown.body, ['Not found.']);
  });

  for (final double width in [390, 1024]) {
    testWidgets('attribution renders without overflow at $width', (tester) async {
      await pumpDirectory(tester, location: '/legal/attribution', width: width, height: 2000);
      expect(find.text('Attribution policy'), findsOneWidget);
      expect(find.textContaining('Every screen indexed here names its source'), findsOneWidget);
      expect(find.textContaining('Any site owner can opt out.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('paragraphs are capped at 672 wide', (tester) async {
    await pumpDirectory(tester, location: '/legal/takedown', width: 1280);
    expect(find.text('Takedown & opt-out'), findsOneWidget);
    final para = find.textContaining('Send the domain');
    expect(tester.getSize(para).width, lessThanOrEqualTo(672));
  });

  testWidgets('unknown doc shows the web fallback', (tester) async {
    await pumpDirectory(tester, location: '/legal/nope');
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Not found.'), findsOneWidget);
  });
}
