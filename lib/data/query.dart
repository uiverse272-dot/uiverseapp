/// Filtering, sorting and natural-language search, ported from web `query.ts`.
library;

import 'catalog.dart';
import 'models.dart';
import 'taxonomy.dart';

bool _set(String? v) => v != null && v.isNotEmpty;

/// Browse filters. Every field mirrors a URL query param (see [kFilterParams]);
/// `null` or `''` means "not set". Values are web strings (`kind: 'screen'`,
/// `code: 'true'`, `tier: 'premium'` ...).
class Filters {
  const Filters({
    this.kind,
    this.q,
    this.category,
    this.componentType,
    this.industry,
    this.style,
    this.tech,
    this.platform,
    this.device,
    this.code,
    this.tier,
    this.responsive,
    this.threed,
    this.source,
    this.sort,
  });

  /// From URL-style params (web `filtersFromParams`). Uses the web param
  /// names: `component` for [componentType], `3d` for [threed]. Empty values
  /// are dropped; unknown keys are ignored.
  factory Filters.fromParams(Map<String, String> params) {
    Filters f = const Filters();
    for (final String p in kFilterParams) {
      final String? v = params[p];
      if (_set(v)) f = f.withParam(p, v);
    }
    return f;
  }

  final String? kind;
  final String? q;
  final String? category;
  final String? componentType;
  final String? industry;
  final String? style;
  final String? tech;
  final String? platform;
  final String? device;
  final String? code;
  final String? tier;
  final String? responsive;
  final String? threed;
  final String? source;
  final String? sort;

  /// Value for web param name [p] (e.g. `component`, `3d`); null if unset
  /// or unknown.
  String? param(String p) {
    final String? v = switch (p) {
      'kind' => kind,
      'q' => q,
      'category' => category,
      'component' => componentType,
      'industry' => industry,
      'style' => style,
      'tech' => tech,
      'platform' => platform,
      'device' => device,
      'code' => code,
      'tier' => tier,
      'responsive' => responsive,
      '3d' => threed,
      'source' => source,
      'sort' => sort,
      _ => null,
    };
    return _set(v) ? v : null;
  }

  /// Copy with web param [p] set to [value]; `null`/`''` clears it.
  /// Unknown params return this unchanged.
  Filters withParam(String p, String? value) {
    final Map<String, String> m = toParams();
    if (!kFilterParams.contains(p)) return this;
    if (_set(value)) {
      m[p] = value!;
    } else {
      m.remove(p);
    }
    return Filters(
      kind: m['kind'],
      q: m['q'],
      category: m['category'],
      componentType: m['component'],
      industry: m['industry'],
      style: m['style'],
      tech: m['tech'],
      platform: m['platform'],
      device: m['device'],
      code: m['code'],
      tier: m['tier'],
      responsive: m['responsive'],
      threed: m['3d'],
      source: m['source'],
      sort: m['sort'],
    );
  }

  /// Copy with the given fields replaced. A `null` argument keeps the current
  /// value — use [withParam] (or pass `''`) to clear a field.
  Filters copyWith({
    String? kind,
    String? q,
    String? category,
    String? componentType,
    String? industry,
    String? style,
    String? tech,
    String? platform,
    String? device,
    String? code,
    String? tier,
    String? responsive,
    String? threed,
    String? source,
    String? sort,
  }) {
    String? pick(String? next, String? cur) => next == null ? cur : (next.isEmpty ? null : next);
    return Filters(
      kind: pick(kind, this.kind),
      q: pick(q, this.q),
      category: pick(category, this.category),
      componentType: pick(componentType, this.componentType),
      industry: pick(industry, this.industry),
      style: pick(style, this.style),
      tech: pick(tech, this.tech),
      platform: pick(platform, this.platform),
      device: pick(device, this.device),
      code: pick(code, this.code),
      tier: pick(tier, this.tier),
      responsive: pick(responsive, this.responsive),
      threed: pick(threed, this.threed),
      source: pick(source, this.source),
      sort: pick(sort, this.sort),
    );
  }

