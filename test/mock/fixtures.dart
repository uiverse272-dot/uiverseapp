import 'dart:ui';

import 'package:uiverse/data/models.dart';

/// Hand-written fixtures for the mock renderer tests — independent of the
/// real catalog in `lib/data`. Palettes copied from web `src/lib/palettes.ts`.

const carbon = Palette(
  key: 'carbon',
  name: 'Carbon',
  bg: Color(0xFF0B0D10),
  surface: Color(0xFF131720),
  raised: Color(0xFF1B212C),
  text: Color(0xFFF2F5F8),
  muted: Color(0xFF8A94A6),
  accent: Color(0xFF5B8CFF),
  accentFg: Color(0xFF04070D),
  border: Color(0xFF222835),
  chart: [Color(0xFF5B8CFF), Color(0xFF3EC9A7), Color(0xFFF5B544), Color(0xFFFF6B6B)],
  dark: true,
);

const paper = Palette(
  key: 'paper',
  name: 'Paper',
  bg: Color(0xFFFFFFFF),
  surface: Color(0xFFFAFAF9),
  raised: Color(0xFFF4F4F2),
  text: Color(0xFF14110E),
  muted: Color(0xFF7A736B),
  accent: Color(0xFF14110E),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFE7E5E1),
  chart: [Color(0xFF14110E), Color(0xFFA8A29A), Color(0xFFD6D2CB), Color(0xFF8C7D6B)],
  dark: false,
);

const citrus = Palette(
  key: 'citrus',
  name: 'Citrus',
  bg: Color(0xFFFFFDF5),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFFFF6DC),
  text: Color(0xFF1A1703),
  muted: Color(0xFF7E7856),
  accent: Color(0xFFFF7A1A),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFF0E8CC),
  chart: [Color(0xFFFF7A1A), Color(0xFFFFC94D), Color(0xFF3BB273), Color(0xFF3B6FB2)],
  dark: false,
);

const ocean = Palette(
  key: 'ocean',
  name: 'Ocean',
  bg: Color(0xFF05161F),
  surface: Color(0xFF0B2231),
  raised: Color(0xFF123043),
  text: Color(0xFFEAF7FF),
  muted: Color(0xFF7FA3B8),
  accent: Color(0xFF31C5F5),
  accentFg: Color(0xFF05161F),
  border: Color(0xFF17394C),
  chart: [Color(0xFF31C5F5), Color(0xFF5BE0C0), Color(0xFFFFD479), Color(0xFFFF8BA0)],
  dark: true,
);

const palettes = [carbon, paper, citrus, ocean];

/// Design size per archetype (web `ARCHETYPES`).
const _size = <Archetype, (double, double)>{
  Archetype.saasLanding: (1440, 3080),
  Archetype.dashboard: (1440, 960),
  Archetype.pricing: (1440, 1360),
  Archetype.ecommerce: (1440, 2120),
  Archetype.portfolio: (1440, 2110),
  Archetype.checkout: (1440, 900),
  Archetype.auth: (1440, 900),
  Archetype.editorial: (1440, 1650),
  Archetype.docs: (1440, 1020),
  Archetype.agency: (1440, 2830),
  Archetype.mobileFinance: (390, 844),
  Archetype.mobileFeed: (390, 844),
  Archetype.mobileOnboarding: (390, 844),
  Archetype.mobileProfile: (390, 844),
};

Source _source(Palette p) => Source(
      slug: 'acme',
      name: 'Acme',
      domain: 'acme.test',
      industry: 'fintech',
      style: p.dark ? 'dark' : 'minimal',
      tech: const ['react'],
      palette: p.key,
      tagline: 'Money that moves as fast as your team',
      about: 'An independent studio for brands that would rather be remembered than liked.',
    );

Item fixtureScreen(Archetype a, Palette p) {
  final (w, h) = _size[a]!;
  final mobile = a.isMobileApp;
  return Item(
    id: 's-${a.slug}',
    slug: 's-${a.slug}-${p.key}',
    kind: Kind.screen,
    title: 'Home',
    archetype: a,
    source: _source(p),
    palette: p,
    aspect: w / h,
    category: 'test',
    industry: 'fintech',
    style: 'minimal',
    platform: mobile ? 'ios' : 'web',
    device: mobile ? Device.mobile : Device.desktop,
    tech: const ['react'],
    blocks: const [],
    hasCode: false,
    tier: Tier.free,
    responsive: true,
    has3d: false,
    saves: 1,
    views: 1,
    daysAgo: 1,
    colors: [p.bg, p.surface, p.accent, p.text, p.muted],
  );
}

Item fixtureComponent(Archetype a, String type, Palette p) {
  final screen = fixtureScreen(a, p);
  final mobile = screen.device == Device.mobile;
  return Item(
    id: 'c-${a.slug}-$type',
    slug: 'c-${a.slug}-$type-${p.key}',
    kind: Kind.component,
    title: type,
    archetype: a,
    source: screen.source,
    palette: p,
    aspect: mobile ? 0.9 : (type == 'footer' || type == 'navbar' ? 3.2 : 1.55),
    category: screen.category,
    industry: screen.industry,
    style: screen.style,
    platform: screen.platform,
    device: screen.device,
    tech: screen.tech,
    componentType: type,
    parentSlug: screen.slug,
    crop: const Crop(y: 0, h: 0.2),
    blocks: [Block(type, type)],
    hasCode: false,
    tier: Tier.free,
    responsive: true,
    has3d: false,
    saves: 1,
    views: 1,
    daysAgo: 1,
    colors: screen.colors,
  );
}

/// Every component type the renderer knows, on a plausible parent archetype.
final componentFixtures = <Item>[
  for (final (a, t) in const [
    (Archetype.saasLanding, 'navbar'),
    (Archetype.saasLanding, 'hero'),
    (Archetype.pricing, 'pricing'),
    (Archetype.dashboard, 'table'),
    (Archetype.dashboard, 'stats'),
    (Archetype.saasLanding, 'testimonials'),
    (Archetype.saasLanding, 'cta'),
    (Archetype.saasLanding, 'footer'),
    (Archetype.auth, 'login'),
    (Archetype.checkout, 'checkout'),
    (Archetype.dashboard, 'sidebar'),
    (Archetype.dashboard, 'charts'),
    (Archetype.ecommerce, 'filters'),
    (Archetype.saasLanding, 'cards'),
    (Archetype.dashboard, 'list'),
    (Archetype.docs, 'tabs'),
    (Archetype.mobileFinance, 'navbar'),
    (Archetype.mobileFeed, 'cards'),
    (Archetype.mobileFinance, 'stats'),
  ])
    fixtureComponent(a, t, palettes[t.length % palettes.length]),
];
