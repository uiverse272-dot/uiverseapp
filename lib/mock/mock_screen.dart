import 'package:flutter/widgets.dart' hide Viewport;

import '../data/models.dart';
import 'primitives.dart';
import 'sections/agency.dart';
import 'sections/app.dart';
import 'sections/checkout_auth.dart';
import 'sections/dashboard.dart';
import 'sections/editorial_docs.dart';
import 'sections/landing.dart';
import 'sections/portfolio.dart';
import 'sections/pricing.dart';
import 'sections/shop.dart';

/// Procedurally rendered interface previews (§11).
///
/// Uiverse ships no screenshots: every preview is drawn from an item's
/// archetype + palette. Units are design pixels at the viewport's width, and
/// each section reflows for the viewport — nothing is simply scaled down.
/// Without [viewport] a design renders at its native device, which is what
/// feed cards show.
class MockScreen extends StatelessWidget {
  const MockScreen({super.key, required this.item, this.full = false, this.viewport});

  final Item item;

  /// false: a fixed `item.aspect` frame cropped like a screenshot (feeds).
  /// true: the height follows the content, min. one screen (detail frame).
  final bool full;

  /// Draw at this device. Implies content height, like [full].
  final Viewport? viewport;

  /// The device an item is drawn at when no viewport is given.
  static Viewport nativeViewport(Item item) =>
      item.device == Device.mobile ? Viewport.mobile : Viewport.desktop;

  @override
  Widget build(BuildContext context) {
    final vp = viewport ?? nativeViewport(item);
    final flow = full || viewport != null;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.hasBoundedWidth ? box.maxWidth : vp.w;
          final c = MockCtx(scale: width / vp.w, item: item, vp: vp);
          final root = _root(c);
          final bg = item.palette.bg;
          if (!flow) {
            return ClipRect(
              child: SizedBox(
                width: width,
                height: width / item.aspect,
                child: ColoredBox(color: bg, child: root),
              ),
            );
          }
          return ClipRect(
            child: ColoredBox(
              color: bg,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: width,
                  maxWidth: width,
                  minHeight: _minHeight(c, vp),
                ),
                child: root,
              ),
            ),
          );
        },
      ),
    );
  }

  double _minHeight(MockCtx c, Viewport vp) {
    if (item.kind != Kind.component) return c.u(vp.h);
    if (vp == nativeViewport(item)) return c.u(vp.w / item.aspect);
    if (kFills.contains(item.componentType)) return c.u(c.v(700, 760, 700));
    return 0;
  }

  Widget _root(MockCtx c) {
    if (item.kind == Kind.component) {
      final block = blockOnly(c);
      final fills = kFills.contains(item.componentType);
      // `margin: auto 0` — the block is centred in the frame, or fills it.
      return MCol(c, justify: MJustify.center, children: [
        if (fills) MItem(grow: 1, child: block) else block,
      ]);
    }
    return MCol(c, children: page(c));
  }
}

/// Component types that fill their frame rather than sitting at natural height.
const kFills = {'login', 'checkout', 'sidebar', 'charts', 'list'};

