import 'package:flutter/widgets.dart' hide Viewport;

import '../../data/models.dart';
import '../primitives.dart';
import 'dashboard.dart';

/// Native mobile app sections. Phone layouts return several children
/// (the web fragments); they are laid into the app's column by `App`.

Widget statusBar(MockCtx c) {
  final p = c.p;
  return MRow(c, justify: MJustify.spaceBetween, pad: c.ins(14, c.v(24, 28, 24), 6), children: [
    T(c, '9:41', size: 13, weight: 600, color: p.text),
    MRow(c, gap: 5, children: [
      B(c, w: 16, h: 9, r: 2, bg: p.text, o: 0.8),
      B(c, w: 13, h: 9, r: 2, bg: p.text, o: 0.8),
      B(c, w: 22, h: 10, r: 3, bg: p.text, o: 0.8),
    ]),
  ]);
}

/// App destinations per mobile archetype — the tab bar on phones, the nav on bigger screens.
List<String> appNav(Item item) => item.archetype == Archetype.mobileFinance
    ? const ['Home', 'Cards', 'Payments', 'Insights', 'Settings']
    : const ['Home', 'Search', 'Create', 'Activity', 'Profile'];

/// Pinned to the bottom (`margin-top: auto`) — must sit directly in a column.
Widget tabBar(MockCtx c) {
  final p = c.p;
  if (c.isTablet) {
    // Tablets keep the bar but give each destination a label.
    return MItem(
      autoBefore: true,
      child: B(
        c,
        bt: p.border,
        pad: c.ins(12, 60, 22),
        child: MRow(c, justify: MJustify.spaceAround, children: [
          for (final (i, n) in appNav(c.item).indexed)
            MCol(c, gap: 7, align: MAlign.center, children: [
              B(c, w: 22, h: 22, r: 6, bg: i == 0 ? p.accent : p.text, o: i == 0 ? 1 : 0.22),
              T(c, n, size: 11, weight: i == 0 ? 600 : 450, color: i == 0 ? p.accent : p.muted),
            ]),
        ]),
      ),
    );
  }
  return MItem(
    autoBefore: true,
    child: B(
      c,
      bt: p.border,
      pad: c.ins(12, 26, 26),
      child: MRow(c, justify: MJustify.spaceBetween, children: [
        for (var i = 0; i < 5; i++)
          MCol(c, gap: 6, align: MAlign.center, children: [
            B(c, w: 20, h: 20, r: 6, bg: i == 0 ? p.accent : p.text, o: i == 0 ? 1 : 0.22),
            B(c, w: 22, h: 4, r: 2, bg: i == 0 ? p.accent : p.text, o: i == 0 ? 0.8 : 0.16),
          ]),
      ]),
    ),
  );
}

/// Laptop: the tab bar becomes a labelled left nav.
Widget appSideNav(MockCtx c) {
  final p = c.p;
  return B(
    c,
    w: 240,
    br: p.border,
    pad: c.ins(26, 18),
    bg: p.surface,
    fill: true,
    child: MCol(c, gap: 4, children: [
      Padding(
        padding: EdgeInsets.only(bottom: c.u(28)),
        child: MRow(c, gap: 10, pad: EdgeInsets.only(left: c.u(10)), children: [
          circle(c, 26, bg: p.accent),
          T(c, c.item.source.name, size: 16, weight: 600, color: p.text),
        ]),
      ),
      for (final (i, n) in appNav(c.item).indexed)
        B(
          c,
          pad: c.ins(11, 12),
          r: 10,
          bg: i == 0 ? p.raised : null,
          child: MRow(c, gap: 12, children: [
            B(c, w: 18, h: 18, r: 5, bg: i == 0 ? p.accent : p.text, o: i == 0 ? 1 : 0.25),
            T(c, n, size: 14, weight: i == 0 ? 600 : 450, color: i == 0 ? p.text : p.muted),
          ]),
        ),
      MItem(
        autoBefore: true,
        child: B(
          c,
          bt: p.border,
          pad: c.ins(14, 10, 0),
          child: MRow(c, gap: 10, children: [
            circle(c, 30, bg: p.raised),
            MCol(c, gap: 6, children: [
              line(c, w: 80, h: 8, col: p.text, o: 0.5),
              line(c, w: 56, h: 7, col: p.muted, o: 0.35),
            ]),
          ]),
        ),
      ),
    ]),
  );
}

