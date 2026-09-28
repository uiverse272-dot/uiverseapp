import 'package:flutter_test/flutter_test.dart';
import 'package:uiverse/data/query.dart';
import 'package:uiverse/screens/search/search_logic.dart';

void main() {
  test('kindTabs counts All / Designs / Components', () {
    final tabs = kindTabs('dark fintech dashboard');
    expect(tabs.map((t) => t.label), ['All', 'Designs', 'Components']);
    expect(tabs.map((t) => t.kind), [null, 'screen', 'component']);
    expect(tabs[0].count, 5);
    expect(tabs[1].count + tabs[2].count, 5);
  });

  test('queryWithout drops the words behind a term (slug or label), keeps the rest', () {
    final terms = parseQuery('Dark fintech dashboard').terms;
    final style = terms.firstWhere((t) => t.param == 'style');
    expect(queryWithout('Dark fintech dashboard', style), 'fintech dashboard');
    final type = terms.firstWhere((t) => t.param == 'category');
    expect(queryWithout('dark  fintech dashboard', type), 'dark fintech');
  });

  test('queryWithout keeps synonyms, like the web', () {
    final industry = parseQuery('bank app').terms.single;
    expect(industry.value, 'fintech');
    expect(queryWithout('bank app', industry), 'bank app');
  });

  test('searchParams omits blank q and null kind', () {
    expect(searchParams('  '), isEmpty);
    expect(searchParams(' dark ', 'screen'), {'q': 'dark', 'kind': 'screen'});
    expect(searchParams('dark'), {'q': 'dark'});
  });
}
