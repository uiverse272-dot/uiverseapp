import 'package:flutter/material.dart';

import '../../data/query.dart';
import '../../data/taxonomy.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/feed/filter_bar.dart';
import '../../widgets/section/section.dart';
import 'feed_filters.dart';
import 'feed_page.dart';

String _firstName(List<(List<Tax>, String?)> pairs) {
  for (final (List<Tax> list, String? slug) in pairs) {
    final String n = slug == null ? '' : taxName(list, slug);
    if (n.isNotEmpty) return n;
  }
  return '';
}

/// `/web/[...facet]` — websites feed.
class WebFeedScreen extends StatelessWidget {
  const WebFeedScreen({super.key, required this.facets, required this.query});

  final List<String> facets;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final Filters fromPath = facetToFilters(facets, <(String, List<Tax>)>[
      ('category', kCategories),
      ('industry', kIndustries),
      ('style', kStyles),
      ('tech', kTechnologies),
    ]);
    final String label = _firstName(<(List<Tax>, String?)>[
      (kCategories, fromPath.category),
      (kIndustries, fromPath.industry),
      (kStyles, fromPath.style),
      (kTechnologies, fromPath.tech),
    ]);
    return FeedPage(
      title: label.isNotEmpty ? '$label websites' : 'Websites',
      sub: 'Full pages captured from live products. Switch device to see the responsive capture of the same screen.',
      base: mergeFilters(const Filters(kind: 'screen', platform: 'web'), fromPath),
      query: query,
      defs: const <FilterDef>[
        FilterDef(param: 'category', label: 'Type', options: kCategories),
        FilterDef(param: 'industry', label: 'Industry', options: kIndustries),
        FilterDef(param: 'style', label: 'Style', options: kStyles),
        FilterDef(param: 'tech', label: 'Tech', options: kTechnologies),
        FilterDef(param: 'device', label: 'Device', options: kDeviceOptions),
      ],
    );
  }
}

/// `/apps/[...facet]` — mobile & app UI feed.
class AppsFeedScreen extends StatelessWidget {
  const AppsFeedScreen({super.key, required this.facets, required this.query});

  final List<String> facets;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final Filters fromPath = facetToFilters(facets, <(String, List<Tax>)>[
      ('platform', kPlatforms),
      ('industry', kIndustries),
      ('category', kCategories),
    ]);
    final String label = _firstName(<(List<Tax>, String?)>[
      (kPlatforms, fromPath.platform),
      (kIndustries, fromPath.industry),
    ]);
    return FeedPage(
      title: label.isNotEmpty ? '$label apps' : 'Mobile & app UI',
      sub: 'Screens from shipped mobile products. Flows — ordered runs of screens — arrive in Phase 2.',
      base: mergeFilters(const Filters(device: 'mobile', kind: 'screen'), fromPath),
      query: query,
      defs: const <FilterDef>[
        FilterDef(param: 'platform', label: 'Platform', options: kPlatforms),
        FilterDef(param: 'category', label: 'Screen', options: kCategories),
        FilterDef(param: 'industry', label: 'Category', options: kIndustries),
        FilterDef(param: 'style', label: 'Style', options: kStyles),
      ],
    );
  }
}

/// `/components/[...facet]` — component crops feed.
class ComponentsFeedScreen extends StatelessWidget {
  const ComponentsFeedScreen({super.key, required this.facets, required this.query});

  final List<String> facets;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final Filters fromPath = facetToFilters(facets, <(String, List<Tax>)>[
      ('component', kComponentTypes),
      ('style', kStyles),
      ('tech', kTechnologies),
    ]);
    final String label = _firstName(<(List<Tax>, String?)>[(kComponentTypes, fromPath.componentType)]);
    return FeedPage(
      title: label.isNotEmpty ? '$label components' : 'Components',
      sub: 'Every component here is a crop of a real screen, so you can always see where it came from and how it was used.',
      base: mergeFilters(const Filters(kind: 'component'), fromPath),
      query: query,
      defs: const <FilterDef>[
        FilterDef(param: 'component', label: 'Component', options: kComponentTypes),
        FilterDef(param: 'industry', label: 'Industry', options: kIndustries),
        FilterDef(param: 'style', label: 'Style', options: kStyles),
        FilterDef(param: 'tech', label: 'Framework', options: kTechnologies),
      ],
    );
  }
}

/// `/3d` — 3D & motion feed (items with `has3d`). No filter bar, like web;
/// [query] is accepted for route symmetry and currently unused.
class ThreeDFeedScreen extends StatelessWidget {
  const ThreeDFeedScreen({super.key, this.query = const <String, String>{}});

  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final items = filterCatalog(const Filters(threed: 'true'));
    return CustomScrollView(
      slivers: [
        const SliverShell(
          sliver: SliverToBoxAdapter(
            child: PageHeader(
              title: '3D & motion',
              sub: 'Scenes, WebGL heroes and interactive elements. Deliberately not a launch nav item — it becomes a section when the captures justify one.',
            ),
          ),
        ),
        SliverShell(
          sliver: SliverPadding(
            padding: const EdgeInsets.only(top: 24),
            sliver: Feed(items: items),
          ),
        ),
      ],
    );
  }
}
