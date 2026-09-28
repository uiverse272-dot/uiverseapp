# 12 — Design System & Flutter Port Spec

Everything visual about Uiverse, pulled from the current source (post retro-editorial redesign, commit `20ab32f` onward), written so the app can be rebuilt in **Flutter** without opening the web code.

> `docs/05-component-library.md` describes the *old* neutral/grey system (white bg, 6–12px radii, blue focus). It is superseded by this document for all visual decisions. Its architecture notes (Feed engine, Detail shell) still apply.

Source of truth for every value below: `src/app/globals.css`, `src/app/layout.tsx`, `src/components/**`, `src/app/(app)/**`, `src/lib/{palettes,spec,taxonomy,data}.ts`. Units are CSS px = Flutter logical px (dp).

---

## Contents

1. Design language
2. Colour
3. Typography
4. Spacing, sizing & layout grid
5. Borders, corners & elevation
6. Motion
7. Iconography
8. Logo
9. App shell & navigation
10. Components
11. The mock-screen renderer
12. Screens
13. Content & voice
14. Accessibility
15. Theme behaviour & persisted state
16. Flutter implementation appendix

---

## 1. Design language

**Retro-editorial.** The app looks like a printed catalogue or a 90s zine laid out on warm paper: ink hairlines, square plates, monospaced captions, one hot orange and one highlighter yellow.

### Principles

| Principle | What it means in practice |
|---|---|
| Warm paper, not white | Background is cream `#fdf1d6`; surfaces are a lighter cream `#fff7e6`. Dark mode is warm charcoal, never pure black. |
| Ink rules everywhere | Structure comes from **1px solid ink borders** (`--border`, near-black), not from spacing or shadows. The navbar and rail are rows/columns of ruled "cells". |
| Soft rule for lists | Inside a bordered box, rows are divided by the *faint* `--rule` (ink at 22% alpha). |
| Zero radius | `--r-sm/md/lg` are all `0px`. Every box, button, chip, input, popover and dialog is square. **Only exceptions:** the SaveToast check-circle (`rounded-full`) and anything drawn *inside* a mock preview. |
| Hard offset shadow | Elevation is a **solid, un-blurred shadow offset down-right** (`4px 4px 0 ink`). No soft/blurred shadows exist in the shell. |
| One hot colour, one signal | Orange `#f47a2c` = active/selected/primary action. Yellow `#f8dc3d` = the search strip, "Pick of the week", Pro badge, text selection, parse chips. Nothing else is coloured — content (the previews) supplies colour. |
| Mono body | The whole UI is set in **Space Mono**. **Lexend** appears only on card titles. System sans appears only *inside* mock previews. |
| Catalogue captions | Card captions read like index entries: title / source · kind / swatch + "N saves". Section heads are "Bold label ........ more" with an underlined link. |
| Lift on hover | Interactive plates move **up-left 2px** and gain the offset shadow, as if picked up off the page. |

### Do / Don't

- ✅ 1px ink border on every container. ✅ Square corners. ✅ Offset shadow on floating things (menus, toasts, sheets, hovered cards). ✅ Orange fill for the *one* selected/primary thing in a group.
- ❌ Rounded corners. ❌ Blurred drop shadows. ❌ Gradients in the shell (single exception: Explore tile scrim, §12). ❌ Coloured text for decoration. ❌ More than one orange-filled button per cluster.

---

## 2. Colour

### 2.1 Shell tokens

| Token | Light | Dark | Used for |
|---|---|---|---|
| `bg` | `#fdf1d6` | `#1b1915` | Page background, navbar, rail, bottom nav, overlay sheet, dialogs |
| `bg-subtle` | `#f6e4bf` | `#26231d` | Hover fill for every button/row/cell; device-frame backdrop; code-tab active chip; table header |
| `surface` | `#fff7e6` | `#211e19` | Cards/plates, panels, popovers, toast, inputs on detail rail |
| `border` | `#1c1b18` | `#d8caa9` | **All** 1px borders; offset-shadow colour; default `*` border colour |
| `border-strong` | `#000000` | `#f3e6c8` | Hover border on tiles; unchecked checkbox; focused upload input |
| `rule` | `rgba(28,27,24,0.22)` | `rgba(216,202,169,0.22)` | Dividers between list rows inside a box; bottom-nav cell dividers |
| `text` | `#1c1b18` | `#f5ead2` | Primary text, icons |
| `text-2` | `#4d4a42` | `#c3b89e` | Secondary text: subtitles, meta labels, inactive tabs |
| `text-3` | `#7c7667` | `#8e856f` | Tertiary: counts, hints, captions, placeholders |
| `accent` | `#f47a2c` | `#f47a2c` | Selected chip/tab/filter fill, primary button, active nav icon+label, focus ring, count badge, tab underline |
| `accent-fg` | `#1c1b18` | `#1b1915` | Text/icon on accent fill (**dark text on orange**, not white) |
| `signal` | `#f8dc3d` | `#e9cc33` | Navbar search strip, Pick-of-week tab/header, Pro badge, profile avatar tile, parse chips, `::selection` |
| `on-signal` | `#1c1b18` | `#1b1915` | Text/icon on signal |
| `focus` | `#f47a2c` | (same) | 2px focus outline, offset 2px |
| `danger` | `#c2331f` | (same — not overridden) | Reserved; currently unused in UI |
| `overlay` | `rgba(40,30,10,0.45)` | `rgba(0,0,0,0.70)` | Scrim behind detail overlay and prompt dialog |

**Hardcoded (theme-independent) colours** — keep them fixed in Flutter too:

| Where | Value | Why |
|---|---|---|
| Logo mark stroke | `#1c1b18` | Logo always drawn in ink (fill uses `accent`, planet uses `signal`) |
| Card corner badges (Code / 3D / Component) | bg `#fff7e6`, border+icon `#1c1b18` | They sit on top of arbitrary preview colours, so they must not flip in dark mode |
| Pick-of-week header hover | `black @ 10%` (`bg-black/10`) | Darkens yellow |
| Pick-of-week header dividers | `on-signal @ 40%` | |
| Explore tile scrim | `linear-gradient(to top, black@45%, transparent)` at 80% opacity | Only gradient in the app |
| Search placeholder on yellow | `on-signal @ 70%` | |
| Spacing-rhythm bars (Breakdown) | `text @ 15%` | |

### 2.2 Content palettes (preview colours)

Previews are coloured by one of 16 palettes from `src/lib/palettes.ts`. Each palette has roles `bg, surface, raised, text, muted, accent, accentFg, border, chart[4], dark`.

| key | name | bg | surface | raised | text | muted | accent | accentFg | border | chart | dark |
|---|---|---|---|---|---|---|---|---|---|---|---|
| carbon | Carbon | #0B0D10 | #131720 | #1B212C | #F2F5F8 | #8A94A6 | #5B8CFF | #04070D | #222835 | #5B8CFF #3EC9A7 #F5B544 #FF6B6B | ✓ |
| ledger | Ledger | #07100C | #0E1A14 | #15251C | #EAF6EF | #7E9A8B | #37E29A | #04150D | #1B2C22 | #37E29A #7FD4FF #FFD166 #FF8A7A | ✓ |
| violet | Violet AI | #0A0713 | #140E22 | #1E1533 | #F4F0FF | #9A8FBF | #A06BFF | #0A0713 | #241A3B | #A06BFF #6BE3FF #FF7AD9 #FFD36B | ✓ |
| paper | Paper | #FFFFFF | #FAFAF9 | #F4F4F2 | #14110E | #7A736B | #14110E | #FFFFFF | #E7E5E1 | #14110E #A8A29A #D6D2CB #8C7D6B | |
| porcelain | Porcelain | #F7F8FA | #FFFFFF | #EEF1F6 | #0E1420 | #69748A | #2C5CFF | #FFFFFF | #E2E6EE | #2C5CFF #19C39A #FFAE2E #FF5F5F | |
| sand | Sand | #FBF7F0 | #FFFDF9 | #F2EADF | #231C12 | #87786A | #B4571F | #FFF8F0 | #EADFCF | #B4571F #D8A14A #6E7F5B #9C4B3C | |
| ink | Ink | #111111 | #191919 | #232323 | #FAFAFA | #8F8F8F | #FAFAFA | #111111 | #2A2A2A | #FAFAFA #8F8F8F #5A5A5A #3A3A3A | ✓ |
| citrus | Citrus | #FFFDF5 | #FFFFFF | #FFF6DC | #1A1703 | #7E7856 | #FF7A1A | #FFFFFF | #F0E8CC | #FF7A1A #FFC94D #3BB273 #3B6FB2 | |
| ocean | Ocean | #05161F | #0B2231 | #123043 | #EAF7FF | #7FA3B8 | #31C5F5 | #05161F | #17394C | #31C5F5 #5BE0C0 #FFD479 #FF8BA0 | ✓ |
| rose | Rose | #FFF8F9 | #FFFFFF | #FDEDF0 | #2B0F16 | #8C6670 | #E5486E | #FFFFFF | #F6DDE3 | #E5486E #F59BAF #7A5CD1 #3CB9A0 | |
| forest | Forest | #F6F8F5 | #FFFFFF | #E9EFE7 | #101A12 | #63776A | #2E6B47 | #FFFFFF | #DEE6DB | #2E6B47 #7FB08D #C9A227 #4F6D9E | |
| noir | Noir Luxe | #0C0A08 | #151210 | #1E1A16 | #F3EDE4 | #9B8F80 | #C8A96A | #100D0A | #26211B | #C8A96A #8C7A5B #F3EDE4 #5C5142 | ✓ |
| electric | Electric | #08090B | #101216 | #181C22 | #F7F8FA | #858C99 | #C8FF2D | #0B0D07 | #1E232B | #C8FF2D #2DE2FF #FF4D8D #FFB020 | ✓ |
| cloud | Cloud | #FAFBFF | #FFFFFF | #EFF2FD | #0D1024 | #6B7194 | #4B44E8 | #FFFFFF | #E5E8F7 | #4B44E8 #28C2B4 #FFB43D #FF6F91 | |
| concrete | Concrete | #EFEFEC | #FFFFFF | #E3E3DE | #101010 | #6E6E68 | #0F0F0F | #F3F3EF | #D8D8D2 | #0F0F0F #767670 #B4B4AE #E0402F | |
| mint | Mint | #F4FBF9 | #FFFFFF | #E4F5F0 | #06201A | #5F8078 | #00A884 | #FFFFFF | #D7EBE5 | #00A884 #5AC8FA #FFC53D #FF7A85 | |

