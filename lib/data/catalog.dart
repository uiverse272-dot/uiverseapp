/// The seeded catalogue, ported from web `data.ts`.
///
/// Every number is derived deterministically from slugs via [rnd], so values
/// match the web app exactly (see `test/data/catalog_test.dart`).
library;

import 'package:flutter/painting.dart';

import 'models.dart';
import 'palettes.dart';
import 'rng.dart';

/* ------------------------------------------------------------------ */
/* Archetype definitions: geometry + section structure                 */
/* ------------------------------------------------------------------ */

const Map<Archetype, ArchetypeDef> kArchetypes = <Archetype, ArchetypeDef>{
  Archetype.saasLanding: ArchetypeDef(
    w: 1440, h: 3080, category: 'landing-page', device: Device.desktop,
    blocks: <Block>[
      Block('navbar', 'Navbar'),
      Block('hero', 'Hero'),
      Block('logo-cloud', 'Logo cloud'),
      Block('cards', 'Feature grid'),
      Block('stats', 'Metrics band'),
      Block('testimonials', 'Testimonial'),
      Block('cta', 'CTA'),
      Block('footer', 'Footer'),
    ],
  ),
  Archetype.dashboard: ArchetypeDef(
    w: 1440, h: 960, category: 'dashboard', device: Device.desktop,
    blocks: <Block>[
      Block('sidebar', 'Sidebar'),
      Block('navbar', 'Top bar'),
      Block('stats', 'Stat cards'),
      Block('charts', 'Chart panel'),
      Block('list', 'Activity list'),
      Block('table', 'Data table'),
    ],
  ),
  Archetype.pricing: ArchetypeDef(
    w: 1440, h: 1360, category: 'pricing', device: Device.desktop,
    blocks: <Block>[
      Block('navbar', 'Navbar'),
      Block('hero', 'Section header'),
      Block('tabs', 'Billing toggle'),
      Block('pricing', 'Pricing tiers'),
      Block('faq', 'FAQ'),
      Block('footer', 'Footer'),
    ],
  ),
  Archetype.ecommerce: ArchetypeDef(
    w: 1440, h: 2120, category: 'ecommerce', device: Device.desktop,
    blocks: <Block>[
      Block('navbar', 'Navbar + search'),
      Block('hero', 'Campaign hero'),
      Block('filters', 'Category row'),
      Block('cards', 'Product grid'),
      Block('cta', 'Editorial band'),
      Block('footer', 'Footer'),
    ],
  ),
  Archetype.portfolio: ArchetypeDef(
    w: 1440, h: 2110, category: 'portfolio', device: Device.desktop,
    blocks: <Block>[
      Block('navbar', 'Minimal nav'),
      Block('hero', 'Type statement'),
      Block('cards', 'Work grid'),
      Block('list', 'Index list'),
      Block('footer', 'Contact footer'),
    ],
  ),
  Archetype.checkout: ArchetypeDef(
    w: 1440, h: 900, category: 'checkout', device: Device.desktop,
    blocks: <Block>[
      Block('navbar', 'Slim header'),
      Block('inputs', 'Contact fields'),
      Block('checkout', 'Payment form'),
      Block('list', 'Order summary'),
      Block('cta', 'Pay button'),
    ],
  ),
  Archetype.auth: ArchetypeDef(
    w: 1440, h: 900, category: 'auth', device: Device.desktop,
    blocks: <Block>[
      Block('login', 'Sign-in card'),
      Block('inputs', 'Field group'),
      Block('cta', 'Provider buttons'),
    ],
  ),
  Archetype.editorial: ArchetypeDef(
    w: 1440, h: 1650, category: 'blog', device: Device.desktop,
    blocks: <Block>[
      Block('navbar', 'Masthead'),
      Block('hero', 'Lead story'),
      Block('list', 'Article index'),
      Block('cards', 'Related grid'),
      Block('footer', 'Footer'),
    ],
  ),
  Archetype.docs: ArchetypeDef(
    w: 1440, h: 1020, category: 'docs', device: Device.desktop,
    blocks: <Block>[
      Block('sidebar', 'Docs tree'),
      Block('breadcrumb', 'Breadcrumb'),
      Block('list', 'Prose + code'),
      Block('tabs', 'On this page'),
    ],
  ),
  Archetype.agency: ArchetypeDef(
    w: 1440, h: 2830, category: 'agency', device: Device.desktop,
    blocks: <Block>[
      Block('navbar', 'Overlay nav'),
      Block('hero', 'Full-bleed hero'),
      Block('list', 'Services list'),
      Block('cards', 'Case studies'),
      Block('cta', 'Contact band'),
    ],
  ),
  Archetype.mobileFinance: ArchetypeDef(
    w: 390, h: 844, category: 'dashboard', device: Device.mobile,
    blocks: <Block>[
      Block('navbar', 'Header'),
      Block('stats', 'Balance card'),
      Block('cards', 'Quick actions'),
      Block('list', 'Transactions'),
      Block('tabs', 'Tab bar'),
    ],
  ),
  Archetype.mobileFeed: ArchetypeDef(
    w: 390, h: 844, category: 'feed', device: Device.mobile,
    blocks: <Block>[
      Block('navbar', 'Header'),
      Block('list', 'Story rail'),
      Block('cards', 'Feed cards'),
      Block('tabs', 'Tab bar'),
    ],
  ),
  Archetype.mobileOnboarding: ArchetypeDef(
    w: 390, h: 844, category: 'onboarding', device: Device.mobile,
    blocks: <Block>[
      Block('hero', 'Illustration'),
      Block('hero', 'Headline'),
      Block('tabs', 'Progress dots'),
      Block('cta', 'Primary action'),
    ],
  ),
  Archetype.mobileProfile: ArchetypeDef(
    w: 390, h: 844, category: 'feed', device: Device.mobile,
    blocks: <Block>[
      Block('navbar', 'Header'),
      Block('stats', 'Profile stats'),
      Block('tabs', 'Segmented control'),
      Block('cards', 'Grid'),
      Block('tabs', 'Tab bar'),
    ],
  ),
};

