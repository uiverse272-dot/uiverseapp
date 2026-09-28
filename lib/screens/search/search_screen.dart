import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/query.dart';
import '../../router/routes.dart';
import '../../shell/search_field.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/hover_tap.dart';
import '../../widgets/core/ui_icon.dart';
import '../../widgets/feed/feed.dart';
import '../../widgets/feed/url_query.dart';
import '../../widgets/section/section.dart';
import 'search_logic.dart';
import 'segment_tab.dart';

/// Max width of the search column (§4.2).
const double kSearchColumn = 620;

/// `/search?q=&kind=` — natural-language search (§12). Big [SearchField]
/// on top; without a query, suggestions and an explainer; with one, a
/// pinned bar of kind tabs and removable "Reading as" parse chips, then the
/// [Feed] of results.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, required this.query});

  /// URL query params: `q` (the search) and `kind` (`screen` | `component`).
  final Map<String, String> query;

  @override
  Widget build(BuildContext context) {
    final String q = query['q'] ?? '';
    final String? kind = (query['kind'] ?? '').isEmpty ? null : query['kind'];
    final bool hasQuery = q.trim().isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverShell(
          sliver: SliverToBoxAdapter(
            child: _Column(
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 20),
                child: SearchField.big(
                  key: ValueKey<String>(q),
                  initialQuery: q,
                  readingAs: (String s) => <String>[
                    for (final ParsedTerm t in parseQuery(s).terms) '${t.dimension}: ${t.label}',
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasQuery) ..._results(context, q, kind) else const SliverShell(sliver: SliverToBoxAdapter(child: _Suggestions())),
      ],
    );
  }

  List<Widget> _results(BuildContext context, String q, String? kind) {
    final SearchResult r = searchItems(q, Filters(kind: kind));
    return <Widget>[
      StickyBar(
        child: _SearchBar(q: q, kind: kind, terms: r.terms, residual: r.residual),
      ),
      SliverShell(
        sliver: SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: Feed(items: r.results),
        ),
      ),
    ];
  }
}

/// Centred column, max [kSearchColumn] wide.
class _Column extends StatelessWidget {
  const _Column({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kSearchColumn),
          child: child,
        ),
      );
}

/// Kind tabs, then the parse ("Reading as" chips + residual). Scrolls
/// horizontally when it doesn't fit the fixed-height bar.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.q, required this.kind, required this.terms, required this.residual});

  final String q;
  final String? kind;
  final List<ParsedTerm> terms;
  final String residual;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final KindTab t in kindTabs(q)) ...[
            if (t.kind != null) const SizedBox(width: 4),
            SegmentTab(
              label: t.label,
              count: t.count,
              selected: kind == t.kind,
              onTap: () => context.go(withQuery(Routes.search, searchParams(q, t.kind))),
            ),
          ],
          // The parse is shown, not hidden: a wrong guess has a repair path.
          if (terms.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: c.border))),
              child: Row(
                children: [
                  Text('Reading as', style: UiText.small.copyWith(color: c.text3)),
                  for (final ParsedTerm t in terms) ...[
                    const SizedBox(width: 6),
                    ParseChip(
                      term: t,
                      onRemove: () => context.go(withQuery(Routes.search, searchParams(queryWithout(q, t)))),
                    ),
                  ],
                  if (residual.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text('+ “$residual” as free text', style: UiText.small.copyWith(color: c.text3)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Removable parse chip (§10.14): "dimension: label ✕", 12px, border,
/// bg-subtle, 8×4; hover border-strong.
class ParseChip extends StatelessWidget {
  const ParseChip({super.key, required this.term, required this.onRemove});

  final ParsedTerm term;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final String text = '${term.dimension}: ${term.label}';
    return HoverTap(
      onTap: onRemove,
      label: 'Remove $text',
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.bgSubtle,
          border: Border.all(color: hovered ? c.borderStrong : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: UiText.small.copyWith(color: c.text)),
            const SizedBox(width: 4),
            UiIcon(Ui.close, size: 11, color: c.text),
          ],
        ),
      ),
    );
  }
}

/// No query: "Try a natural-language query", suggestion chips, explainer.
class _Suggestions extends StatelessWidget {
  const _Suggestions();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return _Column(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                header: true,
                child: Text(
                  'Try a natural-language query',
                  style: UiText.mono(13, bold: true, color: c.text3),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String s in kSearchSuggestions) _Suggestion(s),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Queries are parsed against the taxonomy first — deterministic, explainable and reusable as URL '
              'state — then widened with free text. Whatever the parser decides is shown back to you as chips '
              'you can remove.',
              style: UiText.mono(13, height: 1.625, color: c.text2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Suggestion chip: 13px, border, 12×6; hover bg-subtle + text.
class _Suggestion extends StatelessWidget {
  const _Suggestion(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: () => context.go(Routes.searchFor(text)),
      link: true,
      label: text,
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hovered ? c.bgSubtle : null,
          border: Border.all(color: c.border),
        ),
        child: Text(text, style: UiText.body.copyWith(color: hovered ? c.text : c.text2)),
      ),
    );
  }
}
