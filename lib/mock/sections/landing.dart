import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// Landing-page sections (web `sections.tsx`: nav … footer).
///
/// Every section takes the viewport it is drawn at via [MockCtx]. The desktop
/// values are the original design; tablet and mobile reflow.

const _navLinks = ['Product', 'Solutions', 'Docs', 'Pricing'];

/* ---------------------------------------------------------------- nav */
Widget navbar(MockCtx c) {
  final p = c.p;
  return MRow(
    c,
    justify: MJustify.spaceBetween,
    pad: c.ins(c.v(26, 22, 16), c.v(64, 32, 20)),
    children: [
      MRow(c, gap: 10, children: [
        circle(c, 22, bg: p.accent),
        T(c, c.item.source.name, size: c.v(18, 18, 17), weight: 600, color: p.text),
      ]),
      if (c.isDesktop)
        MRow(c, gap: 34, children: [
          for (final l in _navLinks) T(c, l, size: 14, weight: 450, color: p.muted),
        ]),
      MRow(c, gap: 16, children: [
        if (!c.isMobile) ...[
          T(c, 'Sign in', size: 14, weight: 450, color: p.muted),
          btn(c, label: 'Get started', w: 124, h: 38, r: 8, bg: p.accent, fg: p.accentFg, size: 14),
        ],
        if (!c.isDesktop) burger(c, p.text),
      ]),
    ],
  );
}

/* --------------------------------------------------------------- hero */
Widget hero(MockCtx c) {
  final p = c.p;
  final words = c.item.source.tagline.split(' ');
  final mid = (words.length / 2).ceil();
  final ctas = [
    btn(c, label: 'Start free', w: c.v(148, 148, 0), h: 50, r: 10, bg: p.accent, fg: p.accentFg, size: 16),
    btn(c, label: 'Book a demo', w: c.v(148, 148, 0), h: 50, r: 10, border: p.border, fg: p.text, size: 16),
  ];
  return MCol(
    c,
    align: MAlign.center,
    pad: c.v(c.ins(96, 64, 72), c.ins(72, 32, 56), c.ins(44, 20, 40)),
    children: [
      Padding(
        padding: EdgeInsets.only(bottom: c.u(c.v(28, 24, 20))),
        child: B(
          c,
          h: 30,
          r: 999,
          bg: p.raised,
          pad: EdgeInsets.symmetric(horizontal: c.u(14)),
          align: Alignment.centerLeft,
          child: T(
            c,
            '${c.item.industry.toUpperCase().replaceFirst('-', ' ')} · NEW',
            size: 12,
            weight: 500,
            color: p.muted,
          ),
        ),
      ),
      T(
        c,
        '${words.sublist(0, mid).join(' ')}\n${words.sublist(mid).join(' ')}',
        size: c.v(68, 52, 36),
        weight: 600,
        color: p.text,
        align: TextAlign.center,
        maxW: c.v(900, 700, 350),
      ),
      gapBox(c, h: c.v(26, 22, 18)),
      B(
        c,
        w: c.v<double?>(520, 460, null),
        wf: c.isMobile ? 1 : null,
        child: MCol(c, gap: 9, align: MAlign.center, children: [
          line(c, wf: 0.86, h: 12, col: p.muted, o: 0.4),
          line(c, wf: 0.62, h: 12, col: p.muted, o: 0.4),
        ]),
      ),
      if (c.isMobile) ...[
        gapBox(c, h: 28),
        B(c, wf: 1, child: MCol(c, gap: 10, children: ctas)),
      ] else ...[
        gapBox(c, h: 34),
        MRow(c, gap: 12, children: ctas),
      ],
      appPreview(c),
    ],
  );
}

