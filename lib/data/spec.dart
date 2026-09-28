/// The single derivation of a capture's design facts, ported from web
/// `spec.ts`. The Breakdown tab and the prompt generator both read from here.
library;

import 'package:flutter/painting.dart';

import 'models.dart';
import 'palettes.dart';

class ColorRole {
  const ColorRole({
    required this.key,
    required this.label,
    required this.token,
    required this.color,
  });

  /// Palette field name, e.g. `accentFg`.
  final String key;
  final String label;

  /// CSS token name, e.g. `accent-fg`.
  final String token;
  final Color color;

  /// `#RRGGBB`, as the web shows it.
  String get value => hexOf(color);
}

class TypeStep {
  const TypeStep(this.name, this.size, this.weight, this.use);
  final String name;
  final double size;
  final int weight;
  final String use;
}

class Section {
  const Section({
    required this.index,
    required this.label,
    required this.type,
    required this.note,
  });

  /// 1-based.
  final int index;
  final String label;
  final String type;
  final String note;
}

class LayoutSpec {
  const LayoutSpec({
    required this.container,
    required this.columns,
    required this.gutter,
    required this.radius,
    required this.body,
  });

  final String container;
  final String columns;
  final String gutter;
  final String radius;

  /// `size / line-height`, e.g. `15px / 1.55`.
  final String body;
}

/// Responsive rule: a label and `laptop → tablet → mobile` description.
typedef ResponsiveRule = (String label, String rule);

List<ColorRole> colorRoles(Item item) {
  final Palette p = item.palette;
  return <ColorRole>[
    ColorRole(key: 'bg', label: 'Background', token: 'background', color: p.bg),
    ColorRole(key: 'surface', label: 'Surface', token: 'surface', color: p.surface),
    ColorRole(key: 'raised', label: 'Raised', token: 'raised', color: p.raised),
    ColorRole(key: 'border', label: 'Border', token: 'border', color: p.border),
    ColorRole(key: 'text', label: 'Text', token: 'text', color: p.text),
    ColorRole(key: 'muted', label: 'Text muted', token: 'text-muted', color: p.muted),
    ColorRole(key: 'accent', label: 'Accent', token: 'accent', color: p.accent),
    ColorRole(key: 'accentFg', label: 'Accent foreground', token: 'accent-fg', color: p.accentFg),
  ];
}

const List<TypeStep> _desktopType = <TypeStep>[
  TypeStep('Display', 68, 600, 'Hero headline'),
  TypeStep('H1', 48, 600, 'Section header'),
  TypeStep('H2', 38, 600, 'Sub-section'),
  TypeStep('H3', 22, 560, 'Card title'),
  TypeStep('Body', 15, 430, 'Paragraph'),
  TypeStep('Small', 13, 450, 'Meta, labels'),
  TypeStep('Caption', 11.5, 500, 'Eyebrow, badges'),
];

const List<TypeStep> _mobileType = <TypeStep>[
  TypeStep('Display', 34, 600, 'Screen headline'),
  TypeStep('H1', 28, 600, 'Section header'),
  TypeStep('H2', 21, 600, 'Card title'),
  TypeStep('Body', 15, 430, 'Paragraph'),
  TypeStep('Small', 13, 450, 'Meta, labels'),
  TypeStep('Caption', 11, 500, 'Tab labels'),
];

List<TypeStep> typeScale(Item item) =>
    item.device == Device.mobile ? _mobileType : _desktopType;

/// 4px-based spacing scale.
const List<int> kSpacing = <int>[4, 8, 12, 16, 24, 32, 48, 64, 96];

LayoutSpec layoutSpec(Item item) => item.device == Device.mobile
    ? const LayoutSpec(
        container: '390px', columns: 'single column', gutter: '22px',
        radius: '14 / 20px', body: '15px / 1.5')
    : const LayoutSpec(
        container: '1440px', columns: '12 column', gutter: '24px',
        radius: '8 / 12 / 16px', body: '15px / 1.55');

