import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uiverse/state/prefs.dart';

/// A container backed by mock prefs seeded with [values] and a fixed-or-mutable clock.
Future<(ProviderContainer, SharedPreferences)> makeContainer({
  Map<String, Object> values = const {},
  Clock? clock,
}) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer.test(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    if (clock != null) clockProvider.overrideWithValue(clock),
  ]);
  return (container, prefs);
}