  /// Set params only, keyed by web param name, in [kFilterParams] order.
  Map<String, String> toParams() => <String, String>{
        for (final String p in kFilterParams)
          if (param(p) != null) p: param(p)!,
      };

  /// True when no field is set (including `kind`, `q` and `sort`).
  bool get isEmpty => toParams().isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) {
    if (other is! Filters) return false;
    final Map<String, String> a = toParams();
    final Map<String, String> b = other.toParams();
    return a.length == b.length && a.entries.every((MapEntry<String, String> e) => b[e.key] == e.value);
  }

  @override
  int get hashCode => Object.hashAll(toParams().entries.map((MapEntry<String, String> e) => '${e.key}=${e.value}'));

  @override
  String toString() => 'Filters(${toParams()})';
}

/// Web URL param names understood by [Filters], in canonical order.
const List<String> kFilterParams = <String>[
  'kind', 'q', 'category', 'component', 'industry', 'style', 'tech', 'platform',
  'device', 'code', 'tier', 'responsive', '3d', 'source', 'sort',
];

final RegExp _ws = RegExp(r'\s+');

List<String> _words(String s) => s.split(_ws).where((String w) => w.isNotEmpty).toList();

String _textOf(Item i) => <String>[
      i.title,
      i.source.name,
      i.source.tagline,
      i.category,
      i.industry,
      i.style,
      i.componentType ?? '',
      ...i.tech,
    ].join(' ').toLowerCase();

/// Stable sort (JS `Array.prototype.sort` is stable; Dart's `List.sort` is not).
List<T> _stableSorted<T>(List<T> items, int Function(T a, T b) cmp) {
  final List<int> idx = List<int>.generate(items.length, (int i) => i);
  idx.sort((int x, int y) {
    final int c = cmp(items[x], items[y]);
    return c != 0 ? c : x - y;
  });
  return <T>[for (final int i in idx) items[i]];
}

int _sign(num d) => d < 0 ? -1 : (d > 0 ? 1 : 0);

/// Filter then sort [items] by [f] (web `applyFilters`).
List<Item> applyFilters(List<Item> items, Filters f) {
  Iterable<Item> out = items;
  if (_set(f.kind)) out = out.where((Item i) => i.kind.name == f.kind);
  if (_set(f.category)) out = out.where((Item i) => i.category == f.category);
  if (_set(f.componentType)) out = out.where((Item i) => i.componentType == f.componentType);
  if (_set(f.industry)) out = out.where((Item i) => i.industry == f.industry);
  if (_set(f.style)) out = out.where((Item i) => i.style == f.style);
  if (_set(f.tech)) out = out.where((Item i) => i.tech.contains(f.tech));
  if (_set(f.platform)) out = out.where((Item i) => i.platform == f.platform);
  if (_set(f.device)) out = out.where((Item i) => i.device.name == f.device);
  if (_set(f.source)) out = out.where((Item i) => i.source.slug == f.source);
  if (f.code == 'true') out = out.where((Item i) => i.hasCode);
  if (_set(f.tier)) out = out.where((Item i) => i.tier.name == f.tier);
  if (f.responsive == 'true') out = out.where((Item i) => i.responsive);
  if (f.threed == 'true') out = out.where((Item i) => i.has3d);
  if (_set(f.q)) {
    final List<String> terms = _words(f.q!.toLowerCase());
    out = out.where((Item i) {
      final String t = _textOf(i);
      return terms.every(t.contains);
    });
  }
  return sortItems(out.toList(), f.sort);
}

/// Sorted copy. [sort] is a [kSorts] slug; anything else means `trending`
/// (saves weighted by recency).
List<Item> sortItems(List<Item> items, [String? sort]) {
  switch (sort) {
    case 'new':
      return _stableSorted(items, (Item a, Item b) => a.daysAgo - b.daysAgo);
    case 'saved':
      return _stableSorted(items, (Item a, Item b) => b.saves - a.saves);
    case 'views':
      return _stableSorted(items, (Item a, Item b) => b.views - a.views);
    default:
      return _stableSorted(
        items,
        (Item a, Item b) => _sign(b.saves / (b.daysAgo + 12) - a.saves / (a.daysAgo + 12)),
      );
  }
}