/* ------------------------------------------------------------ finance */

Widget balanceCard(MockCtx c) {
  final p = c.p;
  final blob = c.u(c.v(240, 210, 180));
  return B(
    c,
    r: 20,
    bg: p.accent,
    pad: c.ins(c.v(28, 24, 20)),
    clip: true,
    layers: [
      Disc(fx: 1, dx: c.u(40) - blob, dy: -c.u(40), w: blob, h: blob, fill: const Color(0x1FFFFFFF)),
    ],
    child: MCol(c, children: [
      T(c, 'Total balance', size: 12, weight: 480, color: p.accentFg, o: 0.8),
      gapBox(c, h: 10),
      T(c, '£12,480.20', size: c.v(44, 40, 36), weight: 600, color: p.accentFg),
      gapBox(c, h: 18),
      MRow(c, gap: 8, children: [
        B(
          c,
          h: 26,
          r: 999,
          bg: const Color(0x26FFFFFF),
          pad: EdgeInsets.symmetric(horizontal: c.u(12)),
          align: Alignment.centerLeft,
          child: T(c, '+2.4% this month', size: 11, weight: 550, color: p.accentFg),
        ),
      ]),
    ]),
  );
}

Widget quickActions(MockCtx c) {
  final p = c.p;
  final acts = [
    for (final a in const ['Send', 'Request', 'Top up', 'Split'])
      MCol(c, gap: 9, align: MAlign.center, children: [
        circle(c, 46, bg: p.raised),
        T(c, a, size: 11, weight: 450, color: p.muted),
      ]),
  ];
  if (c.isMobile) {
    return MRow(c, justify: MJustify.spaceBetween, pad: c.ins(22, 28), children: acts);
  }
  return B(
    c,
    r: 20,
    border: p.border,
    bg: p.surface,
    pad: c.ins(22),
    fill: true,
    child: MCol(c, justify: MJustify.center, children: [
      MGrid(c, cols: c.isTablet ? 2 : 4, gap: 16, rowGap: 20, children: acts),
    ]),
  );
}

Widget txnList(MockCtx c, int n) {
  final p = c.p;
  return MCol(c, children: [
    MRow(c, justify: MJustify.spaceBetween, pad: EdgeInsets.only(bottom: c.u(12)), children: [
      T(c, 'Recent', size: 14, weight: 600, color: p.text),
      T(c, 'See all', size: 12, weight: 450, color: p.accent),
    ]),
    MCol(c, gap: 16, children: [
      for (var i = 0; i < n; i++)
        MRow(c, gap: 12, children: [
          circle(c, 38, bg: p.raised),
          MItem(
            grow: 1,
            child: MCol(c, gap: 7, children: [
              line(c, wf: (45 + noise(i, 37) * 30) / 100, h: 9, col: p.text, o: 0.6),
              line(c, wf: (28 + noise(i, 41) * 18) / 100, h: 8, col: p.muted, o: 0.35),
            ]),
          ),
          line(c, w: 46, h: 9, col: p.text, o: 0.55),
        ]),
    ]),
  ]);
}

Widget greeting(MockCtx c) {
  final p = c.p;
  return MCol(c, gap: 7, children: [
    T(c, 'Good morning', size: 13, weight: 430, color: p.muted),
    T(c, c.item.source.name, size: c.v(28, 24, 21), weight: 600, color: p.text),
  ]);
}