/* ------------------------------------------------------------------ */
/* Sources — invented products, so nothing impersonates a real brand   */
/* ------------------------------------------------------------------ */

const List<Source> kSources = <Source>[
  Source(slug: 'ledgerly', name: 'Ledgerly', domain: 'ledgerly.com', industry: 'fintech', style: 'dark', tech: <String>['react', 'nextjs', 'tailwind'], palette: 'ledger', tagline: 'Money that explains itself', about: 'Business banking and spend management for operators.'),
  Source(slug: 'northwind', name: 'Northwind', domain: 'northwind.io', industry: 'saas', style: 'minimal', tech: <String>['nextjs', 'tailwind'], palette: 'paper', tagline: 'Ship the boring parts faster', about: 'Infrastructure tooling for product teams.'),
  Source(slug: 'halo-health', name: 'Halo Health', domain: 'halohealth.co', industry: 'healthcare', style: 'light', tech: <String>['react', 'tailwind'], palette: 'mint', tagline: 'Care, coordinated', about: 'Patient coordination for specialist clinics.'),
  Source(slug: 'substrate', name: 'Substrate', domain: 'substrate.ai', industry: 'ai', style: 'futuristic', tech: <String>['nextjs', 'react'], palette: 'violet', tagline: 'Models that stay in your VPC', about: 'Private model hosting and evaluation.'),
  Source(slug: 'cormorant', name: 'Cormorant', domain: 'cormorant.studio', industry: 'fashion', style: 'luxury', tech: <String>['webflow'], palette: 'noir', tagline: 'Made slowly, worn forever', about: 'A small-batch atelier in Lisbon.'),
  Source(slug: 'quarry', name: 'Quarry', domain: 'quarry.dev', industry: 'productivity', style: 'dark', tech: <String>['react', 'tailwind'], palette: 'carbon', tagline: "Your team's second brain", about: 'Docs, tasks and decisions in one place.'),
  Source(slug: 'meridian', name: 'Meridian', domain: 'meridian.travel', industry: 'travel', style: 'editorial', tech: <String>['nextjs'], palette: 'sand', tagline: 'Go further, slower', about: 'Guided long-form journeys.'),
  Source(slug: 'basil', name: 'Basil', domain: 'basil.kitchen', industry: 'food', style: 'playful', tech: <String>['shopify'], palette: 'citrus', tagline: 'Dinner, sorted', about: 'Weekly meal kits from local farms.'),
  Source(slug: 'atlas-ed', name: 'Atlas Ed', domain: 'atlased.org', industry: 'education', style: 'corporate', tech: <String>['vue', 'tailwind'], palette: 'porcelain', tagline: 'Learning that adapts', about: 'Adaptive coursework for secondary schools.'),
  Source(slug: 'tidal', name: 'Tidal', domain: 'tidal.finance', industry: 'crypto', style: 'futuristic', tech: <String>['react', 'nextjs'], palette: 'ocean', tagline: 'Liquidity without custody', about: 'Non-custodial trading infrastructure.'),
  Source(slug: 'plotline', name: 'Plotline', domain: 'plotline.so', industry: 'saas', style: 'minimal', tech: <String>['svelte', 'tailwind'], palette: 'concrete', tagline: "Analytics you'll actually read", about: 'Product analytics for small teams.'),
  Source(slug: 'rook-estate', name: 'Rook', domain: 'rook.estate', industry: 'real-estate', style: 'editorial', tech: <String>['framer'], palette: 'forest', tagline: 'Homes with a history', about: 'Period property sales and lettings.'),
  Source(slug: 'vellum', name: 'Vellum', domain: 'vellum.press', industry: 'saas', style: 'editorial', tech: <String>['nextjs'], palette: 'paper', tagline: 'Writing, published properly', about: 'A publishing platform for long-form writers.'),
  Source(slug: 'current', name: 'Current', domain: 'current.app', industry: 'fintech', style: 'dark', tech: <String>['swiftui'], palette: 'electric', tagline: 'Spend with intent', about: 'Personal finance for people who hate budgets.'),
  Source(slug: 'orchid', name: 'Orchid', domain: 'orchid.care', industry: 'healthcare', style: 'minimal', tech: <String>['flutter'], palette: 'rose', tagline: 'Therapy that fits your week', about: 'Matching and scheduling for talk therapy.'),
  Source(slug: 'kiln', name: 'Kiln', domain: 'kiln.build', industry: 'saas', style: 'brutalist', tech: <String>['react', 'tailwind'], palette: 'concrete', tagline: 'Build logs, not dashboards', about: 'CI and deployment for monorepos.'),
  Source(slug: 'saffron', name: 'Saffron', domain: 'saffron.market', industry: 'ecommerce', style: 'playful', tech: <String>['shopify'], palette: 'citrus', tagline: 'Spices with provenance', about: 'Direct-trade spice merchant.'),
  Source(slug: 'lantern', name: 'Lantern', domain: 'lantern.school', industry: 'education', style: 'light', tech: <String>['nextjs', 'tailwind'], palette: 'cloud', tagline: 'One lesson at a time', about: 'Micro-courses for working adults.'),
  Source(slug: 'pike', name: 'Pike', domain: 'pike.fitness', industry: 'healthcare', style: 'dark', tech: <String>['swiftui'], palette: 'ink', tagline: 'Train by feel', about: 'Strength training without the spreadsheet.'),
  Source(slug: 'gravel', name: 'Gravel', domain: 'gravel.cc', industry: 'travel', style: 'brutalist', tech: <String>['webflow'], palette: 'concrete', tagline: 'Roads less paved', about: 'Bikepacking routes and gear.'),
  Source(slug: 'umbra', name: 'Umbra', domain: 'umbra.design', industry: 'productivity', style: 'dark', tech: <String>['nextjs', 'react'], palette: 'carbon', tagline: 'Design systems, versioned', about: 'Token management for design teams.'),
  Source(slug: 'clearing', name: 'Clearing', domain: 'clearing.legal', industry: 'saas', style: 'corporate', tech: <String>['react'], palette: 'porcelain', tagline: 'Contracts without the chase', about: 'Contract lifecycle for in-house teams.'),
  Source(slug: 'bramble', name: 'Bramble', domain: 'bramble.garden', industry: 'ecommerce', style: 'light', tech: <String>['shopify'], palette: 'forest', tagline: 'Grow something', about: 'Seeds, tools and advice.'),
  Source(slug: 'signal-post', name: 'Signal Post', domain: 'signalpost.news', industry: 'saas', style: 'editorial', tech: <String>['nextjs'], palette: 'paper', tagline: 'The week, condensed', about: 'Independent technology journalism.'),
  Source(slug: 'nimbus', name: 'Nimbus', domain: 'nimbus.cloud', industry: 'saas', style: 'glassmorphism', tech: <String>['react', 'tailwind'], palette: 'cloud', tagline: 'Compute that scales down', about: 'Serverless infrastructure with real pricing.'),
  Source(slug: 'terrace', name: 'Terrace', domain: 'terrace.hotel', industry: 'travel', style: 'luxury', tech: <String>['framer'], palette: 'noir', tagline: 'Stay a little longer', about: 'A collection of six small hotels.'),
];

