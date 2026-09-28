import 'package:flutter/material.dart';

import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/section/section.dart';
import '../directory/directory_page.dart';

/// A legal document: title and paragraphs.
typedef LegalDoc = ({String title, List<String> body});

const Map<String, LegalDoc> kLegalDocs = {
  'attribution': (
    title: 'Attribution policy',
    body: [
      'Every screen indexed here names its source, shows its logo and links to the live site. '
          'Attribution is never hidden behind a hover or a click.',
      'We index screenshots and derived facts about a page — its colour roles, type scale, spacing '
          "rhythm and section structure. We do not redistribute a site's markup, stylesheets, fonts or "
          'image assets.',
      'Code is only ever shown when it was contributed by its author, published under an open licence, '
          'or generated as a clearly-labelled re-implementation. A screenshot of a site is not '
          'permission to copy its source.',
      'Any site owner can opt out. One request removes every item from that domain across the '
          'platform, including from search and caches, and prevents future captures.',
    ],
  ),
  'takedown': (
    title: 'Takedown & opt-out',
    body: [
      'Send the domain and a contact address and we will remove everything captured from it, '
          'platform-wide, within 5 working days.',
      'Opt-out is a single flag on the source record — it removes the items, the derived components, '
          'the palettes and the search entries in one action.',
    ],
  ),
};

/// The doc for [doc], or the web's fallback ("Legal" / "Not found.").
LegalDoc legalDoc(String doc) => kLegalDocs[doc] ?? (title: 'Legal', body: const ['Not found.']);

/// `/legal/:doc` (§12): narrow PageHeader + paragraphs (14.5 text-2
/// relaxed, max 672). Unknown docs render the web fallback, not a 404.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final String doc;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final LegalDoc d = legalDoc(doc);
    return NarrowPage(
      children: [
        PageHeader(title: d.title),
        Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 64),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 672),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < d.body.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    Text(d.body[i], style: UiText.mono(14.5, height: 1.625, color: c.text2)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
