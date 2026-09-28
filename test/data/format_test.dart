import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/format.dart';

import 'web_ref.dart';

void main() {
  test('compact (CLAUDE.md values)', () {
    expect(compact(842), '842');
    expect(compact(1234), '1.2k');
    expect(compact(12345), '12k');
    expect(compact(1234567), '1.2M');
  });

  test('compact matches web for edge values', () {
    for (final Object? row in refList('compact')) {
      final List<Object?> r = list(row);
      expect(compact(r[0]! as int), r[1], reason: '${r[0]}');
    }
  });

  test('timeAgo boundaries', () {
    expect(timeAgo(0), 'today');
    expect(timeAgo(1), '1d ago');
    expect(timeAgo(6), '6d ago');
    expect(timeAgo(7), '1w ago');
    expect(timeAgo(29), '4w ago');
    expect(timeAgo(30), '1mo ago');
    expect(timeAgo(364), '12mo ago');
    expect(timeAgo(365), '1y ago');
  });

  test('timeAgo matches web for integer days', () {
    for (final Object? row in refList('timeAgo')) {
      final List<Object?> r = list(row);
      final num days = r[0]! as num;
      if (days is int) expect(timeAgo(days), r[1], reason: '$days');
    }
  });
}