/* ------------------------------------------------------------------ */
/* Screen plan                                                         */
/* ------------------------------------------------------------------ */

typedef _Plan = (String source, Archetype archetype, String title);

const List<_Plan> _plan = <_Plan>[
  ('ledgerly', Archetype.saasLanding, 'Homepage'),
  ('ledgerly', Archetype.dashboard, 'Spend overview'),
  ('ledgerly', Archetype.pricing, 'Pricing'),
  ('ledgerly', Archetype.auth, 'Sign in'),
  ('northwind', Archetype.saasLanding, 'Homepage'),
  ('northwind', Archetype.docs, 'Documentation'),
  ('northwind', Archetype.pricing, 'Plans'),
  ('halo-health', Archetype.saasLanding, 'Homepage'),
  ('halo-health', Archetype.dashboard, 'Care schedule'),
  ('substrate', Archetype.saasLanding, 'Homepage'),
  ('substrate', Archetype.dashboard, 'Model evaluations'),
  ('substrate', Archetype.docs, 'API reference'),
  ('cormorant', Archetype.ecommerce, 'Shop all'),
  ('cormorant', Archetype.portfolio, 'Lookbook'),
  ('cormorant', Archetype.checkout, 'Checkout'),
  ('quarry', Archetype.saasLanding, 'Homepage'),
  ('quarry', Archetype.dashboard, 'Workspace'),
  ('quarry', Archetype.mobileFeed, 'Inbox'),
  ('meridian', Archetype.editorial, 'Journal'),
  ('meridian', Archetype.agency, 'Expeditions'),
  ('basil', Archetype.ecommerce, 'Weekly menu'),
  ('basil', Archetype.mobileOnboarding, 'Welcome'),
  ('basil', Archetype.checkout, 'Basket'),
  ('atlas-ed', Archetype.saasLanding, 'Homepage'),
  ('atlas-ed', Archetype.dashboard, 'Class insights'),
  ('tidal', Archetype.saasLanding, 'Homepage'),
  ('tidal', Archetype.dashboard, 'Trading desk'),
  ('tidal', Archetype.mobileFinance, 'Portfolio'),
  ('plotline', Archetype.saasLanding, 'Homepage'),
  ('plotline', Archetype.dashboard, 'Funnels'),
  ('plotline', Archetype.pricing, 'Pricing'),
  ('rook-estate', Archetype.editorial, 'Listings journal'),
  ('rook-estate', Archetype.portfolio, 'Featured homes'),
  ('vellum', Archetype.editorial, 'Reading view'),
  ('vellum', Archetype.saasLanding, 'Homepage'),
  ('current', Archetype.mobileFinance, 'Accounts'),
  ('current', Archetype.mobileOnboarding, 'Get started'),
  ('current', Archetype.mobileProfile, 'Profile'),
  ('orchid', Archetype.mobileOnboarding, 'Matching'),
  ('orchid', Archetype.saasLanding, 'Homepage'),
  ('kiln', Archetype.dashboard, 'Build log'),
  ('kiln', Archetype.saasLanding, 'Homepage'),
  ('kiln', Archetype.docs, 'CLI reference'),
  ('saffron', Archetype.ecommerce, 'Storefront'),
  ('saffron', Archetype.checkout, 'Checkout'),
  ('lantern', Archetype.saasLanding, 'Homepage'),
  ('lantern', Archetype.mobileFeed, 'Today'),
  ('lantern', Archetype.pricing, 'Membership'),
  ('pike', Archetype.mobileFinance, 'Training week'),
  ('pike', Archetype.mobileProfile, 'Athlete'),
  ('gravel', Archetype.agency, 'Routes'),
  ('gravel', Archetype.ecommerce, 'Gear'),
  ('umbra', Archetype.dashboard, 'Token library'),
  ('umbra', Archetype.saasLanding, 'Homepage'),
  ('umbra', Archetype.docs, 'Guidelines'),
  ('clearing', Archetype.saasLanding, 'Homepage'),
  ('clearing', Archetype.dashboard, 'Contract queue'),
  ('clearing', Archetype.auth, 'Log in'),
  ('bramble', Archetype.ecommerce, 'Seed shop'),
  ('bramble', Archetype.editorial, 'Grow guides'),
  ('signal-post', Archetype.editorial, 'Front page'),
  ('signal-post', Archetype.auth, 'Subscribe'),
  ('nimbus', Archetype.saasLanding, 'Homepage'),
  ('nimbus', Archetype.pricing, 'Pricing'),
  ('nimbus', Archetype.dashboard, 'Usage'),
  ('terrace', Archetype.agency, 'The hotels'),
  ('terrace', Archetype.portfolio, 'Rooms'),
  ('terrace', Archetype.checkout, 'Reserve'),
];

