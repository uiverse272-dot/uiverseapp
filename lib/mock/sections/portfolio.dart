import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// Portfolio sections: minimal nav, type statement, work grid, index list.

Widget minimalNav(MockCtx c) {
  final p = c.p;
  return MRow(
    c,
    justify: MJustify.spaceBetween,
    pad: c.v(c.ins(32, 56), c.ins(28, 32), c.ins(20, 20)),
    children: [
      T(c, c.item.source.name, size: 15, weight: 550, color: p.text),
      if (c.isMobile)
        T(c, 'Menu', size: 13, weight: 500, color: p.text)
      else
        MRow(c, gap: 26, children: [
          for (final l in const ['Work', 'Studio', 'Contact']) T(c, l, size: 13, weight: 450, color: p.muted),
        ]),
    ],
  );
}

Widget typeStatement(MockCtx c) {
  final p = c.p;
  return MCol(c, pad: c.v(c.ins(90, 56, 80), c.ins(72, 32, 60), c.ins(44, 20, 40)), children: [
    T(
      c,
      c.item.source.about,
      size: c.v(96, 64, 38),
      weight: 500,
      color: p.text,
      height: 1.04,
      maxW: c.v(1100, 740, 350),
    ),
    gapBox(c, h: c.v(48, 40, 30)),
    MRow(c, gap: 14, children: [
      B(
        c,
        h: 30,
        r: 999,
        border: p.border,
        pad: EdgeInsets.symmetric(horizontal: c.u(14)),
        align: Alignment.centerLeft,
        child: T(c, 'Selected work — 2026', size: 12, weight: 450, color: p.muted),
      ),
    ]),
  ]);
}

/// Two columns of case studies; one on phones. Shared with the agency page.
Widget workGrid(MockCtx c) {
  final p = c.p;
  return MGrid(
    c,
    cols: c.isMobile ? 1 : 2,
    gap: c.v(20, 16, 0),
    rowGap: c.v(20, 24, 28),
    pad: c.v(c.ins(0, 56, 60), c.ins(0, 32, 48), c.ins(0, 20, 36)),
    children: [
      for (var i = 0; i < 4; i++)
        MCol(c, gap: 14, children: [
          B(
            c,
            h: c.v(420, 300, 280),
            r: 12,
            bg: p.raised,
            layers: [
              Linear(40.0 + i * 60, [hexA(p.chart[i % 4], 0x26), null], const [0, 0.65]),
            ],
          ),
          MRow(c, justify: MJustify.spaceBetween, children: [
            line(c, wf: (40 + noise(i, 17) * 30) / 100, h: 11, col: p.text, o: 0.6),
            line(c, w: 60, h: 9, col: p.muted, o: 0.35),
          ]),
        ]),
    ],
  );
}

Widget indexList(MockCtx c) {
  final p = c.p;
  return MCol(c, pad: c.v(c.ins(20, 56, 70), c.ins(16, 32, 56), c.ins(12, 20, 40)), children: [
    for (var i = 0; i < 5; i++)
      B(
        c,
        bt: p.border,
        pad: c.ins(c.v(24, 22, 18), 0),
        child: MRow(c, justify: MJustify.spaceBetween, children: [
          MRow(c, gap: c.v(28, 24, 16), children: [
            T(c, '0${i + 1}', size: 12, weight: 450, color: p.muted),
            line(c, w: (140 + noise(i, 19) * 200) * c.v(1.0, 0.9, 0.6), h: 12, col: p.text, o: 0.6),
          ]),
          line(c, w: 70, h: 9, col: p.muted, o: 0.3),
        ]),
      ),
  ]);
}