/// The section stack for a screen, per archetype and viewport. Layouts that
/// fill the frame (dashboards, docs, apps…) come back as a growing item.
List<Widget> page(MockCtx c) {
  final p = c.p;
  switch (c.item.archetype) {
    case Archetype.saasLanding:
      return [
        navbar(c),
        hero(c),
        logoCloud(c),
        featureGrid(c),
        statsBand(c),
        testimonial(c),
        ctaBand(c),
        footer(c),
      ];
    case Archetype.dashboard:
      if (c.isMobile) {
        // Sidebar → menu button + bottom tab bar; panels stack.
        return [
          MItem(
            grow: 1,
            child: MCol(c, children: [
              topBar(c),
              MItem(
                grow: 1,
                child: MCol(c, gap: 14, pad: c.ins(16), children: [
                  statCards(c),
                  B(c, h: 230, fill: true, child: MCol(c, children: [chartPanel(c)])),
                  activityList(c),
                  dataTable(c),
                ]),
              ),
              tabBar(c),
            ]),
          ),
        ];
      }
      return [
        MItem(
          grow: 1,
          child: MRow(c, align: MAlign.stretch, children: [
            sidebar(c),
            MItem(
              grow: 1,
              child: MCol(c, children: [
                topBar(c),
                MItem(
                  grow: 1,
                  child: MCol(c, gap: c.v(14, 16, 0), pad: c.ins(20), children: [
                    statCards(c),
                    if (c.isDesktop)
                      B(
                        c,
                        h: 300,
                        fill: true,
                        child: MRow(c, gap: 14, align: MAlign.stretch, children: [
                          chartPanel(c),
                          activityList(c),
                        ]),
                      )
                    else ...[
                      B(c, h: 280, fill: true, child: MCol(c, children: [chartPanel(c)])),
                      activityList(c),
                    ],
                    dataTable(c),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ];
    case Archetype.pricing:
      return [navbar(c), sectionHeader(c), billingToggle(c), pricingTiers(c), faq(c), footer(c)];
    case Archetype.ecommerce:
      return [shopNav(c), campaignHero(c), categoryRow(c), productGrid(c), ctaBand(c), footer(c)];
    case Archetype.portfolio:
      return [minimalNav(c), typeStatement(c), workGrid(c), indexList(c), footer(c)];
    case Archetype.checkout:
      return [
        MItem(
          grow: 1,
          child: MCol(c, children: [
            B(
              c,
              pad: c.ins(c.v(24, 22, 18), 0),
              bb: p.border,
              child: MRow(c, justify: MJustify.center, children: [
                MRow(c, gap: 10, children: [B(c, w: 20, h: 20, r: 999, bg: p.accent)]),
              ]),
            ),
            if (c.isMobile) ...[
              orderSummaryBar(c),
              checkoutForm(c),
            ] else
              MItem(
                grow: 1,
                child: MRow(c, align: MAlign.stretch, children: [checkoutForm(c), orderSummary(c)]),
              ),
          ]),
        ),
      ];
    case Archetype.auth:
      // The art panel is a laptop luxury; smaller screens get the form alone.
      return [
        MItem(
          grow: 1,
          child: MRow(c, align: MAlign.stretch, children: [authCard(c), if (c.isDesktop) authArt(c)]),
        ),
      ];
    case Archetype.editorial:
      return [masthead(c), leadStory(c), articleIndex(c), footer(c)];
    case Archetype.docs:
      if (c.isMobile) {
        return [
          MItem(grow: 1, child: MCol(c, children: [docsMobileBar(c), docsBody(c)])),
        ];
      }
      return [
        MItem(
          grow: 1,
          child: MRow(c, align: MAlign.stretch, children: [
            docsSidebar(c),
            docsBody(c),
            if (c.isDesktop) docsToc(c),
          ]),
        ),
      ];
    case Archetype.agency:
      return [agencyHero(c), servicesList(c), workGrid(c), ctaBand(c)];
    case Archetype.mobileFinance:
    case Archetype.mobileFeed:
    case Archetype.mobileOnboarding:
    case Archetype.mobileProfile:
      return app(c);
  }
}

/// Native mobile apps. Tablet keeps the status and tab bars; laptop becomes a
/// web app with a side nav.
List<Widget> app(MockCtx c) {
  final a = c.item.archetype;
  final body = switch (a) {
    Archetype.mobileFinance => mobileFinance(c),
    Archetype.mobileFeed => mobileFeed(c),
    Archetype.mobileOnboarding => mobileOnboarding(c),
    Archetype.mobileProfile => mobileProfile(c),
    _ => const <Widget>[],
  };
  final tabs = a != Archetype.mobileOnboarding;
  if (c.isDesktop) {
    return [
      MItem(
        grow: 1,
        child: MRow(c, align: MAlign.stretch, children: [if (tabs) appSideNav(c), ...body]),
      ),
    ];
  }
  return [
    MItem(
      grow: 1,
      child: MCol(c, children: [statusBar(c), ...body, if (tabs) tabBar(c)]),
    ),
  ];
}

/// A single component block, rendered on its own — what `kind: component` shows.
Widget blockOnly(MockCtx c) {
  final p = c.p;
  final gut = c.u(c.v(28, 24, 16));
  final phoneApp = c.item.device == Device.mobile && c.isMobile;
  switch (c.item.componentType) {
    case 'navbar':
      return Padding(
        padding: EdgeInsets.only(top: c.u(6)),
        child: phoneApp ? statusBar(c) : navbar(c),
      );
    case 'hero':
      return Transform.scale(scale: 0.94, alignment: Alignment.topCenter, child: MCol(c, children: [hero(c)]));
    case 'pricing':
      return Padding(
        padding: EdgeInsets.symmetric(vertical: gut),
        child: MCol(c, children: [billingToggle(c), pricingTiers(c)]),
      );
    case 'table':
      return Padding(padding: EdgeInsets.all(gut), child: dataTable(c));
    case 'stats':
      return Padding(padding: EdgeInsets.all(gut), child: statCards(c));
    case 'testimonials':
      return testimonial(c);
    case 'cta':
      return Padding(padding: EdgeInsets.only(top: c.u(20)), child: ctaBand(c));
    case 'footer':
      return Padding(padding: EdgeInsets.only(top: c.u(10)), child: footer(c));
    case 'login':
      return MRow(c, align: MAlign.stretch, children: [authCard(c)]);
    case 'checkout':
      return MRow(c, align: MAlign.stretch, children: [checkoutForm(c)]);
    case 'sidebar':
      // On a phone the sidebar is a drawer over the dimmed page.
      return MRow(c, align: MAlign.stretch, children: [
        sidebar(c),
        MItem(flex: 1, child: B(c, bg: c.isMobile ? hexA(p.text, 0x33) : p.bg)),
      ]);
    case 'charts':
      return B(
        c,
        pad: EdgeInsets.all(gut),
        fill: true,
        child: MRow(c, align: MAlign.stretch, children: [chartPanel(c)]),
      );
    case 'filters':
      return Padding(padding: EdgeInsets.only(top: c.u(18)), child: categoryRow(c));
    case 'cards':
      if (c.item.device == Device.mobile) return MCol(c, children: mobileFeed(c));
      return Transform.scale(
        scale: 0.96,
        alignment: Alignment.topCenter,
        child: featureGrid(c),
      );
    case 'list':
      return B(
        c,
        pad: EdgeInsets.all(gut),
        fill: true,
        child: MRow(c, justify: MJustify.center, align: MAlign.start, children: [activityList(c)]),
      );
    default:
      return Padding(padding: EdgeInsets.all(gut), child: statCards(c));
  }
}