List<Widget> mobileFinance(MockCtx c) {
  final p = c.p;
  if (c.isTablet) {
    return [
      MCol(c, gap: 24, pad: c.ins(18, 32, 24), children: [
        MRow(c, justify: MJustify.spaceBetween, children: [greeting(c), circle(c, 44, bg: p.raised)]),
        MGrid(c, cols: 2, gap: 18, children: [balanceCard(c), quickActions(c)]),
        B(c, r: 16, border: p.border, bg: p.surface, pad: c.ins(22), child: txnList(c, 7)),
      ]),
    ];
  }
  if (c.isDesktop) {
    return [
      MItem(
        grow: 1,
        child: MCol(c, gap: 24, pad: c.ins(32, 40), children: [
          MRow(c, justify: MJustify.spaceBetween, children: [
            greeting(c),
            MRow(c, gap: 12, children: [
              btn(c, label: 'Send money', w: 140, h: 42, r: 10, bg: p.accent, fg: p.accentFg, size: 14),
              circle(c, 42, bg: p.raised),
            ]),
          ]),
          MRow(c, gap: 20, align: MAlign.stretch, children: [
            MItem(flex: 1.1, child: MCol(c, children: [balanceCard(c)])),
            MItem(flex: 1.4, child: B(c, child: quickActions(c))),
            MItem(flex: 1.2, child: MRow(c, align: MAlign.stretch, children: [chartPanel(c)])),
          ]),
          dataTable(c),
        ]),
      ),
    ];
  }
  return [
    MRow(c, justify: MJustify.spaceBetween, pad: c.ins(14, 22, 18), children: [
      greeting(c),
      circle(c, 38, bg: p.raised),
    ]),
    Padding(padding: EdgeInsets.symmetric(horizontal: c.u(20)), child: balanceCard(c)),
    quickActions(c),
    Padding(padding: c.ins(4, 22, 0), child: txnList(c, 5)),
  ];
}

/* --------------------------------------------------------------- feed */

Widget stories(MockCtx c, int n) {
  final p = c.p;
  return MRow(c, gap: 12, children: [
    for (var i = 0; i < n; i++)
      MCol(c, gap: 7, align: MAlign.center, children: [
        circle(c, 54, bg: p.raised, border: i < 3 ? p.accent : null, bw: 2),
        line(c, w: 32, h: 6, col: p.muted, o: 0.35),
      ]),
  ]);
}

Widget post(MockCtx c, int i, double h) {
  final p = c.p;
  return MCol(c, gap: 11, children: [
    MRow(c, gap: 10, children: [
      circle(c, 32, bg: p.raised),
      MItem(
        grow: 1,
        child: MCol(c, gap: 6, children: [
          line(c, w: 90, h: 8, col: p.text, o: 0.55),
          line(c, w: 60, h: 7, col: p.muted, o: 0.3),
        ]),
      ),
    ]),
    B(
      c,
      h: h,
      r: 14,
      bg: p.raised,
      layers: [
        Linear(60.0 + i * 80, [hexA(p.chart[i % 4], 0x2a), null], const [0, 0.7]),
      ],
    ),
    MRow(c, gap: 16, children: [
      for (var k = 0; k < 3; k++) B(c, w: 20, h: 20, r: 6, bg: p.text, o: 0.2),
    ]),
    lines(c, n: 2, h: 8, gap: 8, col: p.muted, o: 0.3, last: 0.5),
  ]);
}

List<Widget> mobileFeed(MockCtx c) {
  final p = c.p;
  final header = MRow(c, justify: MJustify.spaceBetween, children: [
    T(c, c.item.title, size: c.isMobile ? 22 : 26, weight: 600, color: p.text),
    MRow(c, gap: 10, children: [circle(c, 32, bg: p.raised), circle(c, 32, bg: p.raised)]),
  ]);
  if (c.isTablet) {
    return [
      MCol(c, gap: 20, pad: c.ins(16, 32, 24), children: [
        header,
        stories(c, 11),
        MGrid(c, cols: 2, gap: 20, rowGap: 26, children: [for (var i = 0; i < 4; i++) post(c, i, 300)]),
      ]),
    ];
  }
  if (c.isDesktop) {
    return [
      MItem(
        grow: 1,
        child: MRow(
          c,
          gap: 48,
          align: MAlign.start,
          justify: MJustify.center,
          pad: c.ins(32, 40),
          children: [
            B(
              c,
              w: 580,
              child: MCol(c, gap: 24, children: [
                header,
                stories(c, 8),
                for (var i = 0; i < 2; i++) post(c, i, 420),
              ]),
            ),
            B(
              c,
              w: 300,
              pad: EdgeInsets.only(top: c.u(56)),
              child: MCol(c, gap: 18, children: [
                T(c, 'Suggested for you', size: 13, weight: 600, color: p.muted),
                for (var i = 0; i < 5; i++)
                  MRow(c, gap: 12, children: [
                    circle(c, 36, bg: p.raised),
                    MItem(
                      grow: 1,
                      child: MCol(c, gap: 6, children: [
                        line(c, wf: (50 + noise(i, 43) * 30) / 100, h: 8, col: p.text, o: 0.55),
                        line(c, wf: 0.4, h: 7, col: p.muted, o: 0.3),
                      ]),
                    ),
                    T(c, 'Follow', size: 12, weight: 550, color: p.accent),
                  ]),
              ]),
            ),
          ],
        ),
      ),
    ];
  }
  return [
    Padding(padding: c.ins(14, 22, 16), child: header),
    Padding(padding: c.ins(0, 22, 18), child: stories(c, 6)),
    MCol(c, gap: 18, pad: c.ins(0, 22), children: [for (var i = 0; i < 2; i++) post(c, i, 182)]),
  ];
}

