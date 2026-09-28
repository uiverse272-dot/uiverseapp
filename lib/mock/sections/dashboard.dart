import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// Dashboard sections: sidebar, top bar, stat cards, chart, activity, table.

const _dashNav = ['Overview', 'Reports', 'Customers', 'Transactions', 'Automations', 'Team', 'Settings'];

/// Tablet collapses to an icon rail; phones use [topBar]'s menu + tab bar.
Widget sidebar(MockCtx c) {
  final p = c.p;
  if (c.isTablet) {
    return B(
      c,
      w: 72,
      bg: p.surface,
      br: p.border,
      pad: c.ins(18, 0),
      fill: true,
      child: MCol(c, gap: 6, align: MAlign.center, children: [
        Padding(padding: EdgeInsets.only(bottom: c.u(20)), child: circle(c, 24, bg: p.accent)),
        for (var i = 0; i < _dashNav.length; i++)
          B(
            c,
            w: 40,
            h: 40,
            r: 9,
            bg: i == 1 ? p.raised : null,
            align: Alignment.center,
            child: B(c, w: 16, h: 16, r: 4, bg: p.text, o: i == 1 ? 0.75 : 0.25),
          ),
        MItem(autoBefore: true, child: circle(c, 30, bg: p.raised)),
      ]),
    );
  }
  return B(
    c,
    w: c.isMobile ? 290 : 248,
    bg: p.surface,
    br: p.border,
    pad: c.ins(18),
    fill: true,
    child: MCol(c, children: [
      Padding(
        padding: EdgeInsets.only(bottom: c.u(26)),
        child: MRow(c, gap: 10, children: [
          circle(c, 22, bg: p.accent),
          T(c, c.item.source.name, size: 15, weight: 600, color: p.text),
        ]),
      ),
      MItem(
        grow: 1,
        child: MCol(c, gap: 4, children: [
          for (var i = 0; i < _dashNav.length; i++)
            B(
              c,
              r: 7,
              bg: i == 1 ? p.raised : null,
              pad: c.ins(9, 10),
              child: MRow(c, gap: 10, children: [
                B(c, w: 15, h: 15, r: 4, bg: p.text, o: i == 1 ? 0.75 : 0.25),
                T(c, _dashNav[i], size: 13, weight: i == 1 ? 550 : 430, color: i == 1 ? p.text : p.muted),
              ]),
            ),
        ]),
      ),
      B(
        c,
        bt: p.border,
        pad: EdgeInsets.only(top: c.u(14)),
        child: MRow(c, gap: 10, children: [
          circle(c, 26, bg: p.raised),
          MCol(c, gap: 6, children: [
            line(c, w: 70, h: 8, col: p.text, o: 0.5),
            line(c, w: 48, h: 7, col: p.muted, o: 0.35),
          ]),
        ]),
      ),
    ]),
  );
}

Widget statCards(MockCtx c) {
  final p = c.p;
  const cards = [
    ('Net revenue', '£184,220', '+12.4%'),
    ('Active users', '9,318', '+4.1%'),
    ('Conversion', '3.42%', '-0.3%'),
    ('Avg. order', '£62.10', '+2.8%'),
  ];
  Widget tile(int i) {
    final (label, value, delta) = cards[i];
    final tone = i == 2 ? p.chart[3] : p.chart[1];
    return B(
      c,
      h: c.v(104, 100, 96),
      r: 12,
      bg: p.surface,
      border: p.border,
      pad: c.ins(c.v(16, 14, 13)),
      child: MCol(c, children: [
        T(c, label, size: 12, weight: 450, color: p.muted),
        gapBox(c, h: 12),
        T(c, value, size: c.v(26, 22, 20), weight: 600, color: p.text),
        gapBox(c, h: 10),
        // width: fit-content; the whole pill is at 16% opacity on the web.
        Align(
          alignment: Alignment.topLeft,
          heightFactor: 1,
          child: B(
            c,
            h: 20,
            r: 999,
            bg: tone,
            o: 0.16,
            pad: EdgeInsets.symmetric(horizontal: c.u(9)),
            align: Alignment.centerLeft,
            child: T(c, delta, size: 11, weight: 550, color: tone, o: 0.16),
          ),
        ),
      ]),
    );
  }

  if (c.isMobile) {
    return MGrid(c, cols: 2, gap: 10, children: [for (var i = 0; i < 4; i++) tile(i)]);
  }
  return MRow(c, gap: c.v(14, 12, 0), children: [
    for (var i = 0; i < 4; i++) MItem(grow: 1, child: tile(i)),
  ]);
}

