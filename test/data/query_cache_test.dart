import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/query.dart';

void main() {
  test('filterCatalog returns the same list for equal filters and matches applyFilters', () {
    const a = Filters(style: 'dark', category: 'dashboard');
    const b = Filters(style: 'dark', category: 'dashboard');
    final first = filterCatalog(a);
    expect(identical(first, filterCatalog(b)), isTrue);
    expect([for (final i in first) i.slug], [for (final i in applyFilters(kItems, a)) i.slug]);
  });

  test('searchCatalog caches per query and extra filters', () {
    final all = searchCatalog('dark fintech dashboard');
    expect(identical(all, searchCatalog('dark fintech dashboard')), isTrue);
    expect(all.results.length, 5);
    final designs = searchCatalog('dark fintech dashboard', const Filters(kind: 'screen'));
    expect(identical(all, designs), isFalse);
    expect(designs.results.length, 2);
  });

  test('the cache stays bounded', () {
    for (var i = 0; i < 200; i++) {
      filterCatalog(Filters(q: 'q$i'));
    }
    // Still correct after evictions.
    expect(filterCatalog(const Filters(kind: 'screen')).length, 68);
  });
}
