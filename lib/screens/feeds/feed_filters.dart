/// Path-facet resolution and base/URL filter merging (web `FeedPage.tsx`).
library;

import '../../data/query.dart';
import '../../data/taxonomy.dart';

/// Facet segments (`/web/saas/dark`) resolved against taxonomies: each
/// segment sets the first dictionary's param that contains it and is still
/// unset. [dicts] are `(web param name, taxonomy)` in priority order.
Filters facetToFilters(List<String> segments, List<(String, List<Tax>)> dicts) {
  Filters f = const Filters();
  for (final String seg in segments) {
    for (final (String param, List<Tax> list) in dicts) {
      if (f.param(param) == null && list.any((Tax t) => t.slug == seg)) {
        f = f.withParam(param, seg);
        break;
      }
    }
  }
  return f;
}

/// [base] with every set [url] param laid over it.
Filters mergeFilters(Filters base, Filters url) {
  Filters out = base;
  url.toParams().forEach((String p, String v) => out = out.withParam(p, v));
  return out;
}