/// Grows to fill its flex parent (the web section root has `flex-grow: 1`).
Widget chartPanel(MockCtx c) {
  final p = c.p;
  final n = c.v(34, 28, 16);
  return MItem(
    grow: 1,
    child: B(
      c,
      r: 12,
      bg: p.surface,
      border: p.border,
      pad: c.ins(c.v(18, 16, 14)),
      fill: true,
      child: MCol(c, children: [
        MRow(c, justify: MJustify.spaceBetween, children: [
          MCol(c, gap: 8, children: [
            T(c, 'Revenue', size: 14, weight: 550, color: p.text),
            line(c, w: 110, h: 8, col: p.muted, o: 0.35),
          ]),
          MRow(c, gap: 6, children: [
            for (final (i, t) in const ['7d', '30d', '90d'].indexed)
              B(
                c,
                h: 24,
                r: 6,
                bg: i == 1 ? p.raised : null,
                pad: EdgeInsets.symmetric(horizontal: c.u(10)),
                align: Alignment.centerLeft,
                child: T(c, t, size: 11, weight: 500, color: i == 1 ? p.text : p.muted),
              ),
          ]),
        ]),
        gapBox(c, h: 20),
        MItem(
          grow: 1,
          child: Bars(
            gap: c.u(c.v(5, 5, 4)),
            radius: c.u(3),
            sep: c.u(3),
            columns: [
              for (var i = 0; i < n; i++)
                [
                  BarSeg((12 + noise(i, 7) * 62) / 100, op(p.accent, 0.85)),
                  BarSeg((6 + noise(i, 11) * 22) / 100, op(p.text, 0.14)),
                ],
            ],
          ),
        ),
      ]),
    ),
  );
}

Widget activityList(MockCtx c) {
  final p = c.p;
  return B(
    c,
    w: c.isDesktop ? 340 : null,
    wf: c.isDesktop ? null : 1,
    r: 12,
    bg: p.surface,
    border: p.border,
    pad: c.ins(c.v(18, 16, 14)),
    child: MCol(c, children: [
      T(c, 'Recent activity', size: 14, weight: 550, color: p.text),
      gapBox(c, h: 18),
      MCol(c, gap: 16, children: [
        for (var i = 0; i < c.v(6, 4, 4); i++)
          MRow(c, gap: 11, children: [
            circle(c, 28, bg: p.raised),
            MItem(
              grow: 1,
              child: MCol(c, gap: 7, children: [
                line(c, wf: (58 + noise(i, 2) * 30) / 100, h: 8, col: p.text, o: 0.5),
                line(c, wf: (32 + noise(i, 5) * 22) / 100, h: 7, col: p.muted, o: 0.3),
              ]),
            ),
            line(c, w: 36, h: 8, col: p.muted, o: 0.3),
          ]),
      ]),
    ]),
  );
}

