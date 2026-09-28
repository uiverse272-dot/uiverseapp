import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/catalog.dart';
import 'package:uiverse/data/models.dart';
import 'package:uiverse/data/prompt.dart';
import 'package:uiverse/data/spec.dart';

import 'web_ref.dart';

PromptOptions optsFromWeb(Map<String, Object?> o) => PromptOptions(
      tool: ToolId.values.firstWhere((ToolId t) => t.id == o['tool']),
      stack: StackId.values.firstWhere((StackId s) => s.id == o['stack']),
      includeTokens: o['includeTokens']! as bool,
      includeType: o['includeType']! as bool,
      includeLayout: o['includeLayout']! as bool,
      includeSections: o['includeSections']! as bool,
      includeA11y: o['includeA11y']! as bool,
    );

void main() {
  test('buildPrompt is byte-identical to web', () {
    final List<Object?> ref = refList('prompts');
    expect(ref, isNotEmpty);
    for (final Object? row in ref) {
      final Map<String, Object?> r = obj(row);
      final Item item = bySlug(r['slug']! as String)!;
      final String text = buildPrompt(item, optsFromWeb(obj(r['opts'])));
      expect(text, r['text'], reason: '${r['slug']} ${r['opts']}');
      expect(estimateTokens(text), r['tokens']);
    }
  });

  test('default prompt is non-empty with a sane token estimate', () {
    final String text = buildPrompt(kItems.first, defaultPromptOptions);
    expect(text, startsWith('Build a landing page for a fintech product using Next.js + Tailwind.'));
    expect(estimateTokens(text), (text.length / 4).ceil());
    expect(estimateTokens(''), 0);
    expect(estimateTokens('abcde'), 2);
  });

  test('PromptOptions copyWith / equality', () {
    final PromptOptions o = defaultPromptOptions.copyWith(tool: ToolId.v0, includeA11y: false);
    expect(o.tool, ToolId.v0);
    expect(o.stack, StackId.nextjs);
    expect(o.includeA11y, isFalse);
    expect(o.copyWith(tool: ToolId.claude, includeA11y: true), defaultPromptOptions);
  });

  test('spec matches web (rules, section notes, colour roles)', () {
    for (final Object? row in refList('rules')) {
      final Map<String, Object?> r = obj(row);
      final Item item = bySlug(r['slug']! as String)!;
      final List<(String, String)> rules = responsiveRules(item);
      expect(rules.map(((String, String) x) => <String>[x.$1, x.$2]).toList(),
          list(r['rules']).map(strings).toList(), reason: item.slug);
      expect(sections(item).map((Section s) => s.note).toList(), strings(r['sections']));
      expect(colorRoles(item).map((ColorRole c) => c.value).toList(), strings(r['roles']));
    }
  });
}
