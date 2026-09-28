/// Implementation prompt generator, ported from web `prompt.ts`.
///
/// Output is byte-identical to the web for the same item and options
/// (see `test/data/prompt_test.dart`).
library;

import 'models.dart';
import 'spec.dart';
import 'taxonomy.dart';

/// Target AI tool; [id] is the web id.
enum ToolId {
  claude('claude', 'Claude', 'Full spec, asks for one complete runnable file'),
  chatgpt('chatgpt', 'ChatGPT', 'Full spec, explicit about no placeholder comments'),
  cursor('cursor', 'Cursor', 'Terse, file-oriented, assumes an existing codebase'),
  codex('codex', 'Codex', 'Terse, task-shaped, no preamble'),
  v0('v0', 'v0', 'Single page component, Next.js + Tailwind assumed'),
  lovable('lovable', 'Lovable', 'Screen-level, reuses an existing design system'),
  bolt('bolt', 'Bolt', 'Scaffolds a new project from scratch');

  const ToolId(this.id, this.label, this.hint);
  final String id;
  final String label;
  final String hint;
}

/// How colour tokens are written for a stack.
enum TokenSyntax { tailwind, css, swift }

/// Target stack; [id] is the web id.
enum StackId {
  nextjs('nextjs', 'Next.js + Tailwind', TokenSyntax.tailwind),
  react('react', 'React + Tailwind', TokenSyntax.tailwind),
  html('html', 'HTML + CSS', TokenSyntax.css),
  vue('vue', 'Vue + Tailwind', TokenSyntax.tailwind),
  swiftui('swiftui', 'SwiftUI', TokenSyntax.swift);

  const StackId(this.id, this.label, this.tokens);
  final String id;
  final String label;
  final TokenSyntax tokens;
}

class PromptOptions {
  const PromptOptions({
    required this.tool,
    required this.stack,
    required this.includeTokens,
    required this.includeType,
    required this.includeLayout,
    required this.includeSections,
    required this.includeA11y,
  });

  final ToolId tool;
  final StackId stack;
  final bool includeTokens;
  final bool includeType;
  final bool includeLayout;
  final bool includeSections;
  final bool includeA11y;

  PromptOptions copyWith({
    ToolId? tool,
    StackId? stack,
    bool? includeTokens,
    bool? includeType,
    bool? includeLayout,
    bool? includeSections,
    bool? includeA11y,
  }) =>
      PromptOptions(
        tool: tool ?? this.tool,
        stack: stack ?? this.stack,
        includeTokens: includeTokens ?? this.includeTokens,
        includeType: includeType ?? this.includeType,
        includeLayout: includeLayout ?? this.includeLayout,
        includeSections: includeSections ?? this.includeSections,
        includeA11y: includeA11y ?? this.includeA11y,
      );

  @override
  bool operator ==(Object other) =>
      other is PromptOptions &&
      other.tool == tool &&
      other.stack == stack &&
      other.includeTokens == includeTokens &&
      other.includeType == includeType &&
      other.includeLayout == includeLayout &&
      other.includeSections == includeSections &&
      other.includeA11y == includeA11y;

  @override
  int get hashCode => Object.hash(
      tool, stack, includeTokens, includeType, includeLayout, includeSections, includeA11y);
}

/// Web `DEFAULT_OPTIONS`.
const PromptOptions defaultPromptOptions = PromptOptions(
  tool: ToolId.claude,
  stack: StackId.nextjs,
  includeTokens: true,
  includeType: true,
  includeLayout: true,
  includeSections: true,
  includeA11y: true,
);

/* ------------------------------------------------------------------ */

