/// Home category chips and the filters each one applies (web `app/(app)/page.tsx`).
library;

import '../../data/query.dart';
import '../../widgets/feed/filter_bar.dart';

/// A home chip: label, `?chip=` value (`null` = "For You") and its filters.
class HomeChip {
  const HomeChip(this.label, this.value, this.filters);

  final String label;
  final String? value;
  final Filters filters;

  ChipDef get def => ChipDef(label, value);
}

const List<HomeChip> kHomeChips = <HomeChip>[
  HomeChip('For You', null, Filters()),
  HomeChip('Trending', 'trending', Filters(sort: 'trending')),
  HomeChip('New', 'new', Filters(sort: 'new')),
  HomeChip('Web', 'web', Filters(platform: 'web', kind: 'screen')),
  HomeChip('Mobile', 'mobile', Filters(device: 'mobile')),
  HomeChip('Components', 'components', Filters(kind: 'component')),
  HomeChip('Dashboard', 'dashboard', Filters(category: 'dashboard')),
  HomeChip('SaaS', 'saas', Filters(industry: 'saas')),
  HomeChip('Fintech', 'fintech', Filters(industry: 'fintech')),
  HomeChip('E-commerce', 'ecommerce', Filters(category: 'ecommerce')),
  HomeChip('Portfolio', 'portfolio', Filters(category: 'portfolio')),
  HomeChip('Dark', 'dark', Filters(style: 'dark')),
  HomeChip('Minimal', 'minimal', Filters(style: 'minimal')),
  HomeChip('3D', '3d', Filters(threed: 'true')),
];

/// The chip for a `?chip=` value; unknown or missing → "For You".
HomeChip homeChipFor(String? value) {
  for (final HomeChip c in kHomeChips) {
    if (c.value != null && c.value == value) return c;
  }
  return kHomeChips.first;
}
