import 'package:flutter/painting.dart';

/// Core content types, ported from web `src/lib/data.ts` and `palettes.ts`.
/// Data itself (generator, taxonomy, palettes) lives in sibling files.

enum Archetype {
  saasLanding('saas-landing'),
  dashboard('dashboard'),
  pricing('pricing'),
  ecommerce('ecommerce'),
  portfolio('portfolio'),
  checkout('checkout'),
  auth('auth'),
  editorial('editorial'),
  docs('docs'),
  agency('agency'),
  mobileFinance('mobile-finance'),
  mobileFeed('mobile-feed'),
  mobileOnboarding('mobile-onboarding'),
  mobileProfile('mobile-profile');

  const Archetype(this.slug);

  /// Web identifier, e.g. `saas-landing`.
  final String slug;

  bool get isMobileApp => slug.startsWith('mobile-');

  static Archetype fromSlug(String s) => values.firstWhere((a) => a.slug == s);
}

enum Kind {
  screen,
  component,
  layout,
  palette;

  static Kind fromName(String s) => values.byName(s);
}

enum Device {
  desktop,
  tablet,
  mobile;

  static Device fromName(String s) => values.byName(s);
}

/// Mock-renderer viewport (§11.2).
enum Viewport {
  desktop('Laptop', 1440, 900),
  tablet('Tablet', 834, 1194),
  mobile('Mobile', 390, 844);

  const Viewport(this.label, this.w, this.h);
  final String label;
  final double w;
  final double h;

  /// `pick(vp)(desktop, tablet, mobile)` from `primitives.tsx`.
  T pick<T>(T desktop, T tablet, T mobile) => switch (this) {
        Viewport.desktop => desktop,
        Viewport.tablet => tablet,
        Viewport.mobile => mobile,
      };
}

enum Tier { free, premium }

class Palette {
  const Palette({
    required this.key,
    required this.name,
    required this.bg,
    required this.surface,
    required this.raised,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentFg,
    required this.border,
    required this.chart,
    required this.dark,
  });

  final String key;
  final String name;
  final Color bg, surface, raised, text, muted, accent, accentFg, border;

  /// Four chart series colours.
  final List<Color> chart;
  final bool dark;
}

class Block {
  const Block(this.type, this.label);
  final String type;
  final String label;
}

class Source {
  const Source({
    required this.slug,
    required this.name,
    required this.domain,
    required this.industry,
    required this.style,
    required this.tech,
    required this.palette,
    required this.tagline,
    required this.about,
  });

  final String slug;
  final String name;
  final String domain;
  final String industry;
  final String style;
  final List<String> tech;

  /// Palette key.
  final String palette;
  final String tagline;
  final String about;
}

/// Vertical crop of a parent screen, as fractions of its height.
class Crop {
  const Crop({required this.y, required this.h});
  final double y;
  final double h;
}

class Item {
  const Item({
    required this.id,
    required this.slug,
    required this.kind,
    required this.title,
    required this.archetype,
    required this.source,
    required this.palette,
    required this.aspect,
    required this.category,
    required this.industry,
    required this.style,
    required this.platform,
    required this.device,
    required this.tech,
    this.componentType,
    this.parentSlug,
    this.crop,
    required this.blocks,
    required this.hasCode,
    required this.tier,
    required this.responsive,
    required this.has3d,
    required this.saves,
    required this.views,
    required this.daysAgo,
    required this.colors,
  });

  final String id;
  final String slug;
  final Kind kind;
  final String title;
  final Archetype archetype;
  final Source source;
  final Palette palette;

  /// width / height.
  final double aspect;
  final String category;
  final String industry;
  final String style;
  final String platform;
  final Device device;
  final List<String> tech;
  final String? componentType;
  final String? parentSlug;
  final Crop? crop;
  final List<Block> blocks;
  final bool hasCode;
  final Tier tier;
  final bool responsive;
  final bool has3d;
  final int saves;
  final int views;
  final int daysAgo;

  /// `[bg, surface, accent, text, muted]`.
  final List<Color> colors;

  bool get isPremium => tier == Tier.premium;
}

/// Archetype geometry + section structure (`ARCHETYPES` in data.ts).
class ArchetypeDef {
  const ArchetypeDef({
    required this.w,
    required this.h,
    required this.category,
    required this.device,
    required this.blocks,
  });

  final double w;
  final double h;
  final String category;
  final Device device;
  final List<Block> blocks;
}