/// What each detected block actually looks like.
const Map<String, String> kBlockNotes = <String, String>{
  'navbar':
      'sticky, hairline bottom border, logo lockup left, four text links, ghost sign-in plus one solid CTA on the right',
  'sidebar':
      '248px fixed column on surface, logo row, seven nav rows each with a small icon square, active row on the raised background, user row pinned to the bottom',
  'hero':
      'centred; small pill eyebrow, two-line headline at display size, one muted sub-line, two buttons side by side, then a large bordered product preview',
  'logo-cloud': 'one centred row of five muted wordmarks at roughly 22% opacity, with a small caption above',
  'cards':
      'three equal bordered cards; each has an accent-tinted icon square, a title, three lines of body and a small accent link',
  'stats': 'four large numerals with small muted labels, hairline rules top and bottom of the band',
  'charts':
      'bar chart with the accent colour for the primary series and a muted secondary series, range toggle top right',
  'table':
      'header row, six body rows, avatar in the first cell, one status pill column, right-aligned numeric column',
  'list': 'rows of avatar plus two stacked lines with a right-aligned value',
  'testimonials': 'single centred quote at 30px on 1.45 line height, avatar and name beneath',
  'pricing':
      'three tiers; the middle tier is emphasised with an accent border and a Popular badge, each has a large price, a button, and a feature list with small dot markers',
  'faq': 'four rows separated by hairlines, each a question with a plus affordance on the right',
  'cta': 'full-width raised band with generous radius, headline and one solid button, centred',
  'footer': 'brand lockup plus four columns of links, hairline rule above',
  'login':
      "centred 380px card; logo, title, two labelled fields, solid submit, 'or' divider, two provider buttons",
  'checkout':
      'two columns; the wider one holds grouped labelled fields and two selectable delivery rows, the narrower one holds the order summary',
  'inputs': 'labelled fields at 46px height with a hairline border and 9px radius',
  'filters': 'single row of pill filters, the first one active on the accent colour',
  'search': 'rounded field on the raised background with a leading icon',
  'tabs': 'segmented control on the raised background, active segment on surface',
  'breadcrumb': 'small muted path with slash separators, the final segment in full contrast',
  'modal': 'centred panel over a dimmed backdrop, close affordance top right',
};

List<Section> sections(Item item) => <Section>[
      for (int i = 0; i < item.blocks.length; i++)
        Section(
          index: i + 1,
          label: item.blocks[i].label,
          type: item.blocks[i].type,
          note: kBlockNotes[item.blocks[i].type] ?? 'standard treatment for this block type',
        ),
    ];

/* ------------------------------------------------------------------ */
/* Responsive rules: "laptop → tablet → mobile". Mirrors what the mock  */
/* renderer draws. The third field lists the block types a rule belongs */
/* to, so a single component shows only the rules that apply to it.     */
/* ------------------------------------------------------------------ */

typedef _Rule = (String label, String rule, List<String> blocks);

const _Rule _webNav = (
  'Navigation',
  'links, sign-in and CTA → links fold into a menu button, sign-in and CTA stay → logo and menu button only',
  <String>['navbar'],
);
const _Rule _webFooter = (
  'Footer',
  'brand beside 4 link columns → brand above 4 columns → brand above a 2 × 2 grid',
  <String>['footer'],
);
const _Rule _gutters = ('Gutters', '56–64px → 32px → 20px', <String>[]);
const _Rule _appNavTabs = (
  'Navigation',
  'labelled left nav → labelled tab bar → icon tab bar',
  <String>['tabs', 'navbar'],
);
const _Rule _appNavNone = ('Navigation', 'none — a single-step flow at every size', <String>[]);

