import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// Agency sections: full-bleed hero and services list (work grid and CTA are
/// shared with portfolio / landing).

Widget agencyHero(MockCtx c) {
  final p = c.p;
  final side = c.v<double>(56, 32, 20);
  final blob = c.u(c.v(760, 560, 380));
  return B(
    c,
    h: c.v(880, 720, 600),
    bg: p.raised,
    clip: true,
    fill: true,
    layers: [
      Linear(160, [hexA(p.chart[0], 0x2e), hexA(p.chart[1], 0x1a), null], const [0, 0.45, 0.75]),
      // right: -8%, top: -12%
      Disc(fx: 1.08, dx: -blob, fy: -0.12, w: blob, h: blob, fill: hexA(p.accent, 0x18)),
    ],
    child: MCol(c, children: [
      MRow(c, justify: MJustify.spaceBetween, pad: c.ins(c.v(30, 26, 18), side), children: [
        T(c, c.item.source.name, size: 17, weight: 600, color: p.text),
        if (c.isMobile)
          burger(c, p.text)
        else
          MRow(c, gap: 26, children: [
            for (final l in const ['Work', 'Services', 'About', 'Contact'])
              T(c, l, size: 13, weight: 450, color: p.text, o: 0.7),
          ]),
      ]),
      MItem(
        autoBefore: true,
        child: MCol(c, gap: c.v(24, 22, 20), pad: c.ins(0, side, c.v(60, 48, 36)), children: [
          T(
            c,
            c.item.source.tagline,
            size: c.v(108, 72, 46),
            weight: 500,
            color: p.text,
            height: 0.98,
            maxW: c.v(1000, 700, 350),
          ),
          if (c.isMobile)
            MCol(c, gap: 14, children: [
              btn(c, label: 'View work', w: 0, h: 50, r: 999, bg: p.accent, fg: p.accentFg, size: 15),
              line(c, w: 200, h: 9, col: p.muted, o: 0.45),
            ])
          else
            MRow(c, gap: 16, children: [
              btn(c, label: 'View work', w: 150, h: 50, r: 999, bg: p.accent, fg: p.accentFg, size: 15),
              line(c, w: 220, h: 9, col: p.muted, o: 0.45),
            ]),
        ]),
      ),
    ]),
  );
}

Widget servicesList(MockCtx c) {
  final p = c.p;
  const svc = ['Brand identity', 'Digital product', 'Art direction', 'Motion'];
  return MCol(c, pad: c.v(c.ins(70, 56), c.ins(56, 32), c.ins(36, 20)), children: [
    for (final (i, s) in svc.indexed)
      B(
        c,
        bt: p.border,
        pad: c.ins(c.v(34, 28, 22), 0),
        child: MRow(c, justify: MJustify.spaceBetween, children: [
          MRow(c, gap: c.v(36, 28, 16), children: [
            T(c, '0${i + 1}', size: 13, weight: 450, color: p.muted),
            T(c, s, size: c.v(38, 30, 22), weight: 500, color: p.text),
          ]),
          circle(c, c.v(38, 34, 28), bg: p.raised),
        ]),
      ),
  ]);
}