/* --------------------------------------------------------- onboarding */

/// The illustration; with [h] null it fills its flex slot (`height: 100%`).
Widget onboardingArt(MockCtx c, {double? h, required double r}) {
  final p = c.p;
  return B(
    c,
    h: h,
    r: r,
    bg: p.raised,
    layers: [
      Radial(fx: 0.5, fy: 0.4, rx: c.u(340), ry: c.u(340), color: hexA(p.accent, 0x38), stop: 0.68),
      Disc(fx: 0.26, fy: 0.28, w: c.u(180), h: c.u(180), fill: hexA(p.accent, 0x30)),
      Disc(fx: 0.44, fy: 0.46, w: c.u(120), h: c.u(120), r: c.u(28), fill: hexA(p.chart[1], 0x38)),
    ],
  );
}

Widget dots(MockCtx c) {
  final p = c.p;
  return MRow(c, gap: 8, children: [
    for (var i = 0; i < 3; i++)
      B(c, w: i == 1 ? 22 : 8, h: 8, r: 999, bg: i == 1 ? p.accent : p.text, o: i == 1 ? 1 : 0.18),
  ]);
}

List<Widget> mobileOnboarding(MockCtx c) {
  final p = c.p;
  final tagline = c.item.source.tagline;
  if (c.isDesktop) {
    // Split screen: illustration left, the step's copy and actions right.
    return [
      MItem(
        grow: 1,
        child: MRow(c, align: MAlign.stretch, children: [
          MItem(
            flex: 1.1,
            child: MCol(c, pad: c.ins(24), children: [MItem(grow: 1, child: onboardingArt(c, r: 24))]),
          ),
          MItem(
            flex: 1,
            child: MCol(c, gap: 22, justify: MJustify.center, pad: c.ins(0, 96, 0, 64), children: [
              dots(c),
              T(c, tagline, size: 44, weight: 600, color: p.text, height: 1.15),
              lines(c, n: 2, w: 420, h: 10, gap: 10, col: p.muted, o: 0.35, last: 0.7),
              Padding(
                padding: EdgeInsets.only(top: c.u(14)),
                child: MRow(c, gap: 18, children: [
                  btn(c, label: 'Get started', w: 180, h: 52, r: 14, bg: p.accent, fg: p.accentFg, size: 16),
                  T(c, 'I already have an account', size: 13, weight: 450, color: p.muted),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    ];
  }
  final tablet = c.isTablet;
  return [
    Padding(
      padding: tablet ? c.ins(24, 96, 0) : c.ins(10, 20, 0),
      child: onboardingArt(c, h: tablet ? 560 : 420, r: tablet ? 28 : 24),
    ),
    MCol(c, gap: 16, align: MAlign.center, pad: tablet ? c.ins(56, 120, 0) : c.ins(44, 32, 0), children: [
      T(c, tagline, size: tablet ? 40 : 30, weight: 600, color: p.text, align: TextAlign.center, height: 1.2),
      B(
        c,
        wf: 0.88,
        child: MCol(c, gap: 9, align: MAlign.center, children: [
          line(c, wf: 1, h: 9, col: p.muted, o: 0.35),
          line(c, wf: 0.7, h: 9, col: p.muted, o: 0.35),
        ]),
      ),
    ]),
    MItem(
      autoBefore: true,
      child: MRow(c, justify: MJustify.center, pad: EdgeInsets.only(bottom: c.u(24)), children: [dots(c)]),
    ),
    MCol(c, gap: 14, align: MAlign.center, pad: tablet ? c.ins(0, 220, 48) : c.ins(0, 24, 34), children: [
      btn(c, label: 'Get started', w: 0, h: 54, r: 14, bg: p.accent, fg: p.accentFg, size: 16),
      T(c, 'I already have an account', size: 13, weight: 450, color: p.muted),
    ]),
  ];
}

/* ------------------------------------------------------------ profile */

List<Widget> profileStats(MockCtx c, {double? gap}) {
  final p = c.p;
  return [
    for (final (val, l) in const [('128', 'Sessions'), ('42h', 'Time'), ('9', 'Streak')])
      ConstrainedBox(
        constraints: BoxConstraints(minWidth: gap == null ? 0 : c.u(gap)),
        child: MCol(c, gap: 7, align: MAlign.center, children: [
          T(c, val, size: 20, weight: 600, color: p.text),
          T(c, l, size: 11, weight: 430, color: p.muted),
        ]),
      ),
  ];
}

Widget segments(MockCtx c, {double? w}) {
  final p = c.p;
  return B(
    c,
    w: w,
    bg: p.raised,
    r: 10,
    pad: c.ins(4),
    child: MRow(c, gap: 4, children: [
      for (final (i, t) in const ['Activity', 'Saved', 'Stats'].indexed)
        MItem(
          grow: 1,
          child: B(
            c,
            h: 32,
            r: 8,
            bg: i == 0 ? p.surface : null,
            align: Alignment.center,
            child: T(c, t, size: 12, weight: i == 0 ? 550 : 430, color: i == 0 ? p.text : p.muted),
          ),
        ),
    ]),
  );
}

Widget tiles(MockCtx c, {required int cols, required int n, required double h, required double gap}) {
  final p = c.p;
  return MGrid(c, cols: cols, gap: gap, children: [
    for (var i = 0; i < n; i++)
      B(
        c,
        h: h,
        r: 10,
        bg: p.raised,
        layers: [
          Linear(30.0 + i * 40, [hexA(p.chart[i % 4], 0x26), null], const [0, 0.7]),
        ],
      ),
  ]);
}

List<Widget> mobileProfile(MockCtx c) {
  final p = c.p;
  final name = c.item.source.name;
  if (!c.isMobile) {
    final desk = c.isDesktop;
    return [
      MItem(
        grow: 1,
        child: MCol(c, gap: desk ? 28 : 24, pad: desk ? c.ins(36, 48) : c.ins(16, 32, 24), children: [
          MRow(c, gap: desk ? 36 : 24, children: [
            circle(c, desk ? 132 : 104, bg: p.raised),
            MItem(
              grow: 1,
              child: MCol(c, gap: 14, children: [
                MRow(c, gap: 16, children: [
                  T(c, name, size: desk ? 26 : 22, weight: 600, color: p.text),
                  btn(c, label: 'Edit profile', w: 116, h: 34, r: 9, border: p.border, fg: p.text, size: 12),
                ]),
                line(c, w: desk ? 260 : 220, h: 9, col: p.muted, o: 0.35),
                MRow(
                  c,
                  gap: desk ? 28 : 20,
                  pad: EdgeInsets.only(top: c.u(6)),
                  children: profileStats(c, gap: 70),
                ),
              ]),
            ),
          ]),
          segments(c, w: desk ? 420 : 380),
          tiles(c, cols: desk ? 5 : 4, n: desk ? 10 : 12, h: desk ? 210 : 176, gap: desk ? 14 : 10),
        ]),
      ),
    ];
  }
  return [
    MRow(c, justify: MJustify.spaceBetween, pad: c.ins(12, 22, 20), children: [
      T(c, name, size: 17, weight: 600, color: p.text),
      circle(c, 30, bg: p.raised),
    ]),
    MCol(c, gap: 14, align: MAlign.center, children: [
      circle(c, 84, bg: p.raised),
      MCol(c, gap: 8, align: MAlign.center, children: [
        line(c, w: 120, h: 11, col: p.text, o: 0.6),
        line(c, w: 86, h: 8, col: p.muted, o: 0.35),
      ]),
    ]),
    MRow(c, justify: MJustify.spaceAround, pad: c.ins(24, 30), children: profileStats(c)),
    Padding(padding: EdgeInsets.symmetric(horizontal: c.u(22)), child: segments(c)),
    Padding(padding: c.ins(18, 22), child: tiles(c, cols: 3, n: 9, h: 98, gap: 8)),
  ];
}