/* ------------------------------------------------------------------ */
/* Natural-language query parsing                                      */
/* ------------------------------------------------------------------ */

/// A recognised query token, shown back to the user as a chip.
class ParsedTerm {
  const ParsedTerm({
    required this.dimension,
    required this.label,
    required this.param,
    required this.value,
  });

  /// `Type`, `Component`, `Industry`, `Style`, `Tech` or `Platform`.
  final String dimension;
  final String label;

  /// Web filter param name (`category`, `component`, ...).
  final String param;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is ParsedTerm &&
      other.dimension == dimension &&
      other.label == label &&
      other.param == param &&
      other.value == value;

  @override
  int get hashCode => Object.hash(dimension, label, param, value);

  @override
  String toString() => '$dimension:$value';
}

class ParsedQuery {
  const ParsedQuery(this.terms, this.residual);
  final List<ParsedTerm> terms;

  /// Unrecognised tokens, lowercased, joined by single spaces.
  final String residual;
}

class SearchResult {
  const SearchResult(this.results, this.terms, this.residual);
  final List<Item> results;
  final List<ParsedTerm> terms;
  final String residual;
}

const Map<String, String> kSynonyms = <String, String>{
  'landing': 'landing-page', 'homepage': 'landing-page', 'marketing': 'landing-page',
  'admin': 'dashboard', 'analytics': 'dashboard', 'console': 'dashboard',
  'shop': 'ecommerce', 'store': 'ecommerce', 'commerce': 'ecommerce',
  'signin': 'auth', 'login': 'auth', 'log-in': 'auth', 'signup': 'auth',
  'bank': 'fintech', 'banking': 'fintech', 'finance': 'fintech', 'payments': 'fintech',
  'ml': 'ai', 'machine-learning': 'ai', 'llm': 'ai',
  'medical': 'healthcare', 'health': 'healthcare', 'clinic': 'healthcare',
  'web3': 'crypto', 'blockchain': 'crypto', 'defi': 'crypto',
  'clean': 'minimal', 'simple': 'minimal', 'spare': 'minimal',
  'moody': 'dark', 'night': 'dark',
  'premium': 'luxury', 'elegant': 'luxury', 'refined': 'luxury',
  'bold': 'brutalist', 'raw': 'brutalist',
  'futurist': 'futuristic', 'sci': 'futuristic', 'neon': 'futuristic',
  'glass': 'glassmorphism', 'frosted': 'glassmorphism',
  'fun': 'playful', 'bright': 'playful',
  'next': 'nextjs', 'next.js': 'nextjs', 'tailwindcss': 'tailwind',
  'iphone': 'ios', 'apple': 'ios', 'mobile': 'ios',
  'nav': 'navbar', 'navigation': 'navbar', 'header': 'navbar',
  'cta': 'cta', 'faq': 'faq', 'testimonial': 'testimonials',
  'price': 'pricing', 'plans': 'pricing', 'tiers': 'pricing',
};

const List<(List<Tax> list, String dimension, String param)> _dicts =
    <(List<Tax>, String, String)>[
  (kCategories, 'Type', 'category'),
  (kComponentTypes, 'Component', 'component'),
  (kIndustries, 'Industry', 'industry'),
  (kStyles, 'Style', 'style'),
  (kTechnologies, 'Tech', 'tech'),
  (kPlatforms, 'Platform', 'platform'),
];

