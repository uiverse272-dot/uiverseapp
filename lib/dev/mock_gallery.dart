import 'package:flutter/material.dart' hide Viewport;

import '../data/models.dart';
import '../mock/mock_screen.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';

/// Dev page (`/dev/mock`): every archetype at laptop / tablet / mobile, then
/// each block-only component type as a feed card. Uses its own fixture items
/// until it is wired to the real catalog.
class MockGalleryPage extends StatelessWidget {
  const MockGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final rows = <Widget Function()>[
      for (final (i, a) in Archetype.values.indexed) () => _ArchetypeRow(item: _screen(a, _palettes[i % 4])),
      () => const _ComponentGrid(),
    ];
    return ColoredBox(
      color: ui.bg,
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) => rows[i](),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(text, style: UiText.sectionHead.copyWith(color: context.ui.text)),
      );
}

class _ArchetypeRow extends StatelessWidget {
  const _ArchetypeRow({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) {
    const widths = {Viewport.desktop: 480.0, Viewport.tablet: 280.0, Viewport.mobile: 160.0};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('${item.archetype.slug} · ${item.palette.name}'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final MapEntry(key: vp, value: w) in widths.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vp.label, style: UiText.meta.copyWith(color: context.ui.text2)),
                      const SizedBox(height: 4),
                      DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(border: Border.all(color: context.ui.border)),
                        child: SizedBox(width: w, child: MockScreen(item: item, viewport: vp)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComponentGrid extends StatelessWidget {
  const _ComponentGrid();

  static const _types = [
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
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Components (block only)'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (i, (a, t)) in _types.indexed)
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$t · ${a.slug}', style: UiText.meta.copyWith(color: context.ui.text2)),
                    const SizedBox(height: 4),
                    MockScreen(item: _component(a, t, _palettes[i % 4])),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/* ------------------------------------------------------------- fixtures */

// Copied from web src/lib/palettes.ts (carbon, paper, citrus, ocean).
const _palettes = [
  Palette(
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
  ),
  Palette(
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
  ),
  Palette(
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
  ),
  Palette(
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
  ),
];

double _aspect(Archetype a) => switch (a) {
      Archetype.saasLanding => 1440 / 3080,
      Archetype.dashboard => 1440 / 960,
      Archetype.pricing => 1440 / 1360,
      Archetype.ecommerce => 1440 / 2120,
      Archetype.portfolio => 1440 / 2110,
      Archetype.checkout || Archetype.auth => 1440 / 900,
      Archetype.editorial => 1440 / 1650,
      Archetype.docs => 1440 / 1020,
      Archetype.agency => 1440 / 2830,
      _ => 390 / 844,
    };

Item _screen(Archetype a, Palette p) => Item(
      id: 'dev-${a.slug}',
      slug: 'dev-${a.slug}',
      kind: Kind.screen,
      title: 'Home',
      archetype: a,
      source: Source(
        slug: 'acme',
        name: 'Acme',
        domain: 'acme.dev',
        industry: 'fintech',
        style: p.dark ? 'dark' : 'minimal',
        tech: const ['react'],
        palette: p.key,
        tagline: 'Money that moves as fast as your team',
        about: 'An independent studio for brands that would rather be remembered than liked.',
      ),
      palette: p,
      aspect: _aspect(a),
      category: a.slug,
      industry: 'fintech',
      style: p.dark ? 'dark' : 'minimal',
      platform: a.isMobileApp ? 'ios' : 'web',
      device: a.isMobileApp ? Device.mobile : Device.desktop,
      tech: const ['react'],
      blocks: const [],
      hasCode: false,
      tier: Tier.free,
      responsive: true,
      has3d: false,
      saves: 0,
      views: 0,
      daysAgo: 0,
      colors: [p.bg, p.surface, p.accent, p.text, p.muted],
    );

Item _component(Archetype a, String type, Palette p) {
  final s = _screen(a, p);
  return Item(
    id: '${s.id}-$type',
    slug: '${s.slug}-$type',
    kind: Kind.component,
    title: type,
    archetype: a,
    source: s.source,
    palette: p,
    aspect: a.isMobileApp ? 0.9 : (type == 'footer' || type == 'navbar' ? 3.2 : 1.55),
    category: s.category,
    industry: s.industry,
    style: s.style,
    platform: s.platform,
    device: s.device,
    tech: s.tech,
    componentType: type,
    parentSlug: s.slug,
    blocks: [Block(type, type)],
    hasCode: false,
    tier: Tier.free,
    responsive: true,
    has3d: false,
    saves: 0,
    views: 0,
    daysAgo: 0,
    colors: s.colors,
  );
}