/// Source by slug. Throws if unknown (web uses a non-null assertion).
Source sourceOf(String slug) => kSources.firstWhere((Source s) => s.slug == slug);

/// Block types worth promoting into standalone component entries.
const Set<String> _croppable = <String>{
  'hero', 'pricing', 'navbar', 'table', 'stats', 'testimonials', 'cta',
  'footer', 'login', 'checkout', 'cards', 'sidebar', 'charts', 'filters', 'list',
};

const Set<String> _threeD = <String>{'substrate', 'tidal', 'nimbus', 'umbra'};

final RegExp _nonSlug = RegExp('[^a-z0-9]+');

/// Generates the full catalogue: each planned screen followed by the
/// component entries cropped from it (web `buildItems`).
List<Item> buildItems() {
  final List<Item> items = <Item>[];

  for (int i = 0; i < _plan.length; i++) {
    final (String srcSlug, Archetype archetype, String title) = _plan[i];
    final Source src = sourceOf(srcSlug);
    final ArchetypeDef arch = kArchetypes[archetype]!;
    final Palette pal = paletteByKey(src.palette);
    final String id = 's${'${i + 1}'.padLeft(3, '0')}';
    final String slug = '$id-$srcSlug-${title.toLowerCase().replaceAll(_nonSlug, '-')}';
    final bool mobile = arch.device == Device.mobile;
    final String style = pal.dark ? 'dark' : (src.style == 'dark' ? 'minimal' : src.style);
    final String platform = mobile ? (i % 3 == 0 ? 'android' : 'ios') : 'web';
    final Device device = mobile ? Device.mobile : Device.desktop;
    final Tier tier = i % 7 == 0 ? Tier.premium : Tier.free;
    final bool has3d = _threeD.contains(srcSlug) && archetype == Archetype.saasLanding;
    final List<Color> colors = <Color>[pal.bg, pal.surface, pal.accent, pal.text, pal.muted];

    items.add(Item(
      id: id,
      slug: slug,
      kind: Kind.screen,
      title: title,
      archetype: archetype,
      source: src,
      palette: pal,
      aspect: arch.w / arch.h,
      category: arch.category,
      industry: src.industry,
      style: style,
      platform: platform,
      device: device,
      tech: src.tech,
      blocks: arch.blocks,
      hasCode: i % 5 == 0,
      tier: tier,
      responsive: true, // every design renders at laptop, tablet and mobile
      has3d: has3d,
      saves: rnd('${slug}sv', 40, 4200),
      views: rnd('${slug}vw', 900, 92000),
      daysAgo: rnd('${slug}dt', 1, 240),
      colors: colors,
    ));

    // derive component entries from this screen's blocks
    int cIndex = 0;
    final int n = arch.blocks.length;
    for (int bi = 0; bi < n; bi++) {
      final Block b = arch.blocks[bi];
      if (!_croppable.contains(b.type)) continue;
      if ((i + bi) % 3 != 0) continue; // keep the set from exploding
      cIndex++;
      final String cid = 'c${id.substring(1)}$cIndex';
      final String cslug = '$cid-$srcSlug-${b.type}';
      items.add(Item(
        id: cid,
        slug: cslug,
        kind: Kind.component,
        title: b.label,
        archetype: archetype,
        source: src,
        palette: pal,
        aspect: mobile ? 0.9 : (b.type == 'footer' || b.type == 'navbar' ? 3.2 : 1.55),
        category: arch.category,
        industry: src.industry,
        style: style,
        platform: platform,
        device: device,
        tech: src.tech,
        componentType: b.type,
        parentSlug: slug,
        crop: Crop(y: bi / n, h: 1 / n),
        blocks: <Block>[b],
        hasCode: (i + bi) % 3 == 0,
        tier: tier,
        responsive: true,
        has3d: has3d,
        saves: rnd('${cslug}sv', 20, 2600),
        views: rnd('${cslug}vw', 400, 40000),
        daysAgo: rnd('${cslug}dt', 1, 240),
        colors: colors,
      ));
    }
  }

  return items;
}