const Map<Archetype, List<_Rule>> _rules = <Archetype, List<_Rule>>{
  Archetype.saasLanding: <_Rule>[
    _webNav,
    ('Hero headline', '68px → 52px → 36px; CTAs side by side → side by side → stacked, full width', <String>['hero']),
    ('Product shot', 'sidebar and 3 stat tiles → narrower sidebar → no sidebar, 2 tiles', <String>['hero']),
    ('Logo cloud', '5 in a row → 5, tighter → 4, wrapping', <String>[]),
    ('Feature grid', '3 columns → 2 (third card spans) → 1', <String>['cards']),
    ('Metrics band', '4 across → 4 across, 34px figures → 2 × 2', <String>['stats']),
    ('Testimonial', '30px quote with wide margins → 26px → 20px, full width', <String>['testimonials']),
    ('CTA band', '38px heading → 32px → 24px', <String>['cta']),
    _webFooter,
    _gutters,
  ],
  Archetype.dashboard: <_Rule>[
    ('Sidebar', '248px with labels → 72px icon rail → hidden behind a menu button, bottom tab bar added', <String>['sidebar', 'navbar']),
    ('Top bar', 'title, 232px search, actions → 180px search → menu button, title, actions', <String>['navbar']),
    ('Stat cards', '4 across → 4 across, 22px values → 2 × 2', <String>['stats']),
    ('Chart + activity', 'side by side → stacked, full width → stacked, 16 bars', <String>['charts', 'list']),
    ('Data table', '5 columns → 4 (category dropped) → stacked rows with amount and status on the right', <String>['table']),
  ],
  Archetype.pricing: <_Rule>[
    _webNav,
    ('Header', '48px → 40px → 30px', <String>['hero']),
    ('Tiers', '3 across → 3 across, tighter → stacked; phones list the first 4 features', <String>['pricing']),
    ('FAQ', 'centred 840px → full width, 64px gutters → 20px gutters', <String>[]),
    _webFooter,
  ],
  Archetype.ecommerce: <_Rule>[
    ('Navigation', 'logo, links, search, icons → menu button, logo, search → menu button, logo, 2 icons', <String>['navbar']),
    ('Campaign hero', 'copy left, product right → same, smaller → product image above copy, full-width CTA', <String>['hero']),
    ('Category row', 'one row → one row → crops at the edge and scrolls', <String>['filters']),
    ('Product grid', '4 columns → 3 → 2', <String>['cards']),
    ('Editorial band', '38px heading → 32px → 24px', <String>['cta']),
    _webFooter,
  ],
  Archetype.portfolio: <_Rule>[
    ('Navigation', '3 links → 3 links → a single “Menu”', <String>['navbar']),
    ('Type statement', '96px → 64px → 38px', <String>['hero']),
    ('Work grid', '2 columns → 2 → 1', <String>['cards']),
    ('Index list', 'full-width rows at every size; titles shorten on phones', <String>['list']),
    _webFooter,
  ],
  Archetype.checkout: <_Rule>[
    ('Layout', 'form beside order summary → same, tighter → summary folds into a “Show order summary” bar above the form', <String>['checkout', 'list']),
    ('Pay button', 'full width of the form at every size', <String>['cta']),
  ],
  Archetype.auth: <_Rule>[
    ('Layout', 'form beside the art panel → form alone, centred, 420px → form alone, full width, top aligned', <String>['login']),
    ('Buttons', 'full width of the card at every size', <String>['cta', 'inputs']),
  ],
  Archetype.editorial: <_Rule>[
    ('Masthead', '54px, 5 sections → 44px, 5 → 32px, 4', <String>['navbar']),
    ('Lead story', '520px image, 46px headline → 380px, 36px → 220px, 26px', <String>['hero']),
    ('Article index', '3 cards in a row → 2 × 2 → thumbnail-left list rows', <String>['list', 'cards']),
    _webFooter,
  ],
  Archetype.docs: <_Rule>[
    ('Layout', 'tree, article, on-this-page → tree and article → article only', <String>['sidebar', 'list']),
    ('Docs tree', '268px → 220px → behind a menu button', <String>['sidebar']),
    ('On this page', 'right-hand rail → hidden → collapsed row under the title', <String>['tabs']),
  ],
  Archetype.agency: <_Rule>[
    ('Navigation', '4 links over the hero → 4 links → menu button', <String>['navbar']),
    ('Hero', '880px tall, 108px headline → 720px, 72px → 600px, 46px; CTA row → row → stacked', <String>['hero']),
    ('Services', '38px names → 30px → 22px', <String>['list']),
    ('Case studies', '2 columns → 2 → 1', <String>['cards']),
  ],
  Archetype.mobileFinance: <_Rule>[
    _appNavTabs,
    ('Balance + actions', 'balance, actions and revenue chart side by side → balance beside a 2 × 2 action grid → stacked (original)', <String>['stats', 'cards']),
    ('Transactions', 'full table → 7-row list in a card → 5-row list (original)', <String>['list']),
    ('Status bar', "none — it's a browser → shown → shown", <String>['navbar']),
  ],
  Archetype.mobileFeed: <_Rule>[
    _appNavTabs,
    ('Feed', 'one 580px column beside a suggestions rail → 2-column grid → one column (original)', <String>['cards']),
    ('Stories', '8 → 11 → 6 (original)', <String>['list']),
  ],
  Archetype.mobileOnboarding: <_Rule>[
    _appNavNone,
    ('Layout', 'split screen, art left, copy and actions right → stacked and centred with wide margins → stacked, full bleed (original)', <String>['hero']),
    ('Headline', '44px, left aligned → 40px, centred → 30px, centred (original)', <String>['hero']),
    ('Primary action', '180px beside the sign-in link → centred, 394px → full width (original)', <String>['cta']),
  ],
  Archetype.mobileProfile: <_Rule>[
    _appNavTabs,
    ('Profile header', 'avatar beside name, stats and edit button → same, smaller → centred avatar, stats below (original)', <String>['stats', 'navbar']),
    ('Grid', '5 columns → 4 → 3 (original)', <String>['cards']),
  ],
};

/// Rules for [item]; a component gets only the rules for its block type,
/// falling back to all of them when none match.
List<ResponsiveRule> responsiveRules(Item item) {
  final List<_Rule> rules = _rules[item.archetype]!;
  final List<_Rule> scoped = item.kind == Kind.component
      ? rules.where((_Rule r) => r.$3.contains(item.componentType ?? '')).toList()
      : rules;
  return <ResponsiveRule>[
    for (final _Rule r in scoped.isNotEmpty ? scoped : rules) (r.$1, r.$2),
  ];
}
