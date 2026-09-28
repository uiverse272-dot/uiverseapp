/// Browse taxonomy, ported from web `taxonomy.ts`.
library;

/// One taxonomy entry: URL/query slug plus display name.
/// [group] is only set for component types.
class Tax {
  const Tax(this.slug, this.name, [this.group]);
  final String slug;
  final String name;
  final String? group;

  @override
  String toString() => 'Tax($slug)';
}

const List<Tax> kCategories = <Tax>[
  Tax('landing-page', 'Landing page'),
  Tax('saas', 'SaaS'),
  Tax('dashboard', 'Dashboard'),
  Tax('ecommerce', 'E-commerce'),
  Tax('portfolio', 'Portfolio'),
  Tax('agency', 'Agency'),
  Tax('marketplace', 'Marketplace'),
  Tax('blog', 'Blog'),
  Tax('docs', 'Docs'),
  Tax('pricing', 'Pricing'),
  Tax('checkout', 'Checkout'),
  Tax('auth', 'Login'),
  Tax('onboarding', 'Onboarding'),
  Tax('feed', 'Feed'),
];

const List<Tax> kIndustries = <Tax>[
  Tax('fintech', 'Fintech'),
  Tax('saas', 'SaaS'),
  Tax('ai', 'AI'),
  Tax('healthcare', 'Healthcare'),
  Tax('ecommerce', 'E-commerce'),
  Tax('education', 'Education'),
  Tax('real-estate', 'Real estate'),
  Tax('travel', 'Travel'),
  Tax('fashion', 'Fashion'),
  Tax('food', 'Food'),
  Tax('productivity', 'Productivity'),
  Tax('crypto', 'Crypto'),
];

const List<Tax> kStyles = <Tax>[
  Tax('minimal', 'Minimal'),
  Tax('dark', 'Dark'),
  Tax('light', 'Light'),
  Tax('editorial', 'Editorial'),
  Tax('brutalist', 'Brutalist'),
  Tax('luxury', 'Luxury'),
  Tax('corporate', 'Corporate'),
  Tax('playful', 'Playful'),
  Tax('futuristic', 'Futuristic'),
  Tax('glassmorphism', 'Glassmorphism'),
  Tax('retro', 'Retro'),
];

const List<Tax> kTechnologies = <Tax>[
  Tax('react', 'React'),
  Tax('nextjs', 'Next.js'),
  Tax('tailwind', 'Tailwind'),
  Tax('vue', 'Vue'),
  Tax('svelte', 'Svelte'),
  Tax('webflow', 'Webflow'),
  Tax('framer', 'Framer'),
  Tax('shopify', 'Shopify'),
  Tax('swiftui', 'SwiftUI'),
  Tax('flutter', 'Flutter'),
];

const List<Tax> kComponentTypes = <Tax>[
  Tax('navbar', 'Navbar', 'Navigation'),
  Tax('sidebar', 'Sidebar', 'Navigation'),
  Tax('tabs', 'Tabs', 'Navigation'),
  Tax('breadcrumb', 'Breadcrumb', 'Navigation'),
  Tax('cards', 'Cards', 'Content'),
  Tax('table', 'Table', 'Content'),
  Tax('stats', 'Stats', 'Content'),
  Tax('charts', 'Charts', 'Content'),
  Tax('list', 'List', 'Content'),
  Tax('hero', 'Hero', 'Marketing'),
  Tax('pricing', 'Pricing', 'Marketing'),
  Tax('testimonials', 'Testimonials', 'Marketing'),
  Tax('logo-cloud', 'Logo cloud', 'Marketing'),
  Tax('cta', 'CTA', 'Marketing'),
  Tax('faq', 'FAQ', 'Marketing'),
  Tax('footer', 'Footer', 'Marketing'),
  Tax('login', 'Login', 'Forms'),
  Tax('signup', 'Signup', 'Forms'),
  Tax('checkout', 'Checkout', 'Forms'),
  Tax('search', 'Search', 'Forms'),
  Tax('filters', 'Filters', 'Forms'),
  Tax('inputs', 'Inputs', 'Forms'),
  Tax('modal', 'Modal', 'Interaction'),
  Tax('dropdown', 'Dropdown', 'Interaction'),
  Tax('notification', 'Notification', 'Interaction'),
  Tax('accordion', 'Accordion', 'Interaction'),
  Tax('empty-state', 'Empty state', 'Interaction'),
];

const List<Tax> kPlatforms = <Tax>[
  Tax('web', 'Web'),
  Tax('ios', 'iOS'),
  Tax('android', 'Android'),
  Tax('ipad', 'iPad'),
];

const List<String> kAppCategories = <String>[
  'Finance',
  'Productivity',
  'Social',
  'Health',
  'Shopping',
  'Travel',
  'Education',
  'Media',
];

const List<Tax> kSorts = <Tax>[
  Tax('trending', 'Trending'),
  Tax('new', 'Newest'),
  Tax('saved', 'Most saved'),
  Tax('views', 'Most viewed'),
];

/// Display name for [slug] in [list]; falls back to the slug, then `''`
/// (web `name`).
String taxName(List<Tax> list, String? slug) {
  for (final Tax t in list) {
    if (t.slug == slug) return t.name;
  }
  return slug ?? '';
}

/// Component types grouped by [Tax.group], groups in first-seen order.
List<(String group, List<Tax> types)> componentGroups() {
  final Map<String, List<Tax>> groups = <String, List<Tax>>{};
  for (final Tax c in kComponentTypes) {
    groups.putIfAbsent(c.group!, () => <Tax>[]).add(c);
  }
  return <(String, List<Tax>)>[
    for (final MapEntry<String, List<Tax>> e in groups.entries) (e.key, e.value),
  ];
}