/// The whole catalogue in generation order (web `ITEMS`). Built on first use.
final List<Item> kItems = List<Item>.unmodifiable(buildItems());

final Map<String, Item> _bySlug = <String, Item>{
  for (final Item i in kItems) i.slug: i,
};

final List<Item> _screens =
    List<Item>.unmodifiable(kItems.where((Item i) => i.kind == Kind.screen));
final List<Item> _components =
    List<Item>.unmodifiable(kItems.where((Item i) => i.kind == Kind.component));

/// Item with [slug], or null.
Item? bySlug(String slug) => _bySlug[slug];

/// All screens, in catalogue order.
List<Item> screens() => _screens;

/// All components, in catalogue order.
List<Item> components() => _components;

/* ------------------------------------------------------------------ */
/* Derived collections                                                 */
/* ------------------------------------------------------------------ */

/// One entry on the Layouts page.
class LayoutEntry {
  const LayoutEntry({
    required this.slug,
    required this.name,
    required this.sections,
    required this.example,
    required this.uses,
  });

  /// `l-<archetype>`.
  final String slug;
  final String name;
  final List<Block> sections;
  final Item example;
  final int uses;
}

/// One entry on the Palettes page.
class PaletteEntry {
  const PaletteEntry({
    required this.slug,
    required this.palette,
    required this.source,
    required this.example,
    required this.saves,
  });

