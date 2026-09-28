import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's [SharedPreferences] instance.
///
/// Loaded once in `main()` and injected with
/// `sharedPreferencesProvider.overrideWithValue(prefs)`; tests do the same after
/// `SharedPreferences.setMockInitialValues({...})`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider in ProviderScope'),
);

/// Wall clock, injectable so tests can fix "now" (month rollover, save timestamps).
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);
