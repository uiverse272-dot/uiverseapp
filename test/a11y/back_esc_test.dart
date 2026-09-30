import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uiverse/detail/detail_screen.dart';
import 'package:uiverse/router/detail.dart';
import 'package:uiverse/widgets/core/back_dismiss.dart';
import 'package:uiverse/widgets/feed/option_popover.dart';

import '../shell/app_harness.dart';
import 'a11y_harness.dart';

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Android back.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Hardware Esc.
Future<void> _esc(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

Future<GoRouter> _openOverlay(WidgetTester tester, {double width = 1024}) async {
  final app = await pumpApp(tester, width: width, location: '/web');
  app.router.push<void>('/screen/s001-ledgerly-homepage', extra: DetailPresentation.overlay).ignore();
  await tester.pumpAndSettle();
  expect(find.byType(DetailOverlay), findsOneWidget);
  return app.router;
}

void main() {
  for (final (name, dismiss) in [('back', _back), ('Esc', _esc)]) {
    group('$name closes', () {
      testWidgets('the More menu without leaving the page', (tester) async {
        final app = await pumpApp(tester, width: 1280, location: '/legal/takedown');
        await _tap(tester, find.text('More'));
        expect(find.text('Creators'), findsOneWidget);
        await dismiss(tester);
        expect(find.text('Creators'), findsNothing);
        expect(app.router.state.uri.path, '/legal/takedown');
        expect(BackDismiss.openCount, 0);
      });

      testWidgets('a filter popover (≥768)', (tester) async {
        await pumpApp(tester, width: 1024, location: '/web');
        await _tap(tester, find.text('Type'));
        expect(find.byType(OptionList), findsOneWidget);
        await dismiss(tester);
        expect(find.byType(OptionList), findsNothing);
      });

      testWidgets('a filter bottom sheet (phone)', (tester) async {
        final app = await pumpApp(tester, width: 390, location: '/web');
        await _tap(tester, find.text('Type'));
        expect(find.byType(OptionSheet), findsOneWidget);
        await dismiss(tester);
        expect(find.byType(OptionSheet), findsNothing);
        expect(app.router.state.uri.path, '/web');
      });

      testWidgets('Pick of the week details before anything else', (tester) async {
        await pumpApp(tester, width: 1024);
        await settleTimers(tester);
        await _tap(tester, find.bySemanticsLabel('Show details'));
        expect(find.bySemanticsLabel('Show less'), findsOneWidget);
        await dismiss(tester);
        expect(find.bySemanticsLabel('Show details'), findsOneWidget);
        await _drain(tester);
      });

      testWidgets('the navbar search dropdown', (tester) async {
        await pumpApp(tester, width: 1024);
        await tester.enterText(find.byType(EditableText).first, 'dark');
        await tester.pumpAndSettle();
        expect(find.textContaining('Search for'), findsOneWidget);
        await dismiss(tester);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.textContaining('Search for'), findsNothing);
      });

      testWidgets('the detail overlay', (tester) async {
        final router = await _openOverlay(tester);
        await dismiss(tester);
        expect(find.byType(DetailOverlay), findsNothing);
        expect(router.state.uri.path, '/web');
      });

      testWidgets('the prompt dialog first, then the overlay under it', (tester) async {
        await _openOverlay(tester);
        await _tap(tester, find.text('Prompt'));
        expect(find.text('Colour tokens'), findsOneWidget);
        await dismiss(tester);
        expect(find.text('Colour tokens'), findsNothing);
        expect(find.byType(DetailOverlay), findsOneWidget);
        await dismiss(tester);
        expect(find.byType(DetailOverlay), findsNothing);
      });

      testWidgets('the save toast picker first, then the overlay', (tester) async {
        await _openOverlay(tester);
        final save = find.descendant(of: find.byType(DetailScreen), matching: find.text('Save'));
        await _tap(tester, save);
        await _tap(tester, find.text('Move to…'));
        expect(find.text('Move to collection'), findsOneWidget);
        await dismiss(tester);
        expect(find.text('Move to collection'), findsNothing);
        expect(find.byType(DetailOverlay), findsOneWidget);
        await dismiss(tester);
        expect(find.byType(DetailOverlay), findsNothing);
        await _drain(tester);
      });
    });
  }

  testWidgets('nested layers close most recent first', (tester) async {
    await pumpApp(tester, width: 1280);
    await settleTimers(tester);
    await _tap(tester, find.bySemanticsLabel('Show details'));
    await _tap(tester, find.text('More'));
    expect(BackDismiss.openCount, 2);
    await _back(tester);
    expect(find.text('Creators'), findsNothing);
    expect(find.bySemanticsLabel('Show less'), findsOneWidget);
    await _back(tester);
    expect(find.bySemanticsLabel('Show details'), findsOneWidget);
    expect(BackDismiss.openCount, 0);
    await _drain(tester);
  });

  testWidgets('Esc with nothing open does not leave the page', (tester) async {
    final app = await pumpApp(tester, width: 1024, location: '/palettes');
    await _esc(tester);
    expect(app.router.state.uri.path, '/palettes');
  });
}
