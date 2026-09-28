import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uiverse/router/detail.dart';
import 'package:uiverse/theme/motion.dart';
import 'package:uiverse/widgets/feed/option_popover.dart';

import '../shell/app_harness.dart';
import 'a11y_harness.dart';

/// Turns the platform's "remove animations" setting on for this test.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const _NoAnimations();
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

class _NoAnimations implements AccessibilityFeatures {
  const _NoAnimations();

  @override
  bool get disableAnimations => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => false; // every other feature: off
}

/// Two frames: one to start whatever was triggered, one for it to land.
Future<void> _twoFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Future<GoRouter> _web(WidgetTester tester, double width) async =>
    (await pumpApp(tester, width: width, location: '/web')).router;

void main() {
  testWidgets('motion() returns zero when animations are disabled', (tester) async {
    late Duration on;
    late Duration off;
    await tester.pumpWidget(Builder(builder: (context) {
      on = motion(context, kSheet);
      return MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          off = motion(context, kSheet);
          return const SizedBox();
        }),
      );
    }));
    expect(on, kSheet);
    expect(off, Duration.zero);
  });

  group('with reduced motion', () {
    testWidgets('the detail overlay appears without a transition', (tester) async {
      _reduceMotion(tester);
      final router = await _web(tester, 1024);
      router.push<void>('/screen/s001-ledgerly-homepage', extra: DetailPresentation.overlay).ignore();
      await _twoFrames(tester);
      expect(find.byType(DetailOverlay), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the filter bottom sheet appears without sliding', (tester) async {
      _reduceMotion(tester);
      await _web(tester, 390);
      await tester.tap(find.text('Type'));
      await _twoFrames(tester);
      expect(find.byType(OptionSheet), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('popovers and the More menu do not fade', (tester) async {
      _reduceMotion(tester);
      await pumpApp(tester, width: 1280, location: '/web');
      await tester.tap(find.text('Type'));
      await _twoFrames(tester);
      expect(find.byType(OptionList), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('Pick of the week opens as a card without the sheet animation', (tester) async {
      _reduceMotion(tester);
      await pumpApp(tester, width: 1024);
      await tester.pump(const Duration(seconds: 1)); // auto-open delay
      await _twoFrames(tester);
      expect(find.bySemanticsLabel('Show details'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('without reduced motion the overlay does animate (control)', (tester) async {
    final router = await _web(tester, 1024);
    router.push<void>('/screen/s001-ledgerly-homepage', extra: DetailPresentation.overlay).ignore();
    await _twoFrames(tester);
    expect(tester.hasRunningAnimations, isTrue);
    await settleTimers(tester);
  });
}
