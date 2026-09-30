# Uiverse — Flutter app

Flutter port of the Uiverse web app (Android + iOS). Visual source of truth: `design-system.md` (cited as §N).
Web source (read-only reference, port from here): `C:\Users\LENOVO\Documents\Other Projects\uiverse\uiverse`
— `src/lib/*` (data), `src/components/**` (UI), `src/app/(app)/**` (screens), `src/components/mock/**` (preview renderer).

Where doc and web code disagree: **code wins for data**, **doc wins for visuals**.

## Stack
- Flutter 3.47, Dart 3.13. Riverpod 3 (`flutter_riverpod`), `go_router`, `shared_preferences`.
- Fonts bundled as Latin subsets: `SpaceMono` (400/700, default), `Lexend` Regular (card titles only); see `tool/subset_fonts.md`. No `google_fonts`.
- Icons: add an SVG to `assets/icons`, a value to the `Ui` enum, then run `node tool/gen_icons.mjs`.
- No new packages without asking the orchestrator (note it in your report).

## Shared foundation (do not edit unless you own it)
- `lib/theme/uiverse_colors.dart` — `UiverseColors` ThemeExtension; `context.ui.bg/.surface/.border/.text2/.accent/...`; `UiverseColors.ink`, `.paperBadge` fixed colours.
- `lib/theme/uiverse_text.dart` — `UiText.pageTitle/.sectionHead/.body/.chip/.caption/.meta/...`, `UiText.mono(size, bold:, height:, track:)`, `UiText.tabular`. Styles have no colour: `.copyWith(color: context.ui.text2)`.
- `lib/theme/motion.dart` — `kDur kEase kTransition kFadeUp kFadeIn kSheet`, `Lift.l1..l5`, `hardShadow(d, color)`, `motion(context, d)` (reduced-motion aware), `Bp.sm/md/lg/xl`, `bpColumns(width, base:, sm:, …)`, `context.isWide`, `kLiftOffset`.
- `lib/theme/uiverse_theme.dart` — `uiverseTheme(Brightness)`.
- `lib/widgets/core/` — `InkBox(shadow:, dashed:)`, `LiftOnPress(onTap:, onLiftChanged:)`, `UiIcon(Ui.search, size:, color:, turns:)`, `LogoMark(size:)`, `BoxButton`, `LinkInk` / `TextLink` / `InlineLinkText` (`links.dart`), `SheetIn` / `FadeUp` / `FadeIn` (`entrance.dart`), `bareInput`, `HoverTap` (hover fill, 2px accent focus ring, 48dp min hit, semantics, no ink — the default tappable).
- `lib/data/models.dart` — `Item, Source, Palette, Block, Crop, ArchetypeDef`, enums `Archetype(.slug)`, `Kind`, `Device`, `Viewport(.w/.h/.label/.pick)`, `Tier`.

## Phase 1 APIs (read the files for exact signatures)
- **Data** `lib/data/`: `catalog.dart` (`kItems`, `bySlug`, `screens()`, `components()`, `kSources`, `sourceOf`, `kArchetypes`, `kLayouts`, `kPaletteItems`, `kCreators`), `palettes.dart` (16 palettes, `paletteByKey`, `hexOf`), `taxonomy.dart` (`Tax`, `kCategories`… `kSorts`, `taxName`, `componentGroups`), `query.dart` (`Filters` with web param names, `applyFilters`, `sortItems`, `parseQuery`, `searchItems`, cached `filterCatalog` / `searchCatalog` (use these from screens), `facetCounts`, `similarTo`, `mixFeed`), `spec.dart` (`colorRoles`, `typeScale`, `layoutSpec`, `sections`, `responsiveRules`, `kSpacing`), `prompt.dart` (`ToolId`, `StackId`, `PromptOptions`, `buildPrompt`, `estimateTokens`), `format.dart` (`compact`, `timeAgo`). Web parity tests use `test/data/fixtures/web_reference.json`.
- **State** `lib/state/`: `sharedPreferencesProvider` (must be overridden; tests use `test/shell/app_harness.dart` `pumpApp()` / `test/state/state_harness.dart`), `clockProvider`, `themeModeProvider`, `savesProvider` (+ `SavesState.isSaved/count/savesIn/countIn/collectionName`), `promptQuotaProvider` (`consume/reset/remaining/locked`), `pickFoldedProvider`.
- **Save widgets** `lib/widgets/save/`: `SaveButton(slug, variant: SaveButtonVariant.icon|solid|inline)`, `saveToastProvider`.
- **Shell** `lib/shell/`: `AppShell`, `Navbar`, `Rail`, `BottomNav`, `SearchField.compact()/.big()`, `ThemeToggle`.
- **Router** `lib/router/`: `Routes` path helpers (`Routes.screen(slug)`, `searchFor(q)`, `facets(base, list)`…), `AppRoute` enum, `facetsOf(state)`, `openDetail(context, item)` / `openDetailSlug`. Route→screen table = `buildRoute` switch in `routes.dart` — **only the orchestrator edits it**; agents export screen widgets and state the constructor to wire. Detail screens must not scroll themselves (the presentation wraps them in a scroll view); `DetailPresentation.of(context)` tells overlay vs page.
- **Mock** `lib/mock/mock_screen.dart`: `MockScreen(item:, full: false, viewport:)` (feeds: fixed `item.aspect` crop; detail: `full: true` or a `viewport`, content height), `MockScreen.nativeViewport(item)`. Gallery at `/dev/mock`.

## Rules
- Square corners, 1px ink borders, hard offset shadows only. Never Material ripples/elevation; custom widgets over Material nav/chips.
- Strict analysis (see `analysis_options.yaml`). Explicit return types on public API. No `dynamic` without a comment.
- Tests in `test/` mirroring `lib/`. Unit tests for logic; widget tests by text/semantics. No whole-tree goldens.
- Conventional Commits, small, one logical unit each.
- Only edit directories you own (given in your brief). Need a shared change? Describe it in your final report.
- Done = `flutter analyze` clean + `flutter test` green.

## Data parity (captured from web)
- `ITEMS.length == 181` (68 screens, 113 components).
- First items: `s001-ledgerly-homepage` saves 3747 views 43984 daysAgo 105 hasCode premium aspect 0.4675324675324675;
  `c0011-ledgerly-navbar` 2360/35826/19 crop {y:0,h:0.125}; `c0012-ledgerly-cards` 748/4950/112;
  `c0013-ledgerly-cta` 2561/23688/33; `s002-ledgerly-spend-overview` 4150/16053/140 free aspect 1.5.
- `parseQuery("dark fintech dashboard")` → Style:dark, Industry:fintech, Type(category):dashboard, residual "".
- `searchItems` same query → 5 results: s002-ledgerly-spend-overview, s036-current-accounts, c0361-current-stats, c0021-ledgerly-stats, c0022-ledgerly-table.
- `compact`: 842→"842", 1234→"1.2k", 12345→"12k", 1234567→"1.2M".
