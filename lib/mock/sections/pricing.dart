import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// Pricing sections: tiers, billing toggle, section header, FAQ.

Widget pricingTiers(MockCtx c) {
  final p = c.p;
  const tiers = [('Free', '£0', 4), ('Pro', '£18', 6), ('Team', '£42', 7)];
  Widget card(int i) {
    final (name, price, feats) = tiers[i];
    // Phones show the headline features only — the full list is a tap away.
    final shown = c.isMobile && feats > 4 ? 4 : feats;
    return B(
      c,
      r: 16,
      bg: i == 1 ? p.surface : null,
      border: i == 1 ? p.accent : p.border,
      pad: c.ins(c.v(28, 20, 22)),
      child: MCol(c, children: [
        MRow(c, justify: MJustify.spaceBetween, children: [
          T(c, name, size: 16, weight: 600, color: p.text),
          if (i == 1)
            B(
              c,
              h: 22,
              r: 999,
              bg: p.accent,
              pad: EdgeInsets.symmetric(horizontal: c.u(10)),
              align: Alignment.centerLeft,
              child: T(c, 'Popular', size: 11, weight: 600, color: p.accentFg),
            ),
        ]),
        gapBox(c, h: 20),
        MRow(c, gap: 6, align: MAlign.end, children: [
          T(c, price, size: c.v(44, 36, 38), weight: 600, color: p.text),
          Padding(
            padding: EdgeInsets.only(bottom: c.u(8)),
            child: T(c, '/month', size: 13, weight: 430, color: p.muted),
          ),
        ]),
        btn(
          c,
          label: i == 0 ? 'Start free' : 'Choose plan',
          w: 0,
          h: 42,
          r: 9,
          bg: i == 1 ? p.accent : null,
          border: i == 1 ? null : p.border,
          fg: i == 1 ? p.accentFg : p.text,
          size: 14,
        ),
        gapBox(c, h: 24),
        MCol(c, gap: 13, children: [
          for (var f = 0; f < shown; f++)
            MRow(c, gap: 10, children: [
              circle(c, 15, bg: p.accent, o: 0.2),
              line(c, wf: (52 + noise(f, i + 1) * 36) / 100, h: 8, col: p.text, o: 0.4),
            ]),
        ]),
      ]),
    );
  }

  if (c.isMobile) {
    return MCol(c, gap: 14, pad: c.ins(0, 20), children: [for (var i = 0; i < 3; i++) card(i)]);
  }
  return MRow(
    c,
    gap: c.v(20, 14, 0),
    align: MAlign.stretch,
    justify: MJustify.center,
    pad: c.ins(0, c.v(120, 32, 0)),
    children: [for (var i = 0; i < 3; i++) MItem(grow: 1, maxMain: c.u(340), child: card(i))],
  );
}

Widget billingToggle(MockCtx c) {
  final p = c.p;
  return MRow(c, justify: MJustify.center, pad: c.ins(10, 0, c.v(44, 36, 28)), children: [
    B(
      c,
      bg: p.raised,
      r: 999,
      pad: c.ins(4),
      child: MRow(c, gap: 4, children: [
        for (final (i, t) in const ['Monthly', 'Annual'].indexed)
          B(
            c,
            h: 34,
            r: 999,
            bg: i == 1 ? p.surface : null,
            pad: EdgeInsets.symmetric(horizontal: c.u(20)),
            align: Alignment.centerLeft,
            child: T(c, t, size: 13, weight: i == 1 ? 550 : 430, color: i == 1 ? p.text : p.muted),
          ),
      ]),
    ),
  ]);
}

Widget sectionHeader(MockCtx c, {String? title, String? sub}) {
  final p = c.p;
  return MCol(
    c,
    gap: 16,
    align: MAlign.center,
    pad: c.v(c.ins(80, 64, 30), c.ins(64, 32, 26), c.ins(44, 20, 20)),
    children: [
      T(c, title ?? 'Simple, honest pricing',
          size: c.v(48, 40, 30), weight: 600, color: p.text, align: TextAlign.center),
      line(c, w: c.v(sub != null ? 300 : 420, 380, 280), h: 11, col: p.muted, o: 0.4),
    ],
  );
}

Widget faq(MockCtx c) {
  final p = c.p;
  return MCol(c, pad: c.v(c.ins(70, 300), c.ins(56, 64), c.ins(40, 20)), children: [
    for (var i = 0; i < 4; i++)
      B(
        c,
        bb: p.border,
        pad: c.ins(22, 0),
        child: MRow(c, justify: MJustify.spaceBetween, children: [
          line(c, wf: (40 + noise(i, 9) * 30) / 100, h: 11, col: p.text, o: 0.6),
          B(c, w: 13, h: 13, r: 2, bg: p.muted, o: 0.4),
        ]),
      ),
  ]);
}
