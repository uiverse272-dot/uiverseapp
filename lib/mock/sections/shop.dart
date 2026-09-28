import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// E-commerce sections: shop nav, campaign hero, category row, product grid.

Widget shopNav(MockCtx c) {
  final p = c.p;
  final name = T(c, c.item.source.name.toUpperCase(), size: c.v(19, 18, 16), weight: 600, color: p.text, track: 0.02);
  if (c.isMobile) {
    return B(
      c,
      pad: c.ins(16, 20),
      bb: p.border,
      child: MRow(c, justify: MJustify.spaceBetween, children: [
        burger(c, p.text),
        name,
        MRow(c, gap: 12, children: [circle(c, 26, bg: p.raised), circle(c, 26, bg: p.raised)]),
      ]),
    );
  }
  return B(
    c,
    pad: c.ins(22, c.v(56, 32, 0)),
    bb: p.border,
    child: MRow(c, justify: MJustify.spaceBetween, children: [
      MRow(c, gap: 30, children: [
        if (c.isTablet) burger(c, p.text),
        name,
        if (c.isDesktop)
          MRow(c, gap: 22, children: [
            for (final l in const ['New in', 'Collections', 'Archive', 'Journal'])
              T(c, l, size: 13, weight: 450, color: p.muted),
          ]),
      ]),
      MRow(c, gap: 14, children: [
        B(
          c,
          w: c.v(200, 180, 0),
          h: 32,
          r: 999,
          bg: p.raised,
          pad: EdgeInsets.symmetric(horizontal: c.u(14)),
          align: Alignment.centerLeft,
          child: line(c, w: 66, h: 7, col: p.muted, o: 0.45),
        ),
        circle(c, 30, bg: p.raised),
        circle(c, 30, bg: p.raised),
      ]),
    ]),
  );
}

Widget campaignHero(MockCtx c) {
  final p = c.p;
  final glow = Radial(fx: 0.78, fy: 0.4, rx: c.u(700), ry: c.u(500), color: hexA(p.accent, 0x22));
  if (c.isMobile) {
    // Image first, copy below — the product shot is the hook on a phone.
    return B(
      c,
      bg: p.raised,
      child: MCol(c, children: [
        B(c, h: 300, bg: p.surface, layers: [glow]),
        MCol(c, gap: 18, pad: c.ins(28, 20, 32), children: [
          T(c, c.item.source.tagline, size: 32, weight: 600, color: p.text),
          lines(c, n: 2, h: 10, gap: 10, col: p.muted, o: 0.4),
          btn(c, label: 'Shop the collection', w: 0, h: 48, r: 999, bg: p.accent, fg: p.accentFg, size: 15),
        ]),
      ]),
    );
  }
  final shotW = c.u(c.v(420, 300, 0));
  final shotH = c.u(c.v(400, 340, 0));
  return B(
    c,
    h: c.v(520, 460, 0),
    bg: p.raised,
    clip: true,
    pad: EdgeInsets.symmetric(horizontal: c.u(c.v(80, 40, 0))),
    align: Alignment.centerLeft,
    layers: [
      glow,
      Disc(
        fx: 1,
        dx: -c.u(c.v(80, 40, 0)) - shotW,
        fy: 0.5,
        dy: -shotH / 2,
        w: shotW,
        h: shotH,
        r: c.u(16),
        fill: op(p.surface, 0.9),
      ),
    ],
    child: B(
      c,
      maxW: c.v(560, 400, 0),
      child: MCol(c, gap: 22, children: [
        T(c, c.item.source.tagline, size: c.v(56, 44, 0), weight: 600, color: p.text),
        lines(c, n: 2, w: c.v(420, 340, 0), h: 10, gap: 10, col: p.muted, o: 0.4),
        btn(c, label: 'Shop the collection', w: 220, h: 48, r: 999, bg: p.accent, fg: p.accentFg, size: 15),
      ]),
    ),
  );
}

Widget categoryRow(MockCtx c) {
  final p = c.p;
  const cats = ['All', 'Outerwear', 'Knitwear', 'Trousers', 'Accessories', 'Archive'];
  return B(
    c,
    clip: true,
    pad: c.v(c.ins(28, 56), c.ins(24, 32), c.ins(18, 20)),
    child: MRow(c, gap: 10, children: [
      for (final (i, cat) in cats.indexed)
        B(
          c,
          h: 34,
          r: 999,
          bg: i == 0 ? p.accent : null,
          border: i == 0 ? null : p.border,
          pad: EdgeInsets.symmetric(horizontal: c.u(16)),
          align: Alignment.centerLeft,
          child: T(c, cat, size: 13, weight: 480, color: i == 0 ? p.accentFg : p.muted),
        ),
    ]),
  );
}

Widget productGrid(MockCtx c) {
  final p = c.p;
  return MGrid(
    c,
    cols: c.v(4, 3, 2),
    gap: c.v(18, 16, 12),
    rowGap: c.v(18, 24, 22),
    pad: c.v(c.ins(10, 56, 70), c.ins(8, 32, 56), c.ins(6, 20, 40)),
    children: [
      for (var i = 0; i < c.v(8, 6, 6); i++)
        MCol(c, gap: 12, children: [
          B(
            c,
            h: c.v(330, 290, 210),
            r: 10,
            bg: p.raised,
            layers: [
              Linear(140.0 + i * 24, [hexA(p.chart[i % 4], 0x1f), null], const [0, 0.6]),
            ],
          ),
          line(c, wf: (52 + noise(i, 13) * 32) / 100, h: 10, col: p.text, o: 0.6),
          line(c, w: 54, h: 9, col: p.muted, o: 0.4),
        ]),
    ],
  );
}
