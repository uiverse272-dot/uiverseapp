import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// Checkout and auth sections.

/// `flex: 1.35` — must sit directly in a flex parent.
Widget checkoutForm(MockCtx c) {
  final p = c.p;
  const groups = [('Contact', 1), ('Delivery', 3), ('Payment', 2)];
  return MItem(
    flex: 1.35,
    child: MCol(
      c,
      gap: c.v(26, 24, 22),
      pad: c.v(c.ins(48, 56), c.ins(36, 32), c.ins(24, 20, 32)),
      children: [
        T(c, 'Checkout', size: 22, weight: 600, color: p.text),
        for (final (label, n) in groups)
          MCol(c, gap: 12, children: [
            T(c, label, size: 13, weight: 550, color: p.text),
            for (var i = 0; i < n; i++)
              B(
                c,
                h: 46,
                r: 9,
                border: p.border,
                pad: EdgeInsets.symmetric(horizontal: c.u(14)),
                align: Alignment.centerLeft,
                child: line(c, wf: (22 + noise(i, 23) * 24) / 100, h: 8, col: p.muted, o: 0.4),
              ),
          ]),
        MCol(c, gap: 10, children: [
          for (final (i, s) in const ['Standard — free', 'Express — £6.00'].indexed)
            B(
              c,
              border: i == 0 ? p.accent : p.border,
              r: 9,
              pad: c.ins(14),
              child: MRow(c, gap: 12, children: [
                circle(c, 16, bg: i == 0 ? p.accent : p.raised),
                T(c, s, size: 13, weight: 450, color: p.text),
              ]),
            ),
        ]),
        btn(c, label: 'Pay £128.00', w: 0, h: 50, r: 10, bg: p.accent, fg: p.accentFg, size: 15),
      ],
    ),
  );
}

/// `flex: 1` — must sit directly in a flex parent.
Widget orderSummary(MockCtx c) {
  final p = c.p;
  return MItem(
    flex: 1,
    child: B(
      c,
      bg: p.surface,
      bl: p.border,
      pad: c.ins(c.v(48, 36, 24), c.v(48, 28, 20)),
      child: MCol(c, gap: 18, children: [
        T(c, 'Order summary', size: 14, weight: 550, color: p.text),
        for (var i = 0; i < 3; i++)
          MRow(c, gap: 14, children: [
            B(c, w: c.v(64, 56, 52), h: c.v(78, 68, 64), r: 8, bg: p.raised),
            MItem(
              grow: 1,
              child: MCol(c, gap: 8, children: [
                line(c, wf: (50 + noise(i, 29) * 30) / 100, h: 9, col: p.text, o: 0.55),
                line(c, w: 70, h: 8, col: p.muted, o: 0.35),
              ]),
            ),
            line(c, w: 48, h: 9, col: p.text, o: 0.5),
          ]),
        gapBox(c, h: 6),
        for (final l in const ['Subtotal', 'Delivery', 'VAT'])
          MRow(c, justify: MJustify.spaceBetween, children: [
            T(c, l, size: 12, weight: 430, color: p.muted),
            line(c, w: 44, h: 8, col: p.muted, o: 0.4),
          ]),
        B(
          c,
          bt: p.border,
          pad: EdgeInsets.only(top: c.u(16)),
          child: MRow(c, justify: MJustify.spaceBetween, children: [
            T(c, 'Total', size: 15, weight: 600, color: p.text),
            T(c, '£128.00', size: 15, weight: 600, color: p.text),
          ]),
        ),
      ]),
    ),
  );
}

/// Phones fold the order summary into a disclosure bar above the form.
Widget orderSummaryBar(MockCtx c) {
  final p = c.p;
  return B(
    c,
    pad: c.ins(16, 20),
    bg: p.surface,
    bb: p.border,
    child: MRow(c, justify: MJustify.spaceBetween, children: [
      MRow(c, gap: 10, children: [
        B(c, w: 18, h: 18, r: 5, bg: p.accent, o: 0.25),
        T(c, 'Show order summary', size: 13, weight: 500, color: p.accent),
      ]),
      T(c, '£128.00', size: 15, weight: 600, color: p.text),
    ]),
  );
}

/// `flex: 1` — must sit directly in a flex parent.
Widget authCard(MockCtx c) {
  final p = c.p;
  return MItem(
    flex: 1,
    child: MCol(
      c,
      align: MAlign.center,
      justify: c.isMobile ? MJustify.start : MJustify.center,
      pad: c.v(c.ins(60), c.ins(60), c.ins(56, 24, 32)),
      children: [
        B(
          c,
          w: c.v<double?>(380, 420, null),
          wf: c.isMobile ? 1 : null,
          child: MCol(c, children: [
            Align(alignment: Alignment.topLeft, heightFactor: 1, child: circle(c, 34, bg: p.accent)),
            gapBox(c, h: 26),
            T(c, 'Sign in to ${c.item.source.name}', size: c.v(28, 28, 26), weight: 600, color: p.text),
            line(c, w: 230, h: 9, col: p.muted, o: 0.4, r: 4),
            gapBox(c, h: 30),
            MCol(c, gap: 12, children: [
              for (final f in const ['Email', 'Password'])
                MCol(c, gap: 8, children: [
                  T(c, f, size: 12, weight: 500, color: p.muted),
                  B(c, h: 46, r: 9, border: p.border),
                ]),
            ]),
            gapBox(c, h: 20),
            btn(c, label: 'Continue', w: 0, h: 48, r: 9, bg: p.accent, fg: p.accentFg, size: 15),
            gapBox(c, h: 22),
            MRow(c, gap: 12, children: [
              MItem(grow: 1, child: B(c, h: 1, bg: p.border)),
              T(c, 'or', size: 11, weight: 430, color: p.muted),
              MItem(grow: 1, child: B(c, h: 1, bg: p.border)),
            ]),
            gapBox(c, h: 20),
            MCol(c, gap: 10, children: [
              for (final s in const ['Continue with Google', 'Continue with GitHub'])
                btn(c, label: s, w: 0, h: 44, r: 9, border: p.border, fg: p.text, size: 13),
            ]),
          ]),
        ),
      ],
    ),
  );
}

/// `flex: 1` — must sit directly in a flex parent.
Widget authArt(MockCtx c) {
  final p = c.p;
  return MItem(
    flex: 1,
    child: B(
      c,
      bg: p.raised,
      clip: true,
      fill: true,
      layers: [
        Radial(fx: 0.3, fy: 0.3, rx: c.u(600), ry: c.u(600), color: hexA(p.accent, 0x30), stop: 0.65),
        Disc(fx: 0.18, fy: 0.26, w: c.u(300), h: c.u(300), stroke: hexA(p.accent, 0x44), strokeW: c.u(1)),
        Disc(fx: 0.34, fy: 0.42, w: c.u(220), h: c.u(220), fill: hexA(p.accent, 0x22)),
      ],
      child: MCol(
        c,
        justify: MJustify.end,
        pad: EdgeInsets.fromLTRB(c.u(64), 0, c.u(64), c.u(64)),
        children: [
          MCol(c, gap: 16, children: [
            T(
              c,
              '“The only tool our finance and product teams both open every morning.”',
              size: 26,
              weight: 450,
              color: p.text,
              height: 1.4,
            ),
            line(c, w: 160, h: 9, col: p.muted, o: 0.4),
          ]),
        ],
      ),
    ),
  );
}