  /// `p-<palette key>`.
  final String slug;
  final Palette palette;
  final Source source;
  final Item example;
  final int saves;
}

/// One entry on the Creators page.
class Creator {
  const Creator({
    required this.handle,
    required this.name,
    required this.role,
    required this.source,
    required this.screens,
    required this.followers,
    required this.available,
  });

  final String handle;
  final String name;
  final String role;
  final Source source;
  final int screens;
  final int followers;
  final bool available;
}

String _titleCase(String s) => s
    .replaceAll('-', ' ')
    .replaceAllMapped(RegExp(r'\b\w'), (Match m) => m[0]!.toUpperCase());

/// One layout per desktop archetype; the example is the *last* screen with
/// that archetype, ordered by first appearance (JS `Map` semantics).
final List<LayoutEntry> kLayouts = List<LayoutEntry>.unmodifiable(() {
  final Map<Archetype, Item> byArch = <Archetype, Item>{};
  for (final Item s in screens()) {
    if (s.device == Device.desktop) byArch[s.archetype] = s;
  }
  return byArch.values.map((Item s) => LayoutEntry(
        slug: 'l-${s.archetype.slug}',
        name: _titleCase(s.archetype.slug),
        sections: s.blocks,
        example: s,
        uses: rnd('${s.archetype.slug}use', 8, 340),
      ));
}());

/// One entry per palette in use; example is the last screen using it.
final List<PaletteEntry> kPaletteItems = List<PaletteEntry>.unmodifiable(() {
  final Map<String, Item> byKey = <String, Item>{};
  for (final Item s in screens()) {
    byKey[s.palette.key] = s;
  }
  return byKey.values.map((Item s) => PaletteEntry(
        slug: 'p-${s.palette.key}',
        palette: s.palette,
        source: s.source,
        example: s,
        saves: rnd('${s.palette.key}sv', 60, 1800),
      ));
}());

/// One creator per source (web `CREATORS`).
final List<Creator> kCreators = List<Creator>.unmodifiable(() {
  final List<Creator> out = <Creator>[];
  for (int i = 0; i < kSources.length; i++) {
    final Source s = kSources[i];
    out.add(Creator(
      handle: s.slug,
      name: s.name,
      role: i % 3 == 0 ? 'Studio' : (i % 3 == 1 ? 'Product designer' : 'Design engineer'),
      source: s,
      screens: screens().where((Item x) => x.source.slug == s.slug).length,
      followers: rnd('${s.slug}fl', 120, 24000),
      available: i % 4 == 0,
    ));
  }
  return out;
}());
