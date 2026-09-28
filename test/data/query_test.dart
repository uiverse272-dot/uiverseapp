import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/data/query.dart';

import 'web_ref.dart';

List<String> slugs(List<Item> items) => items.map((Item i) => i.slug).toList();

/// Web `Filters` object (TS field names) → [Filters].
Filters fromWeb(Object? o) {
  const Map<String, String> rename = <String, String>{'componentType': 'component', 'threed': '3d'};
  return Filters.fromParams(<String, String>{
    for (final MapEntry<String, Object?> e in obj(o).entries) rename[e.key] ?? e.key: e.value! as String,
  });
}

void main() {
  group('parseQuery', () {
    test('dark fintech dashboard (CLAUDE.md)', () {
      final ParsedQuery p = parseQuery('dark fintech dashboard');
      expect(p.terms.map((ParsedTerm t) => '${t.dimension}:${t.param}:${t.value}:${t.label}'), <String>[
        'Style:style:dark:Dark',
        'Industry:industry:fintech:Fintech',
        'Type:category:dashboard:Dashboard',
      ]);
      expect(p.residual, '');
    });

    test('matches web for all reference queries', () {
      for (final Object? row in refList('parse')) {
        final Map<String, Object?> r = obj(row);
        final ParsedQuery p = parseQuery(r['q']! as String);
        final List<ParsedTerm> expected = <ParsedTerm>[
          for (final Object? t in list(r['terms']))
            ParsedTerm(
              dimension: obj(t)['dimension']! as String,
              label: obj(t)['label']! as String,
              param: obj(t)['param']! as String,
              value: obj(t)['value']! as String,
            ),
        ];
        expect(p.terms, expected, reason: '${r['q']}');
        expect(p.residual, r['residual'], reason: '${r['q']}');
      }
    });
  });

  group('searchItems', () {
    test('dark fintech dashboard (CLAUDE.md)', () {
      expect(slugs(searchItems('dark fintech dashboard').results), <String>[
        's002-ledgerly-spend-overview',
        's036-current-accounts',
        'c0361-current-stats',
        'c0021-ledgerly-stats',
        'c0022-ledgerly-table',
      ]);
    });

    test('matches web for queries × extras', () {
      for (final Object? row in refList('search')) {
        final Map<String, Object?> r = obj(row);
        final SearchResult s = searchItems(r['q']! as String, fromWeb(r['extra']));
        final String at = '"${r['q']}" ${r['extra']}';
        expect(slugs(s.results), strings(r['results']), reason: at);
        expect(s.residual, r['residual'], reason: at);
        expect(s.terms.length, list(r['terms']).length, reason: at);
      }
    });
  });

  test('applyFilters matches web', () {
    for (final Object? row in refList('filters')) {
      final Map<String, Object?> r = obj(row);
      expect(slugs(applyFilters(kItems, fromWeb(r['f']))), strings(r['results']), reason: '${r['f']}');
    }
  });

  test('sortItems matches web (stable) for every sort', () {
    final Map<String, Object?> ref = obj(webRef['sorts']);
    for (final String sort in ref.keys) {
      expect(slugs(sortItems(kItems, sort)), strings(ref[sort]), reason: sort);
    }
    expect(slugs(sortItems(kItems)), strings(ref['trending']));
    expect(slugs(sortItems(kItems, 'bogus')), strings(ref['trending']));
  });

  test('facetCounts matches web', () {
    for (final Object? row in refList('facets')) {
      final Map<String, Object?> r = obj(row);
      final Map<String, int> m = facetCounts(kItems, Facet.values.byName(r['key']! as String));
      final List<Object?> entries = list(r['entries']);
      expect(m.keys.toList(), <Object?>[for (final Object? e in entries) list(e)[0]]);
      expect(m.values.toList(), <Object?>[for (final Object? e in entries) list(e)[1]]);
    }
  });

  test('similarTo matches web', () {
    for (final Object? row in refList('similar')) {
      final Map<String, Object?> r = obj(row);
      final Item item = bySlug(r['slug']! as String)!;
      expect(slugs(similarTo(item)), strings(r['n8']));
      expect(slugs(similarTo(item, 12)), strings(r['n12']));
    }
  });

  group('mixFeed', () {
    test('matches web', () {
      expect(slugs(mixFeed(applyFilters(kItems, const Filters()))), strings(webRef['mix4']));
      expect(
        slugs(mixFeed(applyFilters(kItems, const Filters(industry: 'saas')), every: 3)),
        strings(webRef['mix3']),
      );
    });

    test('injects one component after every N screens, rest at the end', () {
      final List<Item> s = screens().take(6).toList();
      final List<Item> c = components().take(3).toList();
      final List<Item> out = mixFeed(<Item>[...c, ...s], every: 2);
      expect(slugs(out), <String>[
        s[0].slug, s[1].slug, c[0].slug,
        s[2].slug, s[3].slug, c[1].slug,
        s[4].slug, s[5].slug, c[2].slug,
      ]);
      final List<Item> fewScreens = mixFeed(<Item>[s[0], ...c], every: 4);
      expect(slugs(fewScreens), <String>[s[0].slug, ...slugs(c)]);
    });
  });

  group('Filters', () {
    test('params round-trip with web names', () {
      const Map<String, String> params = <String, String>{
        'kind': 'screen', 'component': 'navbar', '3d': 'true', 'sort': 'new', 'q': 'dark',
      };
      final Filters f = Filters.fromParams(<String, String>{...params, 'industry': '', 'junk': 'x'});
      expect(f.componentType, 'navbar');
      expect(f.threed, 'true');
      expect(f.industry, isNull);
      expect(f.toParams(), <String, String>{
        'kind': 'screen', 'q': 'dark', 'component': 'navbar', '3d': 'true', 'sort': 'new',
      });
      expect(Filters.fromParams(f.toParams()), f);
      expect(Filters.fromParams(f.toParams()).hashCode, f.hashCode);
    });

    test('isEmpty, copyWith, withParam', () {
      expect(const Filters().isEmpty, isTrue);
      expect(const Filters(style: '').isEmpty, isTrue);
      final Filters f = const Filters().copyWith(style: 'dark', tier: 'premium');
      expect(f.isEmpty, isFalse);
      expect(f.copyWith(kind: 'screen').style, 'dark');
      expect(f.copyWith(style: '').style, isNull);
      expect(f.withParam('style', null).toParams(), <String, String>{'tier': 'premium'});
      expect(f.withParam('3d', 'true').threed, 'true');
      expect(f.withParam('nope', 'x'), f);
      expect(f.param('style'), 'dark');
      expect(f.param('component'), isNull);
    });
  });
}