`paletteByKey(key)` falls back to `carbon`. An item's `colors` strip = `[bg, surface, accent, text, muted]`.

---

## 3. Typography

### 3.1 Families

| Role | Family | Weights loaded | Where |
|---|---|---|---|
| **Body / UI (default)** | **Space Mono** (Google Fonts) | 400, 700 | `body` — every piece of shell text unless stated |
| Display | **Lexend** (Google Fonts, variable) | variable | **Only** card titles (`Card` caption title) |
| Mono (explicit) | Space Mono → `ui-monospace, SFMono-Regular, Menlo` | | `font-mono` uses: hex values, code, token counts, numbered indices |
| Preview sans | `-apple-system, BlinkMacSystemFont, "Segoe UI", Inter, Roboto, "Helvetica Neue", Arial` | | Inside `MockScreen` only — previews must look like real product UIs |

**Weight mapping (important).** Space Mono ships only 400 and 700. The web code uses `font-medium` (500) and `font-semibold` (600) in places; browsers resolve 500→**400** and 600→**700**. Reproduce the *rendered* result in Flutter:

| Tailwind class | CSS weight | Renders as | Flutter `FontWeight` |
|---|---|---|---|
| (none) | 400 | Regular | `w400` |
| `font-medium` | 500 | Regular | `w400` |
| `font-semibold` | 600 | Bold | `w700` |
| `font-bold` | 700 | Bold | `w700` |

### 3.2 Global text settings

- Body letter-spacing: **−0.01em** → Flutter `letterSpacing: -0.01 * fontSize`.
- Default line-height: **1.5** (Tailwind preflight) unless overridden.
- `-webkit-font-smoothing: antialiased`, `text-rendering: optimizeLegibility`.
- Numbers that change or align in columns use **tabular figures** (`tabular-nums`) → `fontFeatures: [FontFeature.tabularFigures()]`. (Space Mono is monospaced anyway; keep the feature for Lexend/sans.)
- Line-height helpers: `leading-tight` 1.25 · `leading-snug` 1.375 · `leading-relaxed` 1.625 · `leading-[1.7]` 1.7.
- Tracking helpers: `-0.03em` (page titles, prices), `-0.02em` (detail title, section titles), `-0.015em` (panel/dialog titles), `tracking-wide` +0.025em (uppercase group labels), `+0.12em` (Pick-of-week eyebrow).

### 3.3 Type scale (every size actually used in the shell)

Frequency = number of occurrences in `src/**/*.tsx` outside the mock renderer.

| Size | Uses | Weight | Line / tracking | Role → examples |
|---|---|---|---|---|
| 48 | 1 | 700 | tracking −0.03em | Only inside Code-tab snippet text (not UI) |
| 38 | 1 | 700 (semibold) | −0.03em | Pricing plan price "£12" |
| 34 | 1 | 700 (semibold) | −0.03em | Pricing page H1 "Simple, honest pricing" |
| **26** | 1 | 700 | leading-tight, −0.03em | **Page title** (`PageHeader` h1) |
| 22 | 1 | 700 (semibold) | −0.02em | 404 title |
| 19 | 1 | 700 | snug, −0.02em | Detail item title (rail h1) |
| 17 | 1 | 700 (semibold) | −0.02em | Explore group heading ("By type") |
| **15** | 8 | 700 | — | **Section head** ("Popular this week"), empty-state title, pricing plan name, big search input text |
| 14.5 | 2 | 400 | relaxed | Pricing intro, legal paragraphs |
| **14** | 17 | 700 or 400 | — | Panel titles (Breakdown/Overview), Pick title, card-tile titles (layouts, palettes, creators), Overview body |
| 13.5 | 16 | 400 / 700 | snug | **Card title (Lexend)**, primary buttons (Save, Open live site), detail tab labels, toast text, profile name |
| **13** | 36 | 400 | — | **Default UI text**: buttons, menu items, search results, Load more, page subtitles (`text-text-2`), chips on Saved/Search |
| 12.5 | 26 | 400 | — | Filter chips/popover items, CopyValue (non-mono), meta lists, secondary buttons |
| 12 | 25 | 400 | — | Small buttons (Pick "Open breakdown"), device toggle, meta rows, hints, "more" links |
| 11.5 | 18 | 400 | — | Captions, notes, counts on tiles, CopyValue mono hex, Pick meta |
| 11 | 11 | 400 | — | **Card meta lines** (source, "N saves"), grid numbers, uppercase group labels (700 + tracking-wide) |
| 10.5 | 8 | 400 / 700 | — | **Rail nav labels**, kbd `⌘K`, "Available" tag, Pick eyebrow (700, uppercase, +0.12em), mono spacing labels |
| 10 | 2 | 400 / 700 | — | **Bottom-nav labels**, "PRO" badge (700, uppercase, tracking-wide) |
| 9.5 | 1 | 700 | tabular | Saved-count badge on navbar bookmark |

### 3.4 Named styles for Flutter

| Name | Size | Weight | Family | Height | Letter-spacing (em) | Colour |
|---|---|---|---|---|---|---|
| `pageTitle` | 26 | 700 | Space Mono | 1.25 | −0.03 | text |
| `pageSub` | 13 | 400 | Space Mono | 1.625 | −0.01 | text-2 |
| `detailTitle` | 19 | 700 | Space Mono | 1.375 | −0.02 | text |
| `groupTitle` | 17 | 700 | Space Mono | 1.5 | −0.02 | text |
| `sectionHead` | 15 | 700 | Space Mono | 1.5 | −0.01 | text |
| `panelTitle` | 14 | 700 | Space Mono | 1.5 | −0.015 | text |
| `bodyLg` | 14 | 400 | Space Mono | 1.625 | −0.01 | text-2 |
| `cardTitle` | 13.5 | 400 | **Lexend** | 1.375 | −0.01 | text |
| `button` | 13.5 | 400 | Space Mono | 1.5 | −0.01 | varies |
| `body` | 13 | 400 | Space Mono | 1.5 | −0.01 | text |
| `chip` | 12.5 | 400 | Space Mono | 1.5 | −0.01 | text |
| `small` | 12 | 400 | Space Mono | 1.5 | −0.01 | text-2 |
| `caption` | 11.5 | 400 | Space Mono | 1.5 | −0.01 | text-3 |
| `meta` | 11 | 400 | Space Mono | 1.5 | −0.01 | text-2 |
| `overline` | 11 | 700 | Space Mono | 1.5 | +0.025, UPPERCASE | text-3 |
| `navLabel` | 10.5 | 400 | Space Mono | 1.5 | −0.01 | text / accent |
| `tabLabel` | 10 | 400 | Space Mono | 1.5 | −0.01 | text / accent |
| `eyebrow` | 10.5 | 700 | Space Mono | 1.5 | +0.12, UPPERCASE | on-signal |
| `badge` | 10 | 700 | Space Mono | 1 | +0.025, UPPERCASE | on-signal |
| `mono` | 11.5 | 400 | Space Mono | 1.5 | −0.01 | text |
| `code` | 12 | 400 | Space Mono | 1.625 | 0 | text-2 |

---

## 4. Spacing, sizing & layout grid

### 4.1 Spacing scale

Tailwind v4 unit = **4px** (`p-1`=4, `p-1.5`=6, `p-2.5`=10, `p-3.5`=14…). Values in actual use:

`2 · 4 · 6 · 8 · 10 · 12 · 14 · 16 · 20 · 24 · 28 · 32 · 36 · 40 · 48 · 64`

Common recipes:

| Recipe | Value |
|---|---|
| Page horizontal gutter | **16** phone / **24** ≥768 (`px-4 md:px-6`); detail view uses 16 / 20 |
| Page header top padding | 28 (`pt-7`), bottom 4 |
| Gap between home sections | 36 (`mt-9`) |
| Section head → content | 12 (`pb-3`) |
| Masonry gap (both axes) | **16** |
| "Popular" grid | column gap 16, row gap 24 |
| Explore tile grid | 12 |
| Panel padding | 20 (`p-5`); small cards 14–16 |
| Chip row gap | 8 |
| Button horizontal padding | 10 (chips), 12–14 (buttons), 16–20 (large) |
| Menu item padding | 14 × 10 (navbar menu), 12 × 8 (filter popover) |
| Feed end / Load more block | 40 vertical |

