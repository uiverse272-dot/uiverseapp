import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/state/pick.dart';
import 'package:uiverse/state/prompt_quota.dart';
import 'package:uiverse/state/theme.dart';

import 'state_harness.dart';

void main() {
  group('themeModeProvider', () {
    test('absent key = system; stored values map to modes', () async {
      var (c, _) = await makeContainer();
      expect(c.read(themeModeProvider), ThemeMode.system);
      (c, _) = await makeContainer(values: {kThemeKey: 'dark'});
      expect(c.read(themeModeProvider), ThemeMode.dark);
      (c, _) = await makeContainer(values: {kThemeKey: 'light'});
      expect(c.read(themeModeProvider), ThemeMode.light);
    });

    test('toggle flips the shown brightness and persists', () async {
      final (c, prefs) = await makeContainer();
      // System mode on a dark platform: shown = dark, so toggle goes light.
      final shown = resolveBrightness(c.read(themeModeProvider), Brightness.dark);
      await c.read(themeModeProvider.notifier).toggle(shown);
      expect(c.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString(kThemeKey), 'light');

      await c.read(themeModeProvider.notifier).toggle(Brightness.light);
      expect(c.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString(kThemeKey), 'dark');
    });
  });

  group('promptQuotaProvider', () {
    test('reads web JSON for the current month', () async {
      final (c, _) = await makeContainer(
        values: {kPromptsKey: '{"month":"2026-09","used":2}'},
        clock: () => DateTime.utc(2026, 9, 28),
      );
      final q = c.read(promptQuotaProvider);
      expect(q.used, 2);
      expect(q.remaining, 1);
      expect(q.locked, isFalse);
    });

    test('resets when the month changes', () async {
      var now = DateTime.utc(2026, 9, 30, 23);
      final (c, prefs) = await makeContainer(
        values: {kPromptsKey: '{"month":"2026-09","used":3}'},
        clock: () => now,
      );
      expect(c.read(promptQuotaProvider).locked, isTrue);

      now = DateTime.utc(2026, 10, 1, 1);
      c.read(promptQuotaProvider.notifier).refresh();
      expect(c.read(promptQuotaProvider).used, 0);

      expect(c.read(promptQuotaProvider.notifier).consume(), 1);
      expect(jsonDecode(prefs.getString(kPromptsKey)!), {'month': '2026-10', 'used': 1});
    });

    test('consume counts up to the limit; reset clears', () async {
      final (c, prefs) = await makeContainer(clock: () => DateTime.utc(2026, 1, 5));
      final n = c.read(promptQuotaProvider.notifier)
        ..consume()
        ..consume()
        ..consume();
      expect(c.read(promptQuotaProvider).remaining, 0);
      n.reset();
      expect(c.read(promptQuotaProvider).remaining, 3);
      expect(prefs.getString(kPromptsKey), isNull);
    });

    test('period is UTC YYYY-MM', () {
      expect(quotaPeriod(DateTime.utc(2026, 3, 1)), '2026-03');
    });
  });

  group('pickFoldedProvider', () {
    test('"tab" means folded; unfold removes the key', () async {
      final (c, prefs) = await makeContainer(values: {kPickKey: 'tab'});
      expect(c.read(pickFoldedProvider), isTrue);
      c.read(pickFoldedProvider.notifier).set(false);
      expect(prefs.getString(kPickKey), isNull);
      c.read(pickFoldedProvider.notifier).toggle();
      expect(prefs.getString(kPickKey), 'tab');
    });
  });
}
