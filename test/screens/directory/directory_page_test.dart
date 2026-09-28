import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/screens/directory/directory_page.dart';

import 'directory_harness.dart';

void main() {
  test('directoryColumns is 1 / 2 / 3 / 4 at the sm / lg / xl breakpoints', () {
    expect(directoryColumns(390), 1);
    expect(directoryColumns(639), 1);
    expect(directoryColumns(640), 2);
    expect(directoryColumns(1023), 2);
    expect(directoryColumns(1024), 3);
    expect(directoryColumns(1280), 4);
  });

  const routes = ['/palettes', '/layouts', '/creators', '/pricing', '/upload', '/u/me', '/legal/attribution'];
  for (final double width in [360, 768, 1440]) {
    testWidgets('every directory screen lays out without overflow at $width', (tester) async {
      for (final String route in routes) {
        await pumpDirectory(tester, location: route, width: width);
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }
}