Widget appPreview(MockCtx c) {
  final p = c.p;
  final stats = c.isMobile ? const [0, 1] : const [0, 1, 2];
  const values = ['48.2k', '3.1%', '912'];
  final n = c.v(28, 22, 14);
  return Padding(
    padding: EdgeInsets.only(top: c.u(c.v(64, 48, 36))),
    child: B(
      c,
      w: c.v(1160, 770, 350),
      h: c.v(620, 440, 300),
      r: c.v(16, 14, 12),
      bg: p.surface,
      border: p.border,
      clip: true,
      fill: true,
      child: MRow(c, align: MAlign.stretch, children: [
        if (!c.isMobile)
          B(
            c,
            w: c.v(200, 160, 0),
            pad: c.ins(18),
            br: p.border,
            child: MCol(c, gap: 12, children: [
              MRow(c, gap: 8, children: [
                circle(c, 16, bg: p.accent),
                line(c, w: 64, h: 8, col: p.text, o: 0.5),
              ]),
              gapBox(c, h: 10),
              for (var i = 0; i < 6; i++)
                MRow(c, gap: 9, children: [
                  B(c, w: 14, h: 14, r: 4, bg: p.text, o: i == 1 ? 0.7 : 0.2),
                  line(
                    c,
                    w: c.v(i == 1 ? 84 : 60 + i * 6, i == 1 ? 70 : 48 + i * 5, 0),
                    h: 8,
                    col: p.text,
                    o: i == 1 ? 0.55 : 0.18,
                  ),
                ]),
            ]),
          ),
        MItem(
          grow: 1,
          child: MCol(c, gap: c.v(14, 12, 10), pad: c.ins(c.v(20, 18, 14)), children: [
            MRow(c, justify: MJustify.spaceBetween, children: [
              line(c, w: c.v(130, 110, 90), h: 12, col: p.text, o: 0.6),
              MRow(c, gap: 8, children: [
                B(c, w: c.v(78, 60, 44), h: 26, r: 6, bg: p.raised),
                B(c, w: 26, h: 26, r: 6, bg: p.raised),
              ]),
            ]),
            MRow(c, gap: c.v(12, 10, 8), children: [
              for (final i in stats)
                MItem(
                  grow: 1,
                  child: B(
                    c,
                    h: c.v(78, 70, 64),
                    r: 10,
                    bg: p.raised,
                    pad: c.ins(12),
                    child: MCol(c, children: [
                      line(c, w: 54, h: 7, col: p.muted, o: 0.5),
                      gapBox(c, h: 10),
                      T(c, values[i], size: c.v(22, 20, 18), weight: 600, color: p.text),
                    ]),
                  ),
                ),
            ]),
            MItem(
              grow: 1,
              child: B(
                c,
                r: 10,
                bg: p.raised,
                pad: c.ins(c.v(16, 14, 12)),
                fill: true,
                child: Bars(
                  gap: c.u(c.v(6, 5, 4)),
                  radius: c.u(3),
                  columns: [
                    for (var i = 0; i < n; i++)
                      [
                        BarSeg(
                          (18 + noise(i, 3) * 72) / 100,
                          i % 4 == 0 ? op(p.accent, 0.9) : op(p.text, 0.16),
                        ),
                      ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    ),
  );
}

/* --------------------------------------------------------- logo cloud */
Widget logoCloud(MockCtx c) {
  final p = c.p;
  final logos = c.isMobile ? const [96.0, 118.0, 84.0, 100.0] : const [96.0, 118.0, 84.0, 130.0, 100.0];
  final items = [
    for (final w in logos)
      MRow(c, gap: 8, children: [
        circle(c, 18, bg: p.text, o: 0.22),
        line(c, w: c.v(w, w * 0.8, w * 0.7), h: 13, col: p.text, o: 0.22, r: 4),
      ]),
  ];
  return MCol(
    c,
    gap: c.v(24, 22, 20),
    align: MAlign.center,
    pad: c.v(c.ins(40, 64, 80), c.ins(32, 32, 60), c.ins(28, 20, 44)),
    children: [
      line(c, w: c.v(220, 200, 180), h: 9, col: p.muted, o: 0.35),
      if (c.isMobile)
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: c.u(22),
          runSpacing: c.u(18),
          children: items,
        )
      else
        MRow(c, gap: c.v(56, 34, 22), justify: MJustify.center, children: items),
    ],
  );
}

/* ------------------------------------------------------- feature grid */
Widget featureGrid(MockCtx c) {
  final p = c.p;
  const titles = ['Connected data', 'Live collaboration', 'Audit everything'];
  Widget card(int i) => B(
        c,
        h: c.v<double?>(258, 240, null),
        r: 14,
        bg: p.surface,
        border: p.border,
        pad: c.ins(c.v(26, 24, 22)),
        child: MCol(c, children: [
          B(c, w: 42, h: 42, r: 11, bg: p.accent, o: 0.16),
          gapBox(c, h: 22),
          T(c, titles[i], size: 19, weight: 560, color: p.text),
          gapBox(c, h: 14),
          lines(c, n: 3, h: 9, gap: 9, col: p.muted, o: 0.34, last: 0.7),
          gapBox(c, h: 26),
          MRow(c, gap: 7, children: [line(c, w: 70, h: 9, col: p.accent, o: 0.9)]),
        ]),
      );
  return MCol(
    c,
    gap: c.v(40, 34, 28),
    align: MAlign.center,
    pad: c.v(c.ins(40, 64, 90), c.ins(32, 32, 70), c.ins(28, 20, 52)),
    children: [
      MCol(c, gap: 14, align: MAlign.center, children: [
        T(c, 'Everything in one place',
            size: c.v(40, 34, 26), weight: 600, color: p.text, align: TextAlign.center),
        line(c, w: c.v(420, 380, 280), h: 11, col: p.muted, o: 0.4),
      ]),
      B(
        c,
        wf: 1,
        child: c.isDesktop
            ? MRow(c, gap: 24, children: [for (var i = 0; i < 3; i++) MItem(grow: 1, child: card(i))])
            : MGrid(c, cols: c.v(3, 2, 1), gap: c.v(24, 18, 14), children: [
                for (var i = 0; i < 3; i++) MItem(span: c.isTablet && i == 2 ? 2 : 1, child: card(i)),
              ]),
      ),
    ],
  );
}

/* --------------------------------------------------------- stats band */
Widget statsBand(MockCtx c) {
  final p = c.p;
  const stats = [
    ('99.98%', 'Uptime'),
    ('2.4M', 'Events / day'),
    ('140ms', 'p95 latency'),
    ('38', 'Integrations'),
  ];
  final cells = [
    for (final (val, l) in stats)
      MCol(c, gap: 10, align: MAlign.center, children: [
        T(c, val, size: c.v(42, 34, 30), weight: 600, color: p.text),
        T(c, l, size: 13, weight: 450, color: p.muted),
      ]),
  ];
  if (c.isMobile) {
    return B(
      c,
      bt: p.border,
      bb: p.border,
      pad: c.ins(36, 20),
      child: MGrid(c, cols: 2, gap: 16, rowGap: 30, children: cells),
    );
  }
  return B(
    c,
    bt: p.border,
    bb: p.border,
    pad: c.ins(c.v(56, 44, 0), c.v(120, 48, 0)),
    child: MRow(c, justify: MJustify.spaceBetween, children: cells),
  );
}

/* -------------------------------------------------------- testimonial */
Widget testimonial(MockCtx c) {
  final p = c.p;
  return MCol(
    c,
    gap: c.v(30, 26, 22),
    align: MAlign.center,
    pad: c.v(c.ins(90, 220), c.ins(72, 72), c.ins(48, 22)),
    children: [
      T(
        c,
        '“We replaced four tools with ${c.item.source.name} in a fortnight and nobody asked for the old ones back.”',
        size: c.v(30, 26, 20),
        weight: 450,
        color: p.text,
        align: TextAlign.center,
        height: 1.45,
      ),
      MRow(c, gap: 12, children: [
        circle(c, 40, bg: p.raised),
        MCol(c, gap: 7, justify: MJustify.center, children: [
          line(c, w: 92, h: 9, col: p.text, o: 0.6),
          line(c, w: 130, h: 8, col: p.muted, o: 0.4),
        ]),
      ]),
    ],
  );
}

/* ----------------------------------------------------------- cta band */
Widget ctaBand(MockCtx c) {
  final p = c.p;
  return Padding(
    padding: c.v(c.ins(20, 64, 80), c.ins(16, 32, 64), c.ins(12, 16, 44)),
    child: B(
      c,
      bg: p.raised,
      r: c.v(20, 18, 16),
      pad: c.ins(c.v(64, 56, 40), c.v(0, 32, 20)),
      child: MCol(c, gap: c.v(24, 22, 18), align: MAlign.center, children: [
        T(c, 'Start building today',
            size: c.v(38, 32, 24), weight: 600, color: p.text, align: TextAlign.center),
        line(c, w: c.v(340, 320, 240), h: 11, col: p.muted, o: 0.4),
        btn(c, label: 'Create an account', w: 196, h: 50, r: 10, bg: p.accent, fg: p.accentFg, size: 16),
      ]),
    ),
  );
}

/* ------------------------------------------------------------- footer */
Widget footer(MockCtx c) {
  final p = c.p;
  final brand = MCol(c, gap: 14, children: [
    MRow(c, gap: 10, children: [
      circle(c, 20, bg: p.accent),
      T(c, c.item.source.name, size: 16, weight: 600, color: p.text),
    ]),
    line(c, w: 180, h: 9, col: p.muted, o: 0.3),
  ]);
  final cols = [
    for (var k = 0; k < 4; k++)
      B(
        c,
        w: c.isMobile ? null : 130,
        child: MCol(c, gap: 13, children: [
          line(c, w: 64, h: 9, col: p.text, o: 0.55),
          for (var i = 0; i < 4; i++) line(c, w: 78.0 - i * 8 + k * 5, h: 8, col: p.muted, o: 0.28),
        ]),
      ),
  ];
  final Widget body;
  if (c.isDesktop) {
    body = MRow(c, justify: MJustify.spaceBetween, align: MAlign.start, children: [brand, ...cols]);
  } else {
    body = MCol(c, gap: c.v(0, 36, 30), children: [
      brand,
      if (c.isTablet)
        MRow(c, justify: MJustify.spaceBetween, align: MAlign.start, children: cols)
      else
        MGrid(c, cols: 2, gap: 20, rowGap: 28, children: cols),
    ]);
  }
  return B(
    c,
    bt: p.border,
    pad: c.v(c.ins(54, 64), c.ins(44, 32), c.ins(36, 20)),
    child: body,
  );
}
