import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/query.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/feed/filter_bar.dart';
import '../../widgets/feed/url_query.dart';
import '../../widgets/section/section.dart';
import 'feed_filters.dart';

/// Generic feed page (§12 "Feed page"): PageHeader with the result count,
/// a pinned [FilterBar], then the [Feed]. [base] filters come from the route
/// (kind, facets); [query] (the URL) is laid over them and drives the bar.
class FeedPage extends StatelessWidget {
  const FeedPage({
    super.key,
    required this.title,
    this.sub,
    required this.base,
    required this.defs,
    required this.query,
  });

  final String title;
  final String? sub;
  final Filters base;
  final List<FilterDef> defs;
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final Filters url = Filters.fromParams(query);
    final List<Item> items = filterCatalog(mergeFilters(base, url));
    return CustomScrollView(
      slivers: [
        SliverShell(
          sliver: SliverToBoxAdapter(
            child: PageHeader(
              title: title,
              sub: sub,
              trailing: Text(
                '${items.length} results',
                style: UiText.body.copyWith(color: c.text3, fontFeatures: UiText.tabular),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        StickyBar(
          child: FilterBar(
            defs: defs,
            value: url,
            onChanged: (f) => goWithQuery(context, f.toParams()),
          ),
        ),
        SliverShell(
          sliver: SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: Feed(items: items),
          ),
        ),
      ],
    );
  }
}
