/// Data behind `/source/[slug]` (web `app/(app)/source/[slug]/page.tsx`).
library;

import 'dart:ui';

import '../../data/catalog.dart';
import '../../data/models.dart';

/// One product's catalogue: its screens, its components and the palette
/// inferred from its first screen.
class SourceView {
  SourceView._(this.source, this.all)
      : screens = <Item>[for (final Item i in all) if (i.kind == Kind.screen) i],
        components = <Item>[for (final Item i in all) if (i.kind == Kind.component) i];

  final Source source;
  final List<Item> all;
  final List<Item> screens;
  final List<Item> components;

  /// The first screen's palette; null when the source has no screens.
  Palette? get palette => screens.isEmpty ? null : screens.first.palette;

  /// Saves summed across every item.
  int get totalSaves => all.fold(0, (int a, Item i) => a + i.saves);

  /// Block labels across the screens, de-duplicated in first-seen order.
  List<String> get recurringBlocks => <String>{
        for (final Item s in screens)
          for (final Block b in s.blocks) b.label,
      }.toList();

  /// Palette rows shown under "Inferred palette".
  List<(String, Color)> get paletteRows {
    final Palette? p = palette;
    if (p == null) return const <(String, Color)>[];
    return <(String, Color)>[
      ('Background', p.bg),
      ('Surface', p.surface),
      ('Raised', p.raised),
      ('Border', p.border),
      ('Text', p.text),
      ('Muted', p.muted),
      ('Accent', p.accent),
    ];
  }
}

/// The view for [slug], or null when no source has that slug.
SourceView? sourceView(String slug) {
  for (final Source s in kSources) {
    if (s.slug == slug) {
      return SourceView._(s, <Item>[for (final Item i in kItems) if (i.source.slug == slug) i]);
    }
  }
  return null;
}

/// The Source page tabs: `?tab=` id, label and count (0 = no count shown).
List<(String, String, int)> sourceTabs(SourceView v) => <(String, String, int)>[
      ('screens', 'Screens', v.screens.length),
      ('components', 'Components', v.components.length),
      ('system', 'Palette & type', 0),
    ];