### 4.2 Fixed dimensions

| Element | Size |
|---|---|
| Navbar height | **64** |
| Desktop rail width | **88** |
| Phone logo cell / theme cell in navbar | 64 / 56 wide |
| Navbar profile cell | min 220 wide; avatar column 64; avatar tile 40×40 |
| Navbar bookmark cell | 64 wide |
| Search field (navbar) | height 40, max width 460 |
| Search field (big, /search) | height 52, max width 620 |
| Bottom nav | height **56** + safe-area inset |
| Chip / filter button / toggle | height **32** |
| Standard button | 36 (h-9), 40 (h-10), **44 (h-11)** for primary CTAs |
| Icon button | 28 (card save), 32 (Pick header, dialog close), 36 (overlay close) |
| Card corner badge | 24×24 |
| Count badge | height 16, min width 16 |
| Colour swatch | 10 (card), 12 (palette list), 16 (detail byline), 28 (colour roles), 36 (creator), 56 (source header) |
| Filter popover | 224 wide, max 320 tall |
| Navbar "More" menu | 192 wide |
| Pick of the week card | `min(340, screenWidth − 32)` |
| Save toast | `min(420, screenWidth − 32)` |
| Prompt dialog | max 1020 × `min(720, 90% height)`; options column 264 |
| Detail rail | 340 |
| Pick thumbnail | 68 wide, 3:4 |
| Source-strip thumbnails (detail) | 112 wide, 3:2 |
| Tab underline | 3px tall, accent |
| Content max widths | 2100 (wide feeds), 1100 (narrow pages), 1700 (detail), 620 (search column) |

### 4.3 Breakpoints

Tailwind defaults: **sm 640 · md 768 · lg 1024 · xl 1280 · 2xl 1536**.

| Width | Shell behaviour |
|---|---|
| < 768 | No rail. Navbar = logo cell + yellow search + theme cell. **BottomNav** fixed at bottom. Main content gets 64px bottom padding. |
| ≥ 768 (md) | Rail (88px) on the left, BottomNav hidden. Navbar shows profile cell + saved cell. |
| ≥ 1024 (lg) | Navbar adds "More" dropdown. `⌘K` hint shows in search. Detail view splits into media + 340 rail; Breakdown grid → 2 columns. |

### 4.4 Feed column counts (`useColumns.ts`)

Based on **full window width** (thresholds already account for the 88px rail):

| Window width ≥ | Masonry columns |
|---|---|
| 1900 | 6 |
| 1540 | 5 |
| 1180 | 4 |
| 760 | 3 |
| 0 | 2 |

Other grids: Popular this week 2 / 3 (sm) / 6 (xl) · Explore tiles 2 / 3 / 4 (lg) / 6 (xl) · Palettes, Layouts, Creators 1 / 2 (sm) / 3 (lg) / 4 (xl) · Detail "Similar" 2 / 3 / 6.

### 4.5 Z-order (lowest → highest)

`StickyBar / popovers 50` → `Navbar, BottomNav 60` → `Pick of the week, search dropdown 70` → `Save toast 80` → `Detail overlay 90` → `Prompt dialog 100`.

---

## 5. Borders, corners & elevation

- **Border width:** always **1px**. Dashed 1px for placeholders (layout skeletons, drop zone, "New collection").
- **Default border colour:** `border` (ink). Every element inherits it (`* { border-color: var(--border) }`).
- **Row dividers inside boxes:** `rule`.
- **Radius:** **0 everywhere**. Only `SaveToast` check icon is a circle.

### Offset-shadow ("lift") scale

All shadows are `x = y = N, blur 0, spread 0`.

| Level | Offset | Colour | Used on |
|---|---|---|---|
| L1 | 2 | border | Logo hover (as drop-shadow on the SVG shape) |
| L2 | 3 | border | Pick tab, Load more hover; **focused navbar search uses 3px in `currentColor`** |
| L3 | **4** | border | Hovered card, popovers, More menu, search dropdown, toast, Responsive-tab tiles hover |
| L3-focus | 4 | **accent** | Card keyboard focus |
| L4 | 5 | border | Pick of the week card |
| L5 | 6 | border | Detail overlay sheet (≥768 only) |

Flutter:

```dart
BoxShadow hardShadow(double d, Color c) =>
    BoxShadow(color: c, offset: Offset(d, d), blurRadius: 0, spreadRadius: 0);
```

---

## 6. Motion

| Token | Value | Flutter |
|---|---|---|
| `--dur` | 140ms | `Duration(milliseconds: 140)` |
| `--ease` | `cubic-bezier(0.2, 0, 0, 1)` | `Cubic(0.2, 0, 0, 1)` |
| Tailwind default transitions (`transition-colors`, `-transform`) | 150ms, `cubic-bezier(0.4, 0, 0.2, 1)` | `Duration(ms:150)`, `Curves.fastOutSlowIn`-like `Cubic(0.4,0,0.2,1)` |

### Keyframes

| Class | Duration | From → To | Used by |
|---|---|---|---|
| `anim-fade-up` | 220ms, ease | opacity 0, translateY(6) → 1, 0 | Save toast, Pick tab |
| `anim-fade-in` | 160ms, ease | opacity 0 → 1 | Popovers, More menu, search dropdown, Pick details |
| `anim-sheet` | 240ms, ease | opacity 0, translateY(24), scale 0.99 → 1, 0, 1 | Detail overlay, prompt dialog, Pick card |

### Micro-interactions

| Interaction | Behaviour |
|---|---|
| Card hover | translate (−2, −2) + L3 shadow, 150ms. Corner badges fade in (opacity 0→1). |
| Logo hover | translate (−2, −2) + 2px hard drop-shadow |
| Load more / Pick tab hover | translateY(−2) (+ L2 shadow on Load more) |
| Buttons / rows hover | background → `bg-subtle` (colour transition 150ms) |
| Primary (accent) button hover | `brightness(1.05)`; Copy-prompt button: opacity 0.9 |
| Close button on overlay hover | fill → accent, icon → accent-fg |
| Nav link hover | text → accent |
| Device frame switch | frame width animates 200ms |
| CopyValue | icon swaps Copy → Check for **1200ms** |
| Copy prompt | label "Copied" for **1400ms** |
| Big search placeholder | rotates example queries every **3200ms** |
| Pick of the week | appears as card **700ms** after load (≥768 only) |
| Search blur | dropdown closes 140ms after blur |

**Reduced motion:** all animations/transitions → 0.01ms. Flutter: check `MediaQuery.of(context).disableAnimations` and use `Duration.zero`.

**Touch equivalent of hover-lift:** on press-down, apply the same (−2,−2) + L3 shadow; release on tap-up/cancel. Keep hover behaviour for desktop/web Flutter targets via `MouseRegion`.

---

## 7. Iconography

Custom inline SVG set in `src/components/ui/icons.tsx`.

- Grid: **24×24 viewBox**, `fill: none`, `stroke: currentColor`, **stroke-width 1.8**, round caps, round joins.
- Sizes in use: 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21. Rail 21, bottom nav 19, navbar 20, buttons 14–15, chips 13.
- Colour always inherits text colour.

