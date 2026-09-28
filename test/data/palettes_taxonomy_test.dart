import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/data/palettes.dart';
import 'package:uiverse/data/taxonomy.dart';

import 'web_ref.dart';

void main() {
  group('palettes', () {
    test('16 palettes, unique keys, four chart colours each', () {
      expect(kPalettes.length, 16);
      expect(kPalettes.map((Palette p) => p.key).toSet().length, 16);
      for (final Palette p in kPalettes) {
        expect(p.chart.length, 4, reason: p.key);
      }
    });

    test('paletteByKey finds and falls back to carbon', () {
      expect(paletteByKey('ledger').name, 'Ledger');
      expect(paletteByKey('noir').name, 'Noir Luxe');
      expect(paletteByKey('missing'), same(kCarbon));
      expect(paletteByKey(''), same(kCarbon));
    });

    test('hexOf formats as uppercase #RRGGBB', () {
      expect(hexOf(kCarbon.bg), '#0B0D10');
      expect(hexOf(const Color(0xFF00A884)), '#00A884');
      expect(hexOf(const Color(0xFF000000)), '#000000');
    });
  });

  group('taxonomy', () {
    test('list sizes', () {
      expect(kCategories.length, 14);
      expect(kIndustries.length, 12);
      expect(kStyles.length, 11);
      expect(kTechnologies.length, 10);
      expect(kComponentTypes.length, 27);
      expect(kPlatforms.length, 4);
      expect(kAppCategories.length, 8);
      expect(kSorts.map((Tax t) => t.slug), <String>['trending', 'new', 'saved', 'views']);
    });

    test('taxName looks up, falls back to slug, then empty', () {
      expect(taxName(kCategories, 'auth'), 'Login');
      expect(taxName(kIndustries, 'ai'), 'AI');
      expect(taxName(kIndustries, 'unknown-thing'), 'unknown-thing');
      expect(taxName(kIndustries, null), '');
    });

    test('componentGroups matches web', () {
      final List<(String, List<Tax>)> groups = componentGroups();
      final List<Object?> ref = refList('groups');
      expect(groups.length, ref.length);
      for (int i = 0; i < ref.length; i++) {
        final List<Object?> r = list(ref[i]);
        expect(groups[i].$1, r[0]);
        expect(groups[i].$2.map((Tax t) => t.slug).toList(), strings(r[1]));
      }
    });
  });
}
