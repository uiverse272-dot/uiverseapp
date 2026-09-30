/// Pure helpers behind `/search` (web `app/(app)/search/page.tsx`).
library;

import '../../data/query.dart';

/// Suggestion chips shown when there is no query.
const List<String> kSearchSuggestions = <String>[
  'dark fintech dashboard',
  'minimal saas pricing',
  'luxury ecommerce landing page',
  'ios onboarding',
  'brutalist portfolio',
  'editorial blog',
  'react tailwind hero',
];

/// A kind tab: label, `?kind=` value (`null` = All) and its result count.
typedef KindTab = ({String label, String? kind, int count});

/// All / Designs / Components with the result count of [q] for each.
///
/// Three searches, not one split by kind: the free-text residual only narrows
/// a result set it still matches, so a kind-filtered search can differ.
List<KindTab> kindTabs(String q) => <KindTab>[
      (label: 'All', kind: null, count: searchCatalog(q).results.length),
      (label: 'Designs', kind: 'screen', count: searchCatalog(q, const Filters(kind: 'screen')).results.length),
      (
        label: 'Components',
        kind: 'component',
        count: searchCatalog(q, const Filters(kind: 'component')).results.length,
      ),
    ];

/// [q] without the words that produced [term] (its slug or its label), as
/// the web does when a parse chip is removed. Synonyms (e.g. "bank" for
/// fintech) are left in place, matching the web.
String queryWithout(String q, ParsedTerm term) => q
    .split(RegExp(r'\s+'))
    .where((String w) {
      final String l = w.toLowerCase();
      return w.isNotEmpty && l != term.value && l != term.label.toLowerCase();
    })
    .join(' ');

/// Search location for [q] and optional [kind] (`/search?q=…&kind=…`).
Map<String, String> searchParams(String q, [String? kind]) => <String, String>{
      if (q.trim().isNotEmpty) 'q': q.trim(),
      'kind': ?kind,
    };