/// Dictionary-first parse: each token maps (via [kSynonyms]) to at most one
/// taxonomy term, one term per dimension, first match wins.
ParsedQuery parseQuery(String q) {
  final String raw = q.toLowerCase().trim();
  if (raw.isEmpty) return const ParsedQuery(<ParsedTerm>[], '');
  final List<String> tokens = raw.split(_ws);
  final List<ParsedTerm> terms = <ParsedTerm>[];
  final Set<int> used = <int>{};
  final Set<String> taken = <String>{};

  for (int idx = 0; idx < tokens.length; idx++) {
    final String tok = tokens[idx];
    final String norm = kSynonyms[tok] ?? tok;
    for (final (List<Tax> list, String dimension, String param) in _dicts) {
      if (taken.contains(param)) continue;
      final Tax? hit = list.where((Tax t) => t.slug == norm || t.name.toLowerCase() == norm).firstOrNull;
      if (hit != null) {
        terms.add(ParsedTerm(dimension: dimension, label: hit.name, param: param, value: hit.slug));
        used.add(idx);
        taken.add(param);
        break;
      }
    }
  }

  final String residual = <String>[
    for (int i = 0; i < tokens.length; i++)
      if (!used.contains(i)) tokens[i],
  ].join(' ');
  return ParsedQuery(terms, residual);
}

/// Parsed terms become filters (unless [extra] already sets that field); the
/// residual narrows results only when it leaves at least one match.
SearchResult searchItems(String q, [Filters extra = const Filters()]) {
  final ParsedQuery parsed = parseQuery(q);
  Filters f = extra;
  for (final ParsedTerm t in parsed.terms) {
    if (f.param(t.param) == null) f = f.withParam(t.param, t.value);
  }
  List<Item> results = applyFilters(kItems, f.withParam('q', null));
  if (parsed.residual.isNotEmpty) {
    final List<String> rt = _words(parsed.residual);
    final List<Item> narrowed =
        results.where((Item i) => rt.every(_textOf(i).contains)).toList();
    // residual is a recall booster, not a hard gate
    if (narrowed.isNotEmpty) results = narrowed;
  }
  return SearchResult(sortItems(results, extra.sort), parsed.terms, parsed.residual);
}

enum Facet { industry, style, category }

/// Count of items per value of [key], in first-seen order.
Map<String, int> facetCounts(List<Item> items, Facet key) {
  final Map<String, int> m = <String, int>{};
  for (final Item i in items) {
    final String v = switch (key) {
      Facet.industry => i.industry,
      Facet.style => i.style,
      Facet.category => i.category,
    };
    m[v] = (m[v] ?? 0) + 1;
  }
  return m;
}

/// The [n] catalogue items most similar to [item] (excluding itself).
List<Item> similarTo(Item item, [int n = 8]) {
  final List<(Item, int)> scored = <(Item, int)>[
    for (final Item i in kItems)
      if (i.slug != item.slug) (i, _similarity(i, item)),
  ];
  final List<(Item, int)> sorted =
      _stableSorted(scored, ((Item, int) a, (Item, int) b) => b.$2 - a.$2);
  return <Item>[for (final (Item, int) x in sorted.take(n)) x.$1];
}

int _similarity(Item i, Item item) {
  int score = 0;
  if (i.kind == item.kind) score += 2;
  if (i.industry == item.industry) score += 3;
  if (i.style == item.style) score += 3;
  if (i.category == item.category) score += 2;
  if (i.palette.key == item.palette.key) score += 2;
  if (i.source.slug == item.source.slug) score += 1;
  score += i.tech.where(item.tech.contains).length;
  return score;
}

/// Home feed: non-components in order, with one component injected after
/// every [every] of them; leftover components go at the end.
List<Item> mixFeed(List<Item> items, {int every = 4}) {
  final List<Item> nonComps = items.where((Item i) => i.kind != Kind.component).toList();
  final List<Item> comps = items.where((Item i) => i.kind == Kind.component).toList();
  final List<Item> out = <Item>[];
  int c = 0;
  for (int i = 0; i < nonComps.length; i++) {
    out.add(nonComps[i]);
    if ((i + 1) % every == 0 && c < comps.length) out.add(comps[c++]);
  }
  return out..addAll(comps.skip(c));
}
