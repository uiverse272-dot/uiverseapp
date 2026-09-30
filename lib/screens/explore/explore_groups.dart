/// The Explore directory (web `app/(app)/explore/page.tsx`): groups of tiles,
/// each a filtered feed with a real URL.
library;

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/query.dart';
import '../../data/taxonomy.dart';
import '../../router/routes.dart';
import '../../widgets/feed/url_query.dart';

/// One directory tile: where it goes, its label, how many items match and
/// the item drawn as its cover (none when nothing suitable exists).
class ExploreTile {
  const ExploreTile({required this.href, required this.label, required this.count, this.cover});

  final String href;
  final String label;
  final int count;
  final Item? cover;
}

/// A titled group of tiles. [tiles] holds only tiles with a non-zero count.
class ExploreGroup {
  const ExploreGroup({required this.title, this.note, required this.tiles});

  final String title;
  final String? note;
  final List<ExploreTile> tiles;
}

/// First item of [kind] matching [pred] — a tile's cover. Component tiles
/// need a component cover (only components carry a `componentType`).
Item? _cover(bool Function(Item) pred, [Kind kind = Kind.screen]) {
  for (final Item i in kItems) {
    if (i.kind == kind && pred(i)) return i;
  }
  return null;
}

int _count(bool Function(Item) pred) => kItems.where(pred).length;

ExploreGroup _group(String title, List<ExploreTile> tiles, {String? note}) => ExploreGroup(
      title: title,
      note: note,
      tiles: <ExploreTile>[for (final ExploreTile t in tiles) if (t.count > 0) t],
    );

List<ExploreTile> _tiles(
  List<Tax> list,
  String base,
  String param,
  bool Function(Item, String) match, {
  Map<String, int>? counts,
  Kind coverKind = Kind.screen,
}) =>
    <ExploreTile>[
      for (final Tax t in list)
        ExploreTile(
          href: withQuery(base, <String, String>{param: t.slug}),
          label: t.name,
          count: counts != null ? counts[t.slug] ?? 0 : _count((Item i) => match(i, t.slug)),
          cover: _cover((Item i) => match(i, t.slug), coverKind),
        ),
    ];

/// [exploreGroups], computed once: the catalog never changes.
final List<ExploreGroup> kExploreGroups = exploreGroups();

/// The six Explore groups, empty ones removed.
List<ExploreGroup> exploreGroups() {
  final List<ExploreGroup> groups = <ExploreGroup>[
    _group(
      'By type',
      _tiles(kCategories, Routes.web, 'category', (Item i, String s) => i.category == s,
          counts: facetCounts(kItems, Facet.category)),
    ),
    _group(
      'By component',
      _tiles(
        <Tax>[for (final (String _, List<Tax> types) in componentGroups()) ...types],
        Routes.components,
        'component',
        (Item i, String s) => i.componentType == s,
        coverKind: Kind.component,
      ),
      note: 'cropped from real screens',
    ),
    _group(
      'By industry',
      _tiles(kIndustries, Routes.web, 'industry', (Item i, String s) => i.industry == s,
          counts: facetCounts(kItems, Facet.industry)),
    ),
    _group(
      'By style',
      _tiles(kStyles, Routes.web, 'style', (Item i, String s) => i.style == s,
          counts: facetCounts(kItems, Facet.style)),
    ),
    _group('By technology', _tiles(kTechnologies, Routes.web, 'tech', (Item i, String s) => i.tech.contains(s))),
    _group('By platform', _tiles(kPlatforms, Routes.apps, 'platform', (Item i, String s) => i.platform == s)),
  ];
  return <ExploreGroup>[for (final ExploreGroup g in groups) if (g.tiles.isNotEmpty) g];
}