String _preamble(ToolId tool, String subject, String stackName) {
  switch (tool) {
    case ToolId.cursor:
      return 'Add $subject to this codebase, built with $stackName.\n\nFollow the conventions already in the repo: existing component structure, existing token names, existing utility helpers. Do not add dependencies. Do not restate the spec back to me — make the edits.';
    case ToolId.codex:
      return 'Task: implement $subject in $stackName.\n\nWrite the files. No preamble, no explanation, no TODO comments.';
    case ToolId.v0:
      return 'Build $subject as a single page component using $stackName.\n\nUse shadcn/ui primitives where one fits; write plain elements where one does not. One file, production quality, no placeholder content.';
    case ToolId.lovable:
      return 'Build $subject using $stackName.\n\nIf the project already has a design system, use its tokens and components rather than the raw values below — treat this spec as the intent, not the implementation.';
    case ToolId.bolt:
      return 'Create a new $stackName project containing $subject.\n\nSet up the tokens below as the theme before writing any markup, so every value comes from the theme rather than being hard-coded.';
    case ToolId.chatgpt:
      return 'Build $subject using $stackName.\n\nReturn one complete, runnable file. No placeholder comments, no "// rest of the code here", no lorem ipsum — write plausible real copy.';
    case ToolId.claude:
      return 'Build $subject using $stackName.\n\nReturn one complete, runnable file. Every value below is measured from a real interface, so treat it as a specification rather than a suggestion. Where the spec is silent, choose the restrained option.';
  }
}

String _camel(String s) =>
    s.replaceAllMapped(RegExp(r'-(\w)'), (Match m) => m[1]!.toUpperCase());

String _tokenBlock(Item item, TokenSyntax syntax) {
  final List<ColorRole> roles = colorRoles(item);
  switch (syntax) {
    case TokenSyntax.swift:
      return <String>[
        '```swift',
        'extension Color {',
        for (final ColorRole r in roles)
          '    static let ${_camel(r.token)} = Color(hex: "${r.value}")',
        '}',
        '```',
      ].join('\n');
    case TokenSyntax.css:
      return <String>[
        '```css',
        ':root {',
        for (final ColorRole r in roles) '  --${r.token}: ${r.value};',
        '}',
        '```',
      ].join('\n');
    case TokenSyntax.tailwind:
      return <String>[
        '```css',
        '@theme {',
        for (final ColorRole r in roles) '  --color-${r.token}: ${r.value};',
        '}',
        '```',
        '',
        'Reference them as `bg-background`, `text-text-muted`, `border-border` and so on. Do not hard-code hex values in markup.',
      ].join('\n');
  }
}

/// JS number-to-string for the values used here (`68`, `11.5`).
String _jsNum(double v) => v == v.truncateToDouble() ? '${v.toInt()}' : '$v';

/// Lowercase a taxonomy label unless it carries internal capitals (SaaS, AI).
String _lower(String s) =>
    s.length > 1 && RegExp('[A-Z]').hasMatch(s.substring(1)) ? s : s.toLowerCase();

const Map<String, String> _styleNotes = <String, String>{
  'dark': 'deep neutral backgrounds, one luminous accent, generous negative space.',
  'minimal': 'near-monochrome, hairlines instead of shadows, hierarchy carried by type alone.',
  'light': 'bright neutral ground with a single saturated accent.',
  'editorial': 'large type, wide measure, restrained colour, content-first.',
  'brutalist': 'flat blocks, hard edges, high contrast, little ornament.',
  'luxury': 'warm dark ground, metallic accent, slow rhythm, lots of air.',
  'corporate': 'structured, blue-leaning, predictable grid, conservative type.',
  'playful': 'saturated accents, rounder radii, energetic spacing.',
  'futuristic': 'dark ground, neon accent, glow used once rather than everywhere.',
  'glassmorphism': 'translucent surfaces over a soft gradient, thin light borders.',
  'retro': 'warm muted palette, heavier type, visible grid.',
};

String _styleNote(String style) => _styleNotes[style] ?? 'restrained and content-led.';