/// Tablet drops the least useful column; phones turn each row into a stacked item.
Widget dataTable(MockCtx c) {
  final p = c.p;
  final cols = c.isTablet ? const [3.0, 2.0, 1.4, 1.2] : const [3.0, 2.0, 2.0, 1.4, 1.2];
  final rows = c.v(6, 6, 5);
  final List<Widget> body;
  if (c.isMobile) {
    body = [
      for (var r = 0; r < rows; r++)
        B(
          c,
          bt: p.border,
          pad: c.ins(12, 0),
          child: MRow(c, gap: 11, children: [
            circle(c, 30, bg: p.raised),
            MItem(
              grow: 1,
              child: MCol(c, gap: 7, children: [
                line(c, wf: (50 + noise(r, 4) * 34) / 100, h: 9, col: p.text, o: 0.5),
                line(c, wf: 0.44, h: 8, col: p.muted, o: 0.3),
              ]),
            ),
            MCol(c, gap: 7, align: MAlign.end, children: [
              line(c, w: 52, h: 9, col: p.text, o: 0.5),
              B(c, w: 44, h: 16, r: 999, bg: p.chart[r % 3], o: 0.18),
            ]),
          ]),
        ),
    ];
  } else {
    body = [
      B(
        c,
        bb: p.border,
        pad: EdgeInsets.only(bottom: c.u(11)),
        child: MRow(c, gap: 16, children: [
          for (final f in cols) MItem(flex: f, child: line(c, wf: 0.52, h: 8, col: p.muted, o: 0.45)),
        ]),
      ),
      for (var r = 0; r < rows; r++)
        B(
          c,
          bb: r < rows - 1 ? p.border : null,
          pad: c.ins(13, 0),
          child: MRow(c, gap: 16, children: [
            MItem(
              flex: cols[0],
              child: MRow(c, gap: 10, children: [
                circle(c, 22, bg: p.raised),
                line(c, wf: (50 + noise(r, 4) * 34) / 100, h: 9, col: p.text, o: 0.5),
              ]),
            ),
            MItem(flex: cols[1], child: line(c, wf: 0.7, h: 9, col: p.muted, o: 0.3)),
            if (c.isDesktop) MItem(flex: cols[2], child: line(c, wf: 0.58, h: 9, col: p.muted, o: 0.3)),
            MItem(
              flex: cols[cols.length - 2],
              child: B(c, w: 64, h: 20, r: 999, bg: p.chart[r % 3], o: 0.18),
            ),
            MItem(
              flex: cols[cols.length - 1],
              child: B(c, align: Alignment.centerRight, child: line(c, w: 52, h: 9, col: p.text, o: 0.5)),
            ),
          ]),
        ),
    ];
  }
  return B(
    c,
    wf: 1,
    r: 12,
    bg: p.surface,
    border: p.border,
    pad: c.ins(c.v(18, 16, 14)),
    child: MCol(c, children: [
      Padding(
        padding: EdgeInsets.only(bottom: c.u(16)),
        child: MRow(c, justify: MJustify.spaceBetween, children: [
          T(c, 'Transactions', size: 14, weight: 550, color: p.text),
          MRow(c, gap: 8, children: [
            if (!c.isMobile) B(c, w: c.v(150, 130, 0), h: 28, r: 7, bg: p.raised),
            B(c, w: c.v(90, 80, 70), h: 28, r: 7, bg: p.raised),
          ]),
        ]),
      ),
      ...body,
    ]),
  );
}

Widget topBar(MockCtx c) {
  final p = c.p;
  return B(
    c,
    h: c.v(62, 58, 56),
    pad: EdgeInsets.symmetric(horizontal: c.u(c.v(22, 20, 16))),
    bb: p.border,
    fill: true,
    child: MRow(c, justify: MJustify.spaceBetween, children: [
      MRow(c, gap: 14, children: [
        if (c.isMobile) burger(c, p.text, s: 20),
        T(c, 'Overview', size: 16, weight: 600, color: p.text),
      ]),
      MRow(c, gap: c.v(12, 10, 10), children: [
        if (!c.isMobile)
          B(
            c,
            w: c.v(232, 180, 0),
            h: 32,
            r: 8,
            bg: p.raised,
            pad: EdgeInsets.symmetric(horizontal: c.u(11)),
            align: Alignment.centerLeft,
            child: line(c, w: 92, h: 8, col: p.muted, o: 0.4),
          ),
        B(c, w: 32, h: 32, r: 8, bg: p.raised),
        circle(c, 32, bg: p.raised),
      ]),
    ]),
  );
}