| Icon | SVG content (24-grid) | Used for |
|---|---|---|
| Search | circle c(11,11) r7; path `m20 20-3.2-3.2` | Search field, bottom nav |
| Bookmark (+`filled`) | `M6 4h12v16l-6-4.2L6 20z` | Save everywhere; filled = saved |
| Plus | `M12 5v14M5 12h14` | New collection |
| Dots | 3 filled circles r1.4 at x 5/12/19 | (reserved) |
| External | `M13 5h6v6` `M19 5 10 14` `M19 13v6H5V5h6` | Open live site |
| Close | `M6 6l12 12M18 6 6 18` | Close / Clear / remove chip |
| Chevron | `m6 9 6 6 6-6` (down) | Menus, popovers; rotated 180° for "expand" |
| ArrowLeft / ArrowRight | `M19 12H5M11 6l-6 6 6 6` / `M5 12h14M13 6l6 6-6 6` | (reserved) |
| Code | `m9 8-4 4 4 4M15 8l4 4-4 4` | Code badge, Code action |
| Sparkle | 4-point star + small star | Prompt, 3D badge, Pick of the week |
| Grid | 4 squares 7×7 rx1.4 | Rail "Parts" |
| Home | `M4 11 12 4l8 7` `M6 10v9h12v-9` | Nav |
| Compass | circle r8.2 + needle | Nav Explore |
| User | head r3.4 + shoulders arc | Profile |
| Sun / Moon | | Theme toggle (shows the *target* theme's icon) |
| Filter | `M4 6h16M7 12h10M10 18h4` | Filter bar lead |
| Layers | two chevron-diamonds | Component badge, Breakdown action |
| Copy | rect 11×11 rx2 + corner | CopyValue |
| Check | `m5 12.5 4.5 4.5L19 7` | Selected option, copied, pricing ✓ |
| Monitor | screen + stand | Nav Web |
| Phone | rect 10×17 rx1.6 + speaker | Nav Apps |
| Layout | square + header + sidebar | Nav Layouts |
| Palette | palette blob + 3 dots | Nav Palettes |
| Upload | arrow up + tray | Nav Upload |

**Flutter:** copy each path into an `.svg` asset (same viewBox/stroke) and render with `flutter_svg`, tinting via `ColorFilter.mode(color, BlendMode.srcIn)`. Don't swap for Material/Cupertino icons — stroke weight and rounded joins are part of the look. Closest off-the-shelf fallback: **Lucide** at stroke 1.8.

---

## 8. Logo

"The U cradling a planet: UI + universe." Source: `LogoMark` in `Sidebar.tsx` and `src/app/icon.svg`.

```svg
<svg viewBox="0 0 32 32">
  <rect x="1" y="1" width="30" height="30" fill="#f47a2c" stroke="#1c1b18" stroke-width="2"/>
  <path d="M9 7v11a7 7 0 0 0 14 0V7" fill="none" stroke="#1c1b18" stroke-width="4.5" stroke-linecap="square"/>
  <circle cx="16" cy="17.5" r="3" fill="#f8dc3d" stroke="#1c1b18" stroke-width="1.5"/>
</svg>
```

- Orange square tile, 2px ink border, thick ink "U" (square caps), yellow planet with ink ring in the bowl of the U.
- In-app fill uses `accent`, planet uses `signal` (so dark-mode signal `#e9cc33` applies); strokes are always `#1c1b18`.
- Sizes: 34 (rail/navbar cell, centred in a 64-tall cell), 56 (404 page). App icon: use `icon.svg` / `apple-icon.png` → generate Flutter launcher icons with `flutter_launcher_icons`.

---

## 9. App shell & navigation

### 9.1 Phone (< 768)

```
┌──────┬──────────────────────────────┬─────┐  64
│ LOGO │ ▓▓ [🔍 Site, component…   ] ▓▓ │ ☾  │  ← yellow strip
├──────┴──────────────────────────────┴─────┤
│                                           │
│               page content                │
│                                           │
├────────┬────────┬────────┬────────┬───────┤  56 + safe area
│  Home  │Explore │ Search │ Saved  │Profile│
└────────┴────────┴────────┴────────┴───────┘
```

### 9.2 Tablet / desktop (≥ 768)

```
┌──────┬──────────────────────────┬────────┬───────────────────┬─────┐ 64
│ LOGO │ ▓▓ [🔍 …           ⌘K] ▓▓ │ More ▾ │ [👤] Guest      ›  │  🔖3 │
├──────┼──────────────────────────┴────────┴───────────────────┴─────┤
│ Home │                                                             │
│Explore                                                             │
│ Web  │                      page content                          │
│ Apps │                                                             │
│ Parts│                                                             │
│Layouts                                                             │
│Palettes                                                            │
│ Saved│                                                             │
│      │                                                             │
│Upload│                                                             │
│Profile                                                             │
│ Dark │                                                             │
└──────┴─────────────────────────────────────────────────────────────┘
  88
```
("More" only ≥1024.)

### 9.3 Navbar (`Navbar.tsx`)

A row of **ruled cells**, sticky, 64 tall, `bg`, bottom border. Cells are separated by 1px vertical ink borders.

1. **Logo cell** (phone only): 64 wide, right border.
2. **Search cell**: flex-1, **`signal` background**, `on-signal` text, padding 12 (phone) / 20. Contains `SearchField` (max 460).
3. **More** (≥1024): button "More ▾", 13px, padding 20; menu below right edge: 192 wide, `surface`, border, L3 shadow, items 13px 14×10 padding separated by `rule`: **3D, Creators, Pricing, Upload**. Closes on outside tap.
4. **Profile** (≥768): min 220; left 64-wide column on `surface` holding a 40×40 **yellow** tile with 20px User icon; then name "Guest" (13.5 bold) + subline (11, text-2) = "N saved" or "Interface seeker"; chevron 15 on the right. Hover `bg-subtle`.
5. **Saved** (≥768): 64 wide, Bookmark 20. Count badge top-right (top 14, right 12): 16 tall, orange fill, ink border, 9.5px bold, shows "99+" above 99.
6. **Theme** (phone only): 56 wide cell, icon 19.

### 9.4 Rail (`Sidebar.tsx`)

88 wide, full height, sticky, `bg`, right border. Logo cell (64 tall) with bottom border. Nav column padding-y 16, gap 4. Each item: icon 21 above label 10.5, gap 6, padding-y 10, centred. **Active = accent icon + label**; inactive = text, hover → accent. No background highlight.

- Main: Home `/`, Explore, Web, Apps, **Parts** (`/components`), Layouts, Palettes, Saved.
- Footer: Upload, Profile, Theme toggle ("Dark"/"Light" label + Moon/Sun).
- Active rule: `/` exact; others match path or path prefix.

### 9.5 BottomNav (`BottomNav.tsx`)

Fixed bottom, `bg`, top ink border, 56 tall + `safe-area-inset-bottom`. Five equal cells divided by **`rule`** vertical lines: **Home, Explore, Search, Saved, Profile**. Icon 19 over label 10, gap 4. Active = accent. Upload deliberately excluded (<2% of sessions).

**Flutter:** build these as custom widgets (Material `NavigationBar`/`NavigationRail` fight the square, ruled look). Use `LayoutBuilder` on width ≥ 768 to swap `BottomNav` for `Rail`.

---

## 10. Components

States legend: **rest / hover (pointer) / pressed (touch) / focus / selected / disabled / empty**.

### 10.1 SearchField (`SearchCommand.tsx`)

| | Compact (navbar) | Big (/search page) |
|---|---|---|
| Height | 40 | 52 |
| Container | 1px `on-signal` border, transparent on yellow, padding-x 12 | 1px border, `surface`, padding-x 16 |
| Icon | Search 18 | Search 19 |
| Text | 13 | 15 |
| Placeholder | "Site, component, style, or industry" at on-signal 70% | "Try: {example}" rotating every 3.2s, text-3 |
| Kbd hint | `⌘K` box, 10.5px, 1px current-colour border, ≥1024 only | none |
| Focus | 3px hard shadow in current colour | same |

Examples rotated: *dark fintech dashboard · minimal saas pricing section · luxury ecommerce landing page · ios onboarding flow · editorial blog layout*.

**Dropdown** (while focused and non-empty): 6px below, full width, `surface`, border, L3 shadow, padding 8, fade-in. Optional row "Reading as" (11.5 text-3) + yellow parse chips (`dimension: label`, 11px, border). Then one action row: Search icon 14 (text-3) + "Search for **“query”**" 13px, hover bg-subtle.

Shortcuts (desktop): `/` or `Ctrl/⌘+K` focuses. Submit → `/search?q=`.

### 10.2 Card (feed plate) (`Card.tsx`)

```
┌─────────────────────┐  ← 1px border, surface, padding 6 ("mat")
│┌───────────────────┐│
││ [PRO]             ││  ← inner 1px border, preview (MockScreen)
││                   ││
││         [</][✦][≡]││  ← badges bottom-right, hover only, ≥768
│└───────────────────┘│
└─────────────────────┘
  Card title in Lexend 13.5, max 2 lines            (mt 10, pr 32)
  Source name · component      (11, text-2, 1 line)
  ■ 1.2k saves                 (11, tabular; 10px swatch = palette accent)
                                               [🔖]  ← SaveButton icon, bottom-right
```

- Aspect from `item.aspect` (or `crop` prop, e.g. 3/4 on "Popular").
- **Hover/press:** plate translates (−2,−2) + L3 shadow; badges fade in. **Focus:** L3 shadow in accent.
- **PRO badge** (premium): top-left inset 6, `signal` bg, `on-signal` 1px border, 10px bold uppercase, padding 6×2.
- **Corner badges:** 24×24, fixed `#fff7e6` bg / `#1c1b18` border+icon, icon 12, gap 4, inset 6: Code (hasCode), Sparkle (has3d), Layers (component). Hidden on phones.
- Tap → `/component/{slug}` or `/screen/{slug}` (opens as overlay from a feed).

### 10.3 SaveButton (`SaveButton.tsx`)

| Variant | Look | Saved state |
|---|---|---|
| `icon` | 28×28, Bookmark 17, no border | icon filled, accent colour. Hover → accent. aria "Save"/"Remove from saves". |
| `solid` | height 44, full width in rail, border, padding-x 16, 13.5px, Bookmark 15 + "Save" on **accent fill** | switches to `surface` fill + "Saved" + filled icon |
| `inline` | text button 13px text-2, icon 14 | "Saved" + filled icon |

Toggling always shows the SaveToast.

### 10.4 SaveToast (`SaveToast.tsx`)

Fixed, horizontally centred, bottom 80 (phone, above BottomNav) / 28 (≥768). Width `min(420, w−32)`. `surface`, border, padding 12, L3 shadow, fade-up.

- **Default row:** 24px **circle** accent with Check 13 · text 13.5 ("Saved to Recently saved" / "Removed") · "Move to…" button (border, 12.5, 10×6 padding; only after a save) · "Dismiss" (12.5 text-3).
- **Picking:** label "Move to collection" (12, text-3) · list of collections (13px rows, max 208 tall, scroll) · top-ruled input row with Plus 14 and placeholder "New collection…". Enter creates + moves.
- Toast has no auto-dismiss timer in code; it persists until dismissed or replaced.

### 10.5 Chips & filters (`FilterBar.tsx`)

Everything is 32 tall, 1px border, square, 12.5px text.

| Widget | Rest | Selected |
|---|---|---|
| **ChipRail** chip (home categories) | `surface` bg, padding-x 12 | accent fill, accent-fg |
| **Popover trigger** (Type, Industry, Style, Tech, Device, sort) | transparent, padding-x 10, label + Chevron 13 | accent fill, shows the chosen option's name |
| **Toggle** ("Code") | transparent, padding-x 10 | accent fill |
| **Clear** | underlined link (`link-ink`), Close 13 + "Clear", 12px | shown only when any filter active |

FilterBar row: horizontal scroll (scrollbar hidden), gap 8, padding-y 10. Leading Filter icon 14 (≥768). Sort popover pushed right (`ml-auto`), default label "Trending".

**Popover panel:** 36px below trigger, 224 wide, max 320 tall, `surface`, border, L3 shadow, fade-in. Options: 12.5px, padding 12×8, `rule` dividers, Check 13 on the current value; hover bg-subtle. Close on outside tap / Esc. Tapping the selected option again clears it.

Home chips: For You · Trending · New · Web · Mobile · Components · Dashboard · SaaS · Fintech · E-commerce · Portfolio · Dark · Minimal · 3D.
Sorts: Trending · Newest · Most saved · Most viewed.

**Flutter:** popovers → `MenuAnchor`/custom overlay on desktop, **bottom sheet** on phones (same square/ink styling).

### 10.6 Section primitives (`Section.tsx`)

- **PageHeader:** title (pageTitle), optional sub (13, text-2, max 576 wide, mt 8), optional right slot (e.g. "124 results", 13 text-3 tabular). Padding top 28, bottom 4; wraps.
- **SectionHead:** "**Title** ............ more" — 15 bold left, `link-ink` 12px right, baseline aligned, pb 12.
- **Shell:** centred container, padding-x 16/24, max 2100 (wide) or 1100.
- **StickyBar:** sticks at **top 64** (under navbar), `bg`, bottom border, z 50.
- **link-ink:** underline, 1px thickness, 3px offset; hover → accent.

### 10.7 Feed & Masonry (`Feed.tsx`, `Masonry.tsx`)

- Page size **28**, auto-loads up to **5 pages** via a sentinel 1200px before the end, then a **"Load more"** button (border, surface, 13px, 20×10 padding; hover lift −2 + L2 shadow).
- End: "{n} results · end of feed" (12.5, text-3, centred, padding 40).
- **Empty:** centred in 46% viewport height: "Nothing matches those filters" (15 bold) + "Try removing a filter, or browse Explore to start from a category instead." (13 text-2, max 384).
- **Masonry algorithm:** shortest-column-first using precomputed height `1/aspect + 0.14` (caption allowance). No DOM measuring, appended items never move. Gap 16.

**Flutter:** `flutter_staggered_grid_view` `MasonryGridView.count(crossAxisCount: cols, mainAxisSpacing: 16, crossAxisSpacing: 16)` — or port the deterministic column assignment directly into a `Row` of `Column`s for zero-shift behaviour.

### 10.8 Pick of the week (`Featured.tsx`)

Floating over the home feed, bottom-right (right 16 / bottom 80 on phone; 24/24 ≥768), z 70. Three modes, fold state persisted (`uiv.pick` = `"tab"`):

1. **Tab** (default on phones / when folded): yellow button, border, L2 shadow, Sparkle 14 + "Pick of the week" 12px bold. Hover lifts −2. Tap → card.
2. **Card** (auto-opens 700ms after load on ≥768): width `min(340, w−32)`, `surface`, border, **L4 shadow**, sheet animation.
   - Header strip: yellow, bottom border, eyebrow "✦ PICK OF THE WEEK" (10.5, bold, uppercase, +0.12em); two 32×32 icon buttons divided by on-signal@40% lines: expand (Chevron, rotated when collapsed) and close (fold to tab). Hover black@10%.
   - Body (padding 12, gap 12): 68px 3:4 thumbnail in a mat (bg, border, 2px padding, inner border); title 14 bold (hover accent); "By: *Source*" 11.5 with link-ink; domain 11.5 text-2; bottom row: **"Open breakdown"** (32 tall, accent fill, 12px, flex) + 32×32 bordered SaveButton.
3. **Open**: card + details below top border, max 45% screen height, scroll: definition list (76px label column, 11.5; Saves, Type, Industry, Style, Stack, Captured) with `rule` bottom, then about text 12px line-height 1.7. Esc → card.

### 10.9 Detail view (`DetailView.tsx`)

Layout: max 1700, padding 16/20, top 20. ≥1024: `[media | 340 rail]`, gap 24; rail sticky at top 80.

**Media column**
- Top bar: **device segmented control** — bordered group with 2px padding, gap 4; segments "Laptop · Tablet · Mobile" 12px, padding 10×4; selected = accent fill; others text-2. Right: "Captured 3w ago · 12k views" (12, text-3).
- Frame: `bg-subtle` backdrop, border, padding 12/20; inner bordered viewport max 76% screen height, scrolls internally. Tablet/phone frames draw at real width (834/390) capped to column; laptop fills. Width animates 200ms.
- Caption under frame (11.5, text-3, centred): "Laptop · 1440 × 900 · original design · scroll inside the frame" or "adapted from the laptop design".
- Screens only: horizontal strip of up to 6 sibling screens (112 wide, 3:2). Current one has a `text`-coloured border; others hover → border-strong.

**Rail**
- Title (detailTitle). Byline: 16px swatch (palette accent) + "By: *Source*" (12.5, link-ink).
- Buttons (gap 12, mt 20): **Open live site** (44, surface, border, External 15, 13.5) and **Save** (solid SaveButton).
- Action trio: 3-column bordered strip, columns separated by borders: Prompt (Sparkle) / Code / Breakdown (Layers) — icon 19 over 11px label, padding-y 14, hover bg-subtle.
- Meta list (top+bottom ink border, padding-y 6): 88px label column (12, text-2) / value (12). Type, Industry, Style (linkable, hover accent), Platform, Stack, Saves.
- About paragraph (12.5, relaxed). Tag chips (11.5, border, 8×4, text-2; hover bg-subtle + text).
- Footer note (11.5, text-3, top border): "Preview rendered from the capture…" + underlined "attribution policy".

**Tabs** (below, mt 32): Overview · Breakdown · Responsive · Code · Similar. 13.5px, padding 12×10, horizontal scroll on phones. Selected = text + **3px accent underline** at bottom; others text-2. Bottom border across the strip. Content padding-y 24. Unless on Similar, a "Similar designs" / "Related components" section (15 bold) with a 6-up card grid follows.

**Tab contents**
- *Overview:* 2 panels (1.4fr / 1fr ≥1024). "What this screen does" (14 bold title, 14 text-2 relaxed body, bulleted "· " list 13.5). "Palette": 64-tall strip of the 5 colours in a bordered box + CopyValue chips.
- *Breakdown:* see 10.10.
- *Responsive:* three bordered tiles (grid 1.9fr / 1.25fr / 0.75fr ≥768) each with label (13 bold) + "1440px · original" (11 text-3) and the viewport's first screen at true aspect; hover lift + L3 shadow; tap switches device and scrolls to frame. Then "How it adapts" panel: subtitle "Laptop → tablet → mobile", definition rows (160px label column ≥640) divided by `rule`.
- *Code (none):* panel with Code icon 18, "No code for this capture" (14 bold), policy text (13.5 text-2), button "✦ Generate an implementation prompt instead" (36, border, 13).
- *Code (available):* bordered box; header row with fake tabs React (bg-subtle) / HTML / Tailwind (text-3), licence tag "MIT · contributed" (mono 10.5, border), Copy button; `pre` mono 12 text-2 padding 16.

### 10.10 Breakdown (`Breakdown.tsx`)

2-column grid ≥1024, gap 16. **Panel** = `surface`, border, padding 20; header row: title 14 (bold, −0.015em) + note 11.5 text-3, pb 16.

1. **Section outline** ("N blocks detected"): rows padding 8, gap 12, hover bg-subtle: `01` (mono 11 text-3) · 40×24 bordered swatch · label 13 · block type (mono 11 text-3).
2. **Derived layout** ("the page as a reusable structure"): stacked **dashed** boxes with label (11.5 text-2), heights 32 default / 58 hero / 40 footer; link "Save as a layout →".
3. **Colour roles** ("extracted from computed styles"): 28px swatch · role label 12.5 · CopyValue hex. Then buttons "Copy as CSS variables" / "Copy as Tailwind theme".
4. **Type scale:** 64px label column (11.5 text-3) · sample text at min(size, 26) · CopyValue "68px / 600".
5. **Spacing rhythm** ("4px base"): bars `text@15%` width min(s,40), height 26 for 4·8·12·16·24·32·48·64·96 with mono 10.5 labels; then 2×2 facts: Radius, Grid, Body, Container.

### 10.11 CopyValue (`CopyValue.tsx`)

Inline button, padding 6×4, hover bg-subtle. Mono variant 11.5 (hex), plain 12.5 (labels). Trailing Copy icon 12 (text-3) **visible on hover only**; after copy shows Check for 1.2s. Often wrapped with a border to look like a chip. On touch, always show the icon.

### 10.12 Overlay (detail as modal) (`Overlay.tsx`)

Opening a detail from a feed keeps the feed underneath. Full-screen scrim `overlay`, scrollable; sheet max 1700 wide, `bg`, border, L5 shadow (≥768), padding 0 (phone) / 24 margin (≥768), sheet animation. Close: sticky 36×36 bordered button top-right (hover accent fill), Esc, or tapping the scrim. Body scroll locked.

**Flutter:** phone → full-screen route with slide/fade-up (`anim-sheet`); tablet+ → `showGeneralDialog` with the scrim colour and the square sheet. Deep links open the standalone page.

### 10.13 Prompt dialog (`PromptDialog.tsx`)

Scrim + centred sheet, max 1020 × min(720, 90% h); full screen on phones. `bg`, border, square.

- Header (border-bottom, 16×12): Sparkle 16 text-3 · "Generate implementation prompt" (14 bold) · "{title} · {source}" (12 text-3) · close 32×32.
- Left options (264 wide ≥768, right border; stacked above on phone), groups with overline labels (11 bold uppercase text-3):
  - **Target tool** list: Claude, ChatGPT, Cursor, Codex, v0, Lovable, Bolt — name 13 + hint 11; selected = accent fill (hint at 70%).
  - **Stack** chips: Next.js + Tailwind, React + Tailwind, HTML + CSS, Vue + Tailwind, SwiftUI — 12.5, border; selected accent.
  - **Include** checkboxes: Section breakdown, Colour tokens, Type scale, Layout & responsive, Accessibility requirements — 16×16 square box; checked = accent fill + Check 11; unchecked = border-strong.
- Right: editable mono textarea (12, relaxed, padding 16). Editing is discarded when options change.
- **Locked** (3 free/month used): centred "You've used your 3 free prompts this month" (15 bold), explanation (13.5 text-2), "See Pro" (accent), "Reset counter (demo only)" link.
- Footer (top border): "~1,234 tokens · 2 of 3 left this month" (11.5 text-3) · inline Save · **Copy prompt** (36, accent fill, Copy 14; → "Copied" 1.4s; disabled 40% opacity). Tokens estimated as `ceil(chars/4)`.

### 10.14 Other small patterns

| Pattern | Spec |
|---|---|
| Segmented tabs as links (Search kinds, Source tabs, Saved collections) | 13px, padding 10×6 (Saved: h32, border, 14 px-x); selected = accent fill; others text-2; count suffix at 60% opacity, tabular |
| Parse chips (search) | "dimension: label ✕", 12px, border, bg-subtle, 8×4, hover border-strong |
| Tag chip | 11.5–12px, border, 8×4, text-2 |
| Dashed "add" button | h32, dashed border, Plus 14 + label, text-2 |
| Divider with text | hairline flex lines either side of "or drop an image" (12.5 text-3) |
| Inputs | h44, border, bg-subtle, padding-x 14, 14px, focus → border-strong; placeholder text-3 |
| Drop zone | h112, dashed border, centred 13px text-3 |
| Table (pricing) | border box; header row bg-subtle 13px text-3 first col; rows 16×10 padding, bottom border; ✓ rendered as Check 14 |
| "Popular" badge | accent fill, 11px bold, 8×2 |
| Available tag | border, 10.5px, text-2 |
| Kbd | border currentColor, 10.5, 6×2 |

---

## 11. The mock-screen renderer

Uiverse ships **no screenshots**. Every preview is drawn procedurally by `MockScreen` from an item's *archetype* + *palette*. Your Flutter app either ports this renderer or replaces it with real images from a backend. If porting:

### 11.1 Units

Designs are authored in pixels at a design width `W` (laptop 1440, tablet 834, mobile 390). Everything is converted to a fraction of the container width:

```
u(n) = n / W * containerWidth
```

Flutter: wrap in `LayoutBuilder`, `final u = (double n) => n / W * c.maxWidth;`. The preview's height is `width / item.aspect` in feeds (fixed aspect, crop overflow like a screenshot, `ClipRect`), or content height (min one screen) in the detail frame.

### 11.2 Viewports

| Key | Label | W × H |
|---|---|---|
| desktop | Laptop | 1440 × 900 |
| tablet | Tablet | 834 × 1194 |
| mobile | Mobile | 390 × 844 |

`pick(vp)(desktop, tablet, mobile)` chooses per-viewport values; sections **reflow**, never scale.

### 11.3 Primitives (`primitives.tsx`)

| Primitive | Behaviour |
|---|---|
| `B` | Box: w, h, radius r, bg, 1u border, grow |
| `Row` / `Col` | Flex with gap (in u), align, justify, wrap, grow |
| `T` | Text: size, weight (e.g. 450, 520, 560, 600), colour; line-height 1.16; tracking −0.028em if size > 40 else −0.011em |
| `Line` / `Lines` | Placeholder text bars: height 10, radius 3, colour at opacity 0.15–0.18; last line 60% width |
| `Circle` | radius 999 |
| `Btn` | Pill/rect button: default 132×44, r8, label 15/520 |
| `Grid` | equal columns |
| `Burger` | 3 bars, s=22 |
| `noise(a,b)` | Deterministic integer hash → 0..1 (chart bar heights). Port exactly for identical output. |

Variable font weights like 450/520/560 → Flutter `FontWeight.values` nearest (w500/w500/w600) or use a variable sans with `FontVariation('wght', 450)`.

### 11.4 Archetypes → sections

| Archetype | Design size | Device | Section stack |
|---|---|---|---|
| saas-landing | 1440×3080 | desktop | Navbar, Hero (+AppPreview), LogoCloud, FeatureGrid, StatsBand, Testimonial, CtaBand, Footer |
| dashboard | 1440×960 | desktop | Sidebar, TopBar, StatCards, ChartPanel, ActivityList, DataTable (phone: TopBar…TabBar) |
| pricing | 1440×1360 | desktop | Navbar, SectionHeader, BillingToggle, PricingTiers, Faq, Footer |
| ecommerce | 1440×2120 | desktop | ShopNav, CampaignHero, CategoryRow, ProductGrid, CtaBand, Footer |
| portfolio | 1440×2110 | desktop | MinimalNav, TypeStatement, WorkGrid, IndexList, Footer |
| checkout | 1440×900 | desktop | slim header, CheckoutForm + OrderSummary (phone: OrderSummaryBar above form) |
| auth | 1440×900 | desktop | AuthCard + AuthArt (art laptop only) |
| editorial | 1440×1650 | desktop | Masthead, LeadStory, ArticleIndex, Footer |
| docs | 1440×1020 | desktop | DocsSidebar, DocsBody, DocsToc (tablet: no TOC; phone: DocsMobileBar) |
| agency | 1440×2830 | desktop | AgencyHero, ServicesList, WorkGrid, CtaBand |
| mobile-finance | 390×844 | mobile | StatusBar, Greeting, BalanceCard, QuickActions, TxnList, TabBar |
| mobile-feed | 390×844 | mobile | StatusBar, Stories, Posts, TabBar |
| mobile-onboarding | 390×844 | mobile | StatusBar, OnboardingArt, headline, Dots, CTA (no tab bar) |
| mobile-profile | 390×844 | mobile | StatusBar, ProfileStats, Segments, Tiles, TabBar |

Mobile apps on laptop become a web app with `AppSideNav` (240 wide). Component items render one block alone (`BlockOnly`); types `login, checkout, sidebar, charts, list` fill the frame.

The per-archetype responsive rules shown in the Responsive tab live in `src/lib/spec.ts → RULES` and must stay in step with the section code.

---

## 12. Screens

Route → Flutter screen. "Feed page" = PageHeader + StickyBar(FilterBar) + Feed.

| Route | Purpose | Layout & components | Notes |
|---|---|---|---|
| `/` Home | Discovery feed | padding 16/24, top 24. "Categories" SectionHead + ChipRail. If no chip: "Popular this week" (6 Cards, crop 3:4, grid 2/3/6). "Recommended for you ... more" or "{Chip} · N results ... clear" + Feed. **Pick of the week** floating. | Chip state in `?chip=`. Feed mixes components into screens (`mixFeed` every 4) except the Components chip. |
| `/explore` | Directory, not a feed | PageHeader + groups: By type, By component ("cropped from real screens"), By industry, By style, By technology, By platform. Group title 17 bold + note 12.5 text-3. Tiles: 4:3 preview on bg-subtle with **bottom black gradient scrim**, label 13 + count 11.5 tabular; border, surface; hover border-strong. Empty groups hidden. | Each tile links to a filtered feed. |
| `/web/[...facet]` | Websites feed | Feed page. Title "{Facet} websites" or "Websites". Filters: Type, Industry, Style, Tech, Device. | Path facets (`/web/saas/dark`) resolve to filters. |
| `/apps/[...facet]` | Mobile app UI | Feed page. "Mobile & app UI". Filters: Platform, Screen, Category, Style. | |
| `/components/[...facet]` | Component crops | Feed page. "Components". Filters: Component, Industry, Style, Framework. | |
| `/screen/[slug]`, `/component/[slug]` | Detail | DetailView (§10.9). From a feed → Overlay (§10.12). | |
| `/search` | NL search | Big SearchField centred (max 620, top 32). No query: "Try a natural-language query" (13 bold text-3) + suggestion chips (13, border, 12×6) + explainer. With query: StickyBar with kind tabs (All / Designs / Components + counts), "Reading as" removable parse chips, "+ “residual” as free text"; Feed. | |
| `/saved` | Saves & collections | PageHeader "Saved". Collection pills (All + each, counts) + dashed "New collection" (inline input on tap). Feed or empty state: "Nothing saved here yet" / "Tap the bookmark under any card to save it here." / "Browse the feed" button. | Client-side persisted. |
| `/palettes` | Palette cards | Grid 1/2/3/4. Card: 112-tall 5-band strip (bg, surface, raised, accent, text); name 14 bold + saves; "from {source}"; 2-col hex list with 12px swatches + CopyValue; "CSS vars" / "Tailwind" copy buttons. | |
| `/layouts` | Section skeletons | Grid 1/2/3/4. Card: name + "N uses"; 80-wide dashed skeleton column beside a 0.8-aspect preview; numbered section links; "Duplicate" / "Open in builder" buttons. Footer note about Phase 3 builder. | |
| `/3d` | 3D & motion feed | PageHeader + Feed filtered `has3d`. | Reached via More menu. |
| `/creators` | Creator directory | Grid 1/2/3/4. Card: 36 swatch, name 14 bold, role 12 text-3, optional "Available" tag, 3 mini previews (1.1 aspect), "N screens · N followers". | |
| `/source/[slug]` | One product's system | 56 swatch + PageHeader (name, about) + chips (domain, industry, tech) + "· N saves across N items". StickyBar tabs: Screens / Components / Palette & type. System tab: "Inferred palette" rows + "Recurring structure" chips. | |
| `/pricing` | Plans | Narrow shell. Centred H1 34 + intro. 3 plan cards (Free £0, **Pro £12** — `text` border + surface + "Popular" badge + accent button, Team £9 per seat). Comparison table. Footer "No countdown timers, no fake scarcity, cancel in one click." | |
| `/upload` | Submit a design | Narrow. Panel: URL input ("https://"), "or drop an image" divider, drop zone "Drop a PNG, JPG or MP4". Panel "Suggested metadata" with removable chip rows (label column 144). Attribution panel. Full-width accent "Submit for review" (44). "Usually reviewed within 24 hours." | |
| `/u/me` | Profile hub | PageHeader "Your profile". 2-col link cards: Saved, Upload, Collections, Settings (14 bold + 13 text-2). | Known source handle redirects to `/source/`. |
| `/legal/[doc]` | attribution, takedown | Narrow PageHeader + paragraphs 14.5 text-2 relaxed, max 672. | |
| 404 | Not found | Centred: Logo 56, "Not found" 22 bold, "That page doesn't exist.", "Back to the feed" bordered button. | |
| `/dev-measure` | Dev tool | Not a product screen — skip in Flutter. | |

---

## 13. Content & voice

- **Tone:** plain, candid, slightly editorial; explains *why* ("Saving never asks which board…", "No countdown timers, no fake scarcity").
- **Casing:** sentence case everywhere. UPPERCASE only for eyebrow/overline/PRO.
- **Separators:** middle dot `·` between meta facts; em dash `—` in prose; curly quotes `“ ”` around queries; ellipsis `…` in "Move to…", "New collection…".
- **Numbers — `compact(n)`:** `<1000` → `842`; `1000–9999` → `1.2k`; `10000–999999` → `12k`; `≥1M` → `1.2M`.
- **Time — `timeAgo(days)`:** `<1` today · `<7` `3d ago` · `<30` `2w ago` · `<365` `4mo ago` · else `1y ago`.
- **Key strings:** "Interface seeker", "N saved", "Pick of the week", "Open breakdown", "Popular this week", "Recommended for you", "more", "clear", "Load more", "{n} results · end of feed", "Nothing matches those filters", "Saved to Recently saved", "Removed", "Move to…", "Dismiss", "Reading as", "Search for “…”", "Copy prompt", "Copied".
- Title: "Uiverse — Discover interfaces worth building". Description: "A visual index of how real interfaces are built. Browse websites, apps and components, save what works, and understand how it was made."
- All sources are invented products — no real brands appear.

---

## 14. Accessibility

### Contrast (WCAG 2.x, computed)

| Pair | Light | Dark | Verdict |
|---|---|---|---|
| text / bg | 15.36 | 14.69 | AAA |
| text-2 / bg | 7.89 | 8.92 | AAA |
| text-3 / bg | **4.03** | 4.79 | Light fails AA for normal text (4.5); OK ≥ 18.66px bold / 24px. text-3 on surface = 4.24, also < 4.5. |
| accent-fg / accent (dark text on orange) | 6.29 | 6.41 | AA |
| on-signal / signal | 12.54 | 10.99 | AAA |
| **accent as text on bg** (active nav label, hover links) | **2.44** | 6.41 | **Light fails.** Active state is also carried by position/icon, but consider darkening active label or adding an indicator in Flutter. |

Recommendation for the port: keep the palette, but for light mode either darken `text-3` slightly (≈`#6f6a5c`) or use it only for ≥ 14px non-essential text, and pair accent-coloured nav labels with a non-colour cue (e.g. 3px accent bar, as the detail tabs already do).

### Other

- Focus ring: **2px accent outline, 2px offset** on everything focusable; cards use an accent offset shadow instead. Flutter: custom `FocusableActionDetector` + border decoration.
- Touch targets: several web targets are < 48dp (chips 32, card save 28, Pick header buttons 32, device segments ~24). In Flutter keep the **visual** size but expand hit area to 48 (`MaterialTapTargetSize.padded` or padding around a `GestureDetector`).
- Labels: icon-only buttons carry labels ("Saved", "Close", "Switch to dark theme", "Save" / "Remove from saves", "Show details", "Hide pick of the week", "Uiverse home") → Flutter `Semantics(label:)` / `tooltip`.
- `aria-pressed` on save and device toggles; `aria-expanded` on menus; `aria-current="page"` on active nav → `Semantics(selected:, toggled:, expanded:)`.
- Esc closes overlays, dialogs, popovers, Pick details → map to Android back / `Shortcuts` on desktop.
- Reduced motion honoured (§6).
- Text selection colour = signal background, on-signal text → `TextSelectionThemeData(selectionColor: signal)`.

---

## 15. Theme behaviour & persisted state

- Three states: **light**, **dark**, **system** (default when nothing stored). Toggle flips between explicit light/dark based on what's currently shown; there's no "back to system" control.
- Toggle icon shows the *destination*: Moon in light, Sun in dark. Rail variant labels "Dark"/"Light".
- `html { color-scheme: light dark }` → system widgets follow.

| Key (localStorage) | Content | Flutter (`shared_preferences`) |
|---|---|---|
| `uiv.theme` | `"light"` \| `"dark"` | `ThemeMode` |
| `uiv.saves.v1` | `{ saves: [{slug, collectionId, at, note?}], collections: [{id, name, sections[]}] }`; default collection `recent` = "Recently saved"; new saves prepend | same JSON |
| `uiv.prompts.v1` | `{ month: "YYYY-MM", used: n }`, free limit **3**/month, resets when month changes | same |
| `uiv.pick` | `"tab"` when Pick of the week is folded | bool |

Collection ids are slugified names (`[^a-z0-9]+ → -`, max 40).

---

## 16. Flutter implementation appendix

### 16.1 Suggested structure

```
lib/
  theme/
    uiverse_colors.dart      // ThemeExtension with every token (§2.1)
    uiverse_text.dart        // named text styles (§3.4)
    uiverse_theme.dart       // light/dark ThemeData
    motion.dart              // durations, curves, hardShadow()
  shell/                     // AppShell, Navbar, Rail, BottomNav, ThemeToggle, Logo
  widgets/                   // InkBox, LiftOnPress, Chip, FilterPopover, SaveButton, SaveToast, CopyValue, SectionHead, PageHeader
  feed/                      // Feed, Masonry, Card, PickOfTheWeek
  detail/                    // DetailScreen, Breakdown, PromptDialog
  mock/                      // MockScreen + primitives + sections (port of src/components/mock)
  data/                      // palettes, taxonomy, items, spec, compact/timeAgo
  state/                     // saves, prompt quota, theme (Riverpod/Provider)
assets/icons/*.svg           // §7
```

Packages: `google_fonts` (Space Mono, Lexend) — or bundle the TTFs for offline, `flutter_svg`, `flutter_staggered_grid_view`, `shared_preferences`, `go_router` (deep links + modal routes), `flutter_launcher_icons`.

### 16.2 Tokens

```dart
import 'package:flutter/material.dart';

@immutable
class UiverseColors extends ThemeExtension<UiverseColors> {
  const UiverseColors({
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.rule,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentFg,
    required this.signal,
    required this.onSignal,
    required this.focus,
    required this.danger,
    required this.overlay,
  });

  final Color bg, bgSubtle, surface, border, borderStrong, rule;
  final Color text, text2, text3, accent, accentFg, signal, onSignal;
  final Color focus, danger, overlay;

  static const light = UiverseColors(
    bg: Color(0xFFFDF1D6),
    bgSubtle: Color(0xFFF6E4BF),
    surface: Color(0xFFFFF7E6),
    border: Color(0xFF1C1B18),
    borderStrong: Color(0xFF000000),
    rule: Color(0x381C1B18), // 22% of #1c1b18
    text: Color(0xFF1C1B18),
    text2: Color(0xFF4D4A42),
    text3: Color(0xFF7C7667),
    accent: Color(0xFFF47A2C),
    accentFg: Color(0xFF1C1B18),
    signal: Color(0xFFF8DC3D),
    onSignal: Color(0xFF1C1B18),
    focus: Color(0xFFF47A2C),
    danger: Color(0xFFC2331F),
    overlay: Color(0x73281E0A), // rgb(40 30 10 / .45)
  );

  static const dark = UiverseColors(
    bg: Color(0xFF1B1915),
    bgSubtle: Color(0xFF26231D),
    surface: Color(0xFF211E19),
    border: Color(0xFFD8CAA9),
    borderStrong: Color(0xFFF3E6C8),
    rule: Color(0x38D8CAA9),
    text: Color(0xFFF5EAD2),
    text2: Color(0xFFC3B89E),
    text3: Color(0xFF8E856F),
    accent: Color(0xFFF47A2C),
    accentFg: Color(0xFF1B1915),
    signal: Color(0xFFE9CC33),
    onSignal: Color(0xFF1B1915),
    focus: Color(0xFFF47A2C),
    danger: Color(0xFFC2331F),
    overlay: Color(0xB3000000), // black / .70
  );

  /// Theme-independent colours (§2.1 "Hardcoded").
  static const ink = Color(0xFF1C1B18);
  static const paperBadge = Color(0xFFFFF7E6);

  @override
  UiverseColors copyWith() => this;

  @override
  UiverseColors lerp(ThemeExtension<UiverseColors>? other, double t) {
    if (other is! UiverseColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return UiverseColors(
      bg: l(bg, other.bg),
      bgSubtle: l(bgSubtle, other.bgSubtle),
      surface: l(surface, other.surface),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      rule: l(rule, other.rule),
      text: l(text, other.text),
      text2: l(text2, other.text2),
      text3: l(text3, other.text3),
      accent: l(accent, other.accent),
      accentFg: l(accentFg, other.accentFg),
      signal: l(signal, other.signal),
      onSignal: l(onSignal, other.onSignal),
      focus: l(focus, other.focus),
      danger: l(danger, other.danger),
      overlay: l(overlay, other.overlay),
    );
  }
}

extension UiverseX on BuildContext {
  UiverseColors get ui => Theme.of(this).extension<UiverseColors>()!;
}
```

### 16.3 ThemeData

```dart
import 'package:google_fonts/google_fonts.dart';

ThemeData uiverseTheme(Brightness b) {
  final c = b == Brightness.light ? UiverseColors.light : UiverseColors.dark;
  final base = GoogleFonts.spaceMonoTextTheme();
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final side = BorderSide(color: c.border, width: 1);

  return ThemeData(
    brightness: b,
    useMaterial3: true,
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    colorScheme: ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.accentFg,
      secondary: c.signal,
      onSecondary: c.onSignal,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
      onError: c.bg,
      outline: c.border,
      outlineVariant: c.rule,
    ),
    textTheme: base.apply(bodyColor: c.text, displayColor: c.text),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    splashFactory: NoSplash.splashFactory, // hover/press = bg-subtle fill, no ripples
    highlightColor: c.bgSubtle,
    hoverColor: c.bgSubtle,
    focusColor: c.focus,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: c.signal,
      cursorColor: c.text,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: square,
        side: side,
        foregroundColor: c.text,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: square.copyWith(side: side),
        backgroundColor: c.accent,
        foregroundColor: c.accentFg,
        minimumSize: const Size(0, 44),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bgSubtle,
      hintStyle: TextStyle(color: c.text3),
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: side),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: side),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: c.borderStrong),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    dialogTheme: DialogThemeData(
      shape: square.copyWith(side: side),
      backgroundColor: c.bg,
      barrierColor: c.overlay,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: square.copyWith(side: side),
      backgroundColor: c.bg,
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: square.copyWith(side: side),
      color: c.surface,
      elevation: 0,
    ),
  );
}
```

(`DialogThemeData` is the current name; on older Flutter use `DialogTheme`.)

### 16.4 Motion + the two signature widgets

```dart
const kDur = Duration(milliseconds: 140);
const kEase = Cubic(0.2, 0, 0, 1);
const kFadeUp = Duration(milliseconds: 220);
const kFadeIn = Duration(milliseconds: 160);
const kSheet = Duration(milliseconds: 240);

BoxShadow hardShadow(double d, Color c) =>
    BoxShadow(color: c, offset: Offset(d, d), blurRadius: 0);

/// 1px ink box — the base of almost every surface.
class InkBox extends StatelessWidget {
  const InkBox({super.key, required this.child, this.color, this.padding, this.shadow = 0});
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double shadow; // 0, 2, 3, 4, 5, 6

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        border: Border.all(color: c.border),
        boxShadow: shadow > 0 ? [hardShadow(shadow, c.border)] : null,
      ),
      child: child,
    );
  }
}

/// Card/tile lift: up-left 2px + 4px hard shadow on hover or press.
class LiftOnPress extends StatefulWidget {
  const LiftOnPress({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<LiftOnPress> createState() => _LiftOnPressState();
}

class _LiftOnPressState extends State<LiftOnPress> {
  bool _up = false;
  void _set(bool v) => setState(() => _up = v);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final reduce = MediaQuery.of(context).disableAnimations;
    return MouseRegion(
      onEnter: (_) => _set(true),
      onExit: (_) => _set(false),
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
          curve: kEase,
          transform: Matrix4.translationValues(_up ? -2 : 0, _up ? -2 : 0, 0),
          decoration: BoxDecoration(
            boxShadow: [hardShadow(_up ? 4 : 0, c.border)],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
```

### 16.5 Text styles

```dart
TextStyle mono(double size, {bool bold = false, Color? color, double? height, double track = -0.01}) =>
    GoogleFonts.spaceMono(
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
      height: height ?? 1.5,
      letterSpacing: track * size,
    );

TextStyle cardTitle(Color color) =>
    GoogleFonts.lexend(fontSize: 13.5, height: 1.375, color: color, letterSpacing: -0.01 * 13.5);

// e.g. pageTitle: mono(26, bold: true, height: 1.25, track: -0.03)
//      overline:  mono(11, bold: true, track: 0.025)  + .toUpperCase() on the string
```

### 16.6 CSS → Dart token map

| CSS / Tailwind | Dart |
|---|---|
| `bg-bg`, `bg-bg-subtle`, `bg-surface` | `c.bg`, `c.bgSubtle`, `c.surface` |
| `border`, `border-border` | `Border.all(color: c.border)` |
| `border-rule` | `c.rule` |
| `text-text`, `-2`, `-3` | `c.text`, `c.text2`, `c.text3` |
| `bg-accent text-accent-fg` | `c.accent` / `c.accentFg` |
| `bg-signal text-on-signal` | `c.signal` / `c.onSignal` |
| `shadow-[4px_4px_0_var(--border)]` | `hardShadow(4, c.border)` |
| `rounded-*` | `BorderRadius.zero` |
| `p-N` | `EdgeInsets.all(N * 4)` |
| `h-8 / h-9 / h-10 / h-11 / h-16` | 32 / 36 / 40 / 44 / 64 |
| `anim-fade-up / fade-in / sheet` | `kFadeUp` / `kFadeIn` / `kSheet` with `kEase` |
| `tabular-nums` | `FontFeature.tabularFigures()` |
| `link-ink` | `TextDecoration.underline`, thickness 1; hover colour accent |
| `sm / md / lg / xl` | 640 / 768 / 1024 / 1280 |

### 16.7 Port checklist

- [ ] Tokens light/dark + system theme mode, persisted
- [ ] Fonts bundled; weight 500→400, 600→700 mapping applied
- [ ] Icon SVGs exported at stroke 1.8
- [ ] Logo + launcher icons
- [ ] Shell: Navbar cells, Rail (≥768), BottomNav (<768) with safe area
- [ ] Card + LiftOnPress, badges, PRO
- [ ] Masonry with `useColumns` thresholds
- [ ] ChipRail, FilterBar, popovers (→ bottom sheets on phone)
- [ ] Feed pagination (28 / 5 auto pages / Load more), empty + end states
- [ ] SaveButton ×3 variants, SaveToast with Move to…, collections
- [ ] Pick of the week (tab/card/open) with persisted fold
- [ ] Detail: device toggle + frame, rail, action trio, meta, tabs, Breakdown, Responsive, Code
- [ ] Detail as modal from feeds, page on deep link
- [ ] Prompt dialog + monthly quota
- [ ] Search (NL parse chips) + big field with rotating placeholder
- [ ] All screens in §12
- [ ] Mock renderer port (or real images)
- [ ] Contrast fixes from §14, 48dp hit areas, semantics labels, reduced motion
