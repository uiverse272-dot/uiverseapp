/*
 * Regenerates web_reference.json from the web app's src/lib/*.ts.
 *   1. Copy src/lib/{data,palettes,prompt,query,spec,taxonomy}.ts and this file to a temp dir.
 *   2. Rewrite relative imports there: from "./x" -> from "./x.ts".
 *   3. node --experimental-strip-types --no-warnings gen_web_reference.mts <path/to/web_reference.json>
 */
import { writeFileSync } from "node:fs";
import { ITEMS, LAYOUTS, PALETTE_ITEMS, CREATORS, compact, timeAgo, bySlug } from "./data.ts";
import { applyFilters, sortItems, parseQuery, searchItems, facetCounts, similarTo, mixFeed } from "./query.ts";
import { buildPrompt, estimateTokens, DEFAULT_OPTIONS, TOOLS, STACKS } from "./prompt.ts";
import { componentGroups } from "./taxonomy.ts";
import { responsiveRules, sections, colorRoles } from "./spec.ts";

const slugs = (xs: { slug: string }[]) => xs.map((x) => x.slug);

const items = ITEMS.map((i) => ({
  id: i.id, slug: i.slug, kind: i.kind, title: i.title, archetype: i.archetype, source: i.source.slug,
  palette: i.palette.key, aspect: i.aspect, category: i.category, industry: i.industry, style: i.style,
  platform: i.platform, device: i.device, componentType: i.componentType ?? null, parentSlug: i.parentSlug ?? null,
  crop: i.crop ?? null, hasCode: i.hasCode, tier: i.tier, has3d: i.has3d, saves: i.saves, views: i.views,
  daysAgo: i.daysAgo, colors: i.colors,
}));

const queries = [
  "dark fintech dashboard", "landing", "minimal pricing page", "mobile bank", "react", "xyz nothing", "",
  "Login", "glass nav", "clean saas homepage", "  moody   crypto  ", "sidebar dashboard", "iphone feed", "next.js",
];
const search = queries.flatMap((q) =>
  [{}, { kind: "screen" }, { kind: "component" }, { sort: "new" }, { style: "light" }].map((extra) => {
    const r = searchItems(q, extra);
    return { q, extra, terms: r.terms, residual: r.residual, results: slugs(r.results) };
  }),
);

const filterCases = [
  {}, { kind: "screen" }, { kind: "component", componentType: "navbar" }, { industry: "fintech", sort: "new" },
  { tech: "tailwind", sort: "saved" }, { platform: "ios", sort: "views" }, { code: "true" }, { tier: "premium" },
  { threed: "true" }, { responsive: "true", device: "mobile" }, { q: "homepage ledgerly" }, { source: "kiln" },
  { category: "dashboard", style: "dark" }, { q: "Care" },
];
const filters = filterCases.map((f) => ({ f, results: slugs(applyFilters(ITEMS, f)) }));

const pick = ["s001-ledgerly-homepage", "c0011-ledgerly-navbar", ITEMS.find((i) => i.device === "mobile" && i.kind === "screen")!.slug,
  ITEMS.find((i) => i.device === "mobile" && i.kind === "component")!.slug,
  ITEMS.find((i) => i.archetype === "pricing")!.slug, ITEMS.find((i) => i.style === "glassmorphism")!.slug,
  ITEMS.find((i) => i.industry === "ai" && i.kind === "component")!.slug, ITEMS.find((i) => i.componentType === "footer")!.slug];

const prompts: { slug: string; opts: unknown; text: string; tokens: number }[] = [];
const add = (slug: string, opts: typeof DEFAULT_OPTIONS) => {
  const text = buildPrompt(bySlug(slug)!, opts);
  prompts.push({ slug, opts, text, tokens: estimateTokens(text) });
};
for (const s of pick) add(s, DEFAULT_OPTIONS);
for (const t of TOOLS) add(pick[2], { ...DEFAULT_OPTIONS, tool: t.id });
for (const st of STACKS) add(pick[1], { ...DEFAULT_OPTIONS, stack: st.id });
add(pick[0], { ...DEFAULT_OPTIONS, includeTokens: false, includeType: false, includeLayout: false, includeSections: false, includeA11y: false });
add(pick[4], { ...DEFAULT_OPTIONS, tool: "cursor", stack: "swiftui", includeA11y: false, includeType: false });

const out = {
  items,
  sorts: Object.fromEntries(["trending", "new", "saved", "views"].map((s) => [s, slugs(sortItems(ITEMS, s))])),
  layouts: LAYOUTS.map((l) => ({ slug: l.slug, name: l.name, example: l.example.slug, uses: l.uses, sections: l.sections.length })),
  paletteItems: PALETTE_ITEMS.map((p) => ({ slug: p.slug, example: p.example.slug, source: p.source.slug, saves: p.saves })),
  creators: CREATORS.map((c) => ({ handle: c.handle, role: c.role, screens: c.screens, followers: c.followers, available: c.available })),
  compact: [0, 5, 842, 999, 1000, 1049, 1050, 1234, 1250, 9999, 9950, 10000, 12345, 12500, 99999, 999999, 1000000, 1234567, 1250000, 25000000].map((n) => [n, compact(n)]),
  timeAgo: [0, 0.5, 1, 6, 7, 13, 29, 30, 59, 364, 365, 800].map((n) => [n, timeAgo(n)]),
  parse: queries.map((q) => ({ q, ...parseQuery(q) })),
  search,
  filters,
  facets: (["industry", "style", "category"] as const).map((k) => ({ key: k, entries: [...facetCounts(ITEMS, k).entries()] })),
  similar: pick.map((s) => ({ slug: s, n8: slugs(similarTo(bySlug(s)!)), n12: slugs(similarTo(bySlug(s)!, 12)) })),
  mix4: slugs(mixFeed(applyFilters(ITEMS, {}))),
  mix3: slugs(mixFeed(applyFilters(ITEMS, { industry: "saas" }), 3)),
  groups: componentGroups().map(([g, l]) => [g, l.map((x) => x.slug)]),
  rules: pick.map((s) => ({ slug: s, rules: responsiveRules(bySlug(s)!), sections: sections(bySlug(s)!).map((x) => x.note), roles: colorRoles(bySlug(s)!).map((r) => r.value) })),
  prompts,
};
writeFileSync(process.argv[2], JSON.stringify(out));
console.log(ITEMS.length, prompts.length);