/// Structured Markdown implementation spec for [item].
String buildPrompt(Item item, PromptOptions opts) {
  final StackId stack = opts.stack;
  final bool isComponent = item.kind == Kind.component;
  final String category = _lower(taxName(kCategories, item.category));
  final String industry = _lower(taxName(kIndustries, item.industry));
  final String style = _lower(taxName(kStyles, item.style));
  final LayoutSpec layout = layoutSpec(item);

  // "landing page screen" reads as a tautology; "dashboard screen" does not
  final String noun = RegExp(r'\bpage$').hasMatch(category) ? category : '$category screen';
  final String subject = isComponent
      ? 'a ${item.title.toLowerCase()} component for a $industry product'
      : 'a $noun for a $industry product';

  final List<String> out = <String>[];

  out.add(_preamble(opts.tool, subject, stack.label));
  out.add('');
  final String target = item.device == Device.mobile
      ? 'a phone screen at 390pt'
      : 'desktop at 1440px, then tablet and mobile';
  out.add('The register is **$style** — ${_styleNote(style)} The target is $target.');

  if (opts.includeSections) {
    out.addAll(<String>[
      '',
      '## Structure',
      '',
      'Render these in order. The note after each is how it actually looks.',
      '',
    ]);
    for (final Section s in sections(item)) {
      out.add('${s.index}. **${s.label}** — ${s.note}');
    }
  }

  if (opts.includeTokens) {
    out.addAll(<String>['', '## Colour tokens', '', _tokenBlock(item, stack.tokens)]);
    out.addAll(<String>[
      '',
      'Accent is used sparingly: primary buttons, the active navigation state, and at most one emphasis elsewhere. Everything else is neutral.',
    ]);
  }

  if (opts.includeType) {
    out.addAll(<String>[
      '',
      '## Typography',
      '',
      '| Step | Size | Weight | Used for |',
      '| --- | --- | --- | --- |',
    ]);
    for (final TypeStep t in typeScale(item)) {
      out.add('| ${t.name} | ${_jsNum(t.size)}px | ${t.weight} | ${t.use} |');
    }
    out.addAll(<String>[
      '',
      'One sans-serif family throughout. Tracking tightens to about -0.028em above 40px and sits near -0.011em below it. Body line height ${layout.body.split(' / ')[1]}.',
    ]);
  }

  if (opts.includeLayout) {
    out.addAll(<String>[
      '',
      '## Layout and spacing',
      '',
      '- Container: ${layout.container}, ${layout.columns}, ${layout.gutter} gutters',
      '- Radius: ${layout.radius} — nothing is fully rounded except pills and avatars',
      '- Spacing scale (4px base): ${kSpacing.join(', ')}',
      '- Hairline borders at 1px, low contrast. Shadows only on popovers and overlays, never on cards at rest.',
    ]);
    out.addAll(<String>['', '## Responsive behaviour', '']);
    for (final (String k, String v) in responsiveRules(item)) {
      out.add('- **$k:** $v');
    }
  }

  if (opts.includeA11y) {
    out.addAll(<String>[
      '',
      '## Requirements',
      '',
      '- Semantic landmarks: `header`, `nav`, `main`, `section`, `footer`',
      '- Every interactive element keyboard reachable with a visible focus ring',
      '- Colour contrast at least 4.5:1 for body text against its background',
      '- Honour `prefers-reduced-motion`; transitions no longer than 150ms',
      '- Explicit width and height on every image so nothing shifts as it loads',
      '- Write plausible product copy — never lorem ipsum, never placeholder brackets',
    ]);
  }

  out.addAll(<String>[
    '',
    '## Out of scope',
    '',
    "- Do not reproduce any real company's name, logo, wordmark or copy. This is a structural and stylistic reference, not a brand to clone.",
    '- No analytics, auth or data fetching unless asked — markup, styling and layout only.',
  ]);

  return out.join('\n');
}

/// Rough token estimate: `ceil(chars / 4)`, chars as UTF-16 code units.
int estimateTokens(String text) => (text.length / 4).ceil();
