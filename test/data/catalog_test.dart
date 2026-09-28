import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/data/palettes.dart';
import 'package:uiverse/data/rng.dart';

import 'web_ref.dart';

void main() {
  group('rng', () {
    test('hash32 is FNV-1a (unsigned 32-bit)', () {
      expect(hash32(''), 2166136261);
      expect(hash32('a'), 0xE40C292C);
      expect(hash32('foobar'), 0xBF9CF968);
    });

    test('rnd stays in [min, max)', () {
      for (int i = 0; i < 500; i++) {
        final int v = rnd('seed$i', 3, 9);
        expect(v, inInclusiveRange(3, 8));
      }
    });
  });

  group('catalog parity (CLAUDE.md)', () {
    test('counts', () {
      expect(kItems.length, 181);
      expect(screens().length, 68);
      expect(components().length, 113);
    });

    test('first items', () {
      final Item s1 = kItems[0];
      expect(s1.slug, 's001-ledgerly-homepage');
      expect(<Object>[s1.saves, s1.views, s1.daysAgo], <Object>[3747, 43984, 105]);
      expect(s1.hasCode, isTrue);
      expect(s1.tier, Tier.premium);
      expect(s1.aspect, 0.4675324675324675);

      final Item c1 = kItems[1];
      expect(c1.slug, 'c0011-ledgerly-navbar');
      expect(<Object>[c1.saves, c1.views, c1.daysAgo], <Object>[2360, 35826, 19]);
      expect(c1.crop!.y, 0);
      expect(c1.crop!.h, 0.125);

      expect(kItems[2].slug, 'c0012-ledgerly-cards');
      expect(<Object>[kItems[2].saves, kItems[2].views, kItems[2].daysAgo], <Object>[748, 4950, 112]);
      expect(kItems[3].slug, 'c0013-ledgerly-cta');
      expect(<Object>[kItems[3].saves, kItems[3].views, kItems[3].daysAgo], <Object>[2561, 23688, 33]);

      final Item s2 = kItems[4];
      expect(s2.slug, 's002-ledgerly-spend-overview');
      expect(<Object>[s2.saves, s2.views, s2.daysAgo], <Object>[4150, 16053, 140]);
      expect(s2.tier, Tier.free);
      expect(s2.aspect, 1.5);
    });
  });

  test('every item matches the web generator field-for-field', () {
    final List<Object?> ref = refList('items');
    expect(kItems.length, ref.length);
    for (int n = 0; n < ref.length; n++) {
      final Map<String, Object?> r = obj(ref[n]);
      final Item i = kItems[n];
      final String at = '${r['slug']}';
      expect(i.id, r['id'], reason: at);
      expect(i.slug, r['slug'], reason: at);
      expect(i.kind.name, r['kind'], reason: at);
      expect(i.title, r['title'], reason: at);
      expect(i.archetype.slug, r['archetype'], reason: at);
      expect(i.source.slug, r['source'], reason: at);
      expect(i.palette.key, r['palette'], reason: at);
      expect(i.aspect, (r['aspect']! as num).toDouble(), reason: at);
      expect(i.category, r['category'], reason: at);
      expect(i.industry, r['industry'], reason: at);
      expect(i.style, r['style'], reason: at);
      expect(i.platform, r['platform'], reason: at);
      expect(i.device.name, r['device'], reason: at);
      expect(i.componentType, r['componentType'], reason: at);
      expect(i.parentSlug, r['parentSlug'], reason: at);
      final Object? crop = r['crop'];
      if (crop == null) {
        expect(i.crop, isNull, reason: at);
      } else {
        expect(i.crop!.y, (obj(crop)['y']! as num).toDouble(), reason: at);
        expect(i.crop!.h, (obj(crop)['h']! as num).toDouble(), reason: at);
      }
      expect(i.hasCode, r['hasCode'], reason: at);
      expect(i.tier.name, r['tier'], reason: at);
      expect(i.has3d, r['has3d'], reason: at);
      expect(i.saves, r['saves'], reason: at);
      expect(i.views, r['views'], reason: at);
      expect(i.daysAgo, r['daysAgo'], reason: at);
      expect(i.colors.map(hexOf).toList(), strings(r['colors']), reason: at);
    }
  });

  test('bySlug', () {
    expect(bySlug('s002-ledgerly-spend-overview'), same(kItems[4]));
    expect(bySlug('nope'), isNull);
  });

  test('layouts match web', () {
    final List<Object?> ref = refList('layouts');
    expect(kLayouts.length, ref.length);
    for (int n = 0; n < ref.length; n++) {
      final Map<String, Object?> r = obj(ref[n]);
      final LayoutEntry l = kLayouts[n];
      expect(<Object>[l.slug, l.name, l.example.slug, l.uses, l.sections.length],
          <Object?>[r['slug'], r['name'], r['example'], r['uses'], r['sections']]);
    }
  });

  test('palette items match web', () {
    final List<Object?> ref = refList('paletteItems');
    expect(kPaletteItems.length, ref.length);
    for (int n = 0; n < ref.length; n++) {
      final Map<String, Object?> r = obj(ref[n]);
      final PaletteEntry p = kPaletteItems[n];
      expect(<Object>[p.slug, p.example.slug, p.source.slug, p.saves],
          <Object?>[r['slug'], r['example'], r['source'], r['saves']]);
    }
  });

  test('creators match web', () {
    final List<Object?> ref = refList('creators');
    expect(kCreators.length, ref.length);
    for (int n = 0; n < ref.length; n++) {
      final Map<String, Object?> r = obj(ref[n]);
      final Creator c = kCreators[n];
      expect(<Object>[c.handle, c.role, c.screens, c.followers, c.available],
          <Object?>[r['handle'], r['role'], r['screens'], r['followers'], r['available']]);
    }
  });

  test('every archetype is defined and every source has a known palette', () {
    expect(kArchetypes.keys.toSet(), Archetype.values.toSet());
    for (final Source s in kSources) {
      expect(kPalettes.map((Palette p) => p.key), contains(s.palette));
    }
  });
}
