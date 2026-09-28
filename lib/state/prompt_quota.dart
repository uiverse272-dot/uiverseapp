import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs.dart';

/// localStorage key shared with the web app (§15).
const String kPromptsKey = 'uiv.prompts.v1';

/// Free plan: generated prompts per month. Discovery is never metered.
const int kFreePromptLimit = 3;

/// `YYYY-MM` in UTC — matches the web's `toISOString().slice(0, 7)`.
String quotaPeriod(DateTime now) {
  final u = now.toUtc();
  return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}';
}

@immutable
class PromptQuota {
  const PromptQuota({required this.used, this.limit = kFreePromptLimit});

  /// Prompts used in the current month.
  final int used;
  final int limit;

  int get remaining => (limit - used).clamp(0, limit);
  bool get locked => remaining == 0;

  @override
  bool operator ==(Object other) =>
      other is PromptQuota && other.used == used && other.limit == limit;

  @override
  int get hashCode => Object.hash(used, limit);
}

final promptQuotaProvider =
    NotifierProvider<PromptQuotaNotifier, PromptQuota>(PromptQuotaNotifier.new);

class PromptQuotaNotifier extends Notifier<PromptQuota> {
  @override
  PromptQuota build() => PromptQuota(used: _readUsed(ref.watch(sharedPreferencesProvider)));

  String _period() => quotaPeriod(ref.read(clockProvider)());

  int _readUsed(SharedPreferences prefs) {
    final raw = prefs.getString(kPromptsKey);
    if (raw == null) return 0;
    try {
      final p = jsonDecode(raw);
      if (p is Map<String, Object?> && p['month'] == _period()) {
        return (p['used'] as num?)?.toInt() ?? 0;
      }
    } on Object catch (e) {
      debugPrint('uiv.prompts.v1: could not parse ($e); treating as unused');
    }
    return 0;
  }

  /// Re-reads storage against the current month (call after a month may have rolled).
  void refresh() => state = PromptQuota(used: _readUsed(ref.read(sharedPreferencesProvider)));

  /// Records one generated prompt and returns the new used count for this month.
  int consume() {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = _readUsed(prefs) + 1;
    prefs
        .setString(kPromptsKey, jsonEncode({'month': _period(), 'used': next}))
        .ignore();
    state = PromptQuota(used: next);
    return next;
  }

  /// Clears the counter (the "Reset counter (demo only)" link).
  void reset() {
    ref.read(sharedPreferencesProvider).remove(kPromptsKey).ignore();
    state = const PromptQuota(used: 0);
  }
}
