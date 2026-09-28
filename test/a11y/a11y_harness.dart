import 'package:flutter_test/flutter_test.dart';

/// Every main route (§12), with a representative slug for the parameterised ones.
const List<String> kMainRoutes = [
  '/',
  '/explore',
  '/web',
  '/apps',
  '/components',
  '/3d',
  '/search',
  '/search?q=dark%20fintech%20dashboard',
  '/saved',
  '/palettes',
  '/layouts',
  '/creators',
  '/pricing',
  '/upload',
  '/u/me',
  '/legal/takedown',
  '/source/ledgerly',
  '/screen/s001-ledgerly-homepage',
  '/component/c0011-ledgerly-navbar',
];

/// Phone and tablet/desktop widths the audit runs at.
const List<double> kAuditWidths = [390, 1024];

/// Lets timers that fire shortly after load (Pick of the week opens after
/// 700ms on ≥768) run, then settles.
Future<void> settleTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Asserts every tappable semantics node on screen is at least 48×48 (§14)
/// using flutter_test's [androidTapTargetGuideline]. Inline links are exempt
/// (WCAG 2.5.5), as are nodes touching the screen or a scrollable's edge.
Future<void> expectTapTargets48(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
}

/// Asserts every tappable semantics node carries a label (icon-only buttons
/// included) via [labeledTapTargetGuideline].
Future<void> expectLabeledTapTargets(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}
