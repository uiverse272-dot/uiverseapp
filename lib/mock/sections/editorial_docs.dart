import 'package:flutter/widgets.dart' hide Viewport;

import '../primitives.dart';

/// Editorial (masthead, lead story, article index) and docs sections.

Widget masthead(MockCtx c) {
  final p = c.p;
  final links = const ['Latest', 'Culture', 'Technology', 'Interviews', 'Archive'].take(c.v(5, 5, 4)).toList();
  return B(
    c,
    bb: p.border,
    pad: c.v(c.ins(40, 56, 22), c.ins(32, 32, 20), c.ins(22, 20, 16)),
    child: MCol(c, align: MAlign.center, children: [
      T(c, c.item.source.name, size: c.v(54, 44, 32), weight: 500, color: p.text, track: -0.01),
      gapBox(c, h: c.v(26, 22, 16)),
      MRow(c, gap: c.v(30, 24, 18), children: [
        for (final (i, l) in links.indexed)
          T(c, l, size: 13, weight: i == 0 ? 550 : 430, color: i == 0 ? p.text : p.muted),
      ]),
    ]),
  );
}

Widget leadStory(MockCtx c) {
  final p = c.p;
  return MCol(
    c,
    gap: c.v(26, 22, 18),
    pad: c.v(c.ins(50, 56), c.ins(36, 32), c.ins(20, 20, 28)),
    children: [
      B(
        c,
        h: c.v(520, 380, 220),
        r: 6,
        bg: p.raised,
        layers: [
          Linear(120, [hexA(p.chart[0], 0x22), hexA(p.chart[2], 0x14), null], const [0, 0.6, 1]),
        ],
      ),
      B(
        c,
        maxW: c.v(900, 720, 350),
        child: MCol(c, gap: c.v(18, 16, 14), children: [
          T(c, 'FEATURE', size: 12, weight: 550, color: p.accent, track: 0.06),
          T(c, c.item.source.tagline, size: c.v(46, 36, 26), weight: 500, color: p.text, height: 1.12),
          lines(c, n: 2, h: 11, gap: 11, col: p.muted, o: 0.4, last: 0.7),
          MRow(c, gap: 10, children: [
            circle(c, 26, bg: p.raised),
            line(c, w: 110, h: 8, col: p.muted, o: 0.4),
          ]),
        ]),
      ),
    ],
  );
}

const _articleTags = ['CULTURE', 'TECHNOLOGY', 'INTERVIEW', 'DESIGN'];

Widget articleIndex(MockCtx c) {
  final p = c.p;
  if (c.isMobile) {
    // Phones: thumbnail-left list rows, the standard news pattern.
    return B(
      c,
      bt: p.border,
      pad: c.ins(4, 20, 44),
      child: MCol(c, children: [
        for (final tag in _articleTags.take(3))
          B(
            c,
            bb: p.border,
            pad: c.ins(18, 0),
            child: MRow(c, gap: 14, align: MAlign.start, children: [
              B(c, w: 112, h: 84, r: 6, bg: p.raised),
              MItem(
                grow: 1,
                child: MCol(c, gap: 9, children: [
                  T(c, tag, size: 10.5, weight: 550, color: p.muted, track: 0.06),
                  lines(c, n: 2, h: 11, gap: 8, col: p.text, o: 0.55, last: 0.6),
                  line(c, wf: 0.5, h: 8, col: p.muted, o: 0.3),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
  final cards = [
    for (final tag in _articleTags.take(c.v(3, 4, 0)))
      MCol(c, gap: 14, pad: EdgeInsets.only(top: c.u(30)), children: [
        B(c, h: c.v(220, 200, 0), r: 6, bg: p.raised),
        T(c, tag, size: 11, weight: 550, color: p.muted, track: 0.06),
        lines(c, n: 2, h: 12, gap: 9, col: p.text, o: 0.55, last: 0.55),
        lines(c, n: 2, h: 8, gap: 8, col: p.muted, o: 0.3, last: 0.8),
      ]),
  ];
  if (c.isTablet) {
    return B(
      c,
      bt: p.border,
      pad: c.ins(10, 32, 56),
      child: MGrid(c, cols: 2, gap: 20, rowGap: 10, children: cards),
    );
  }
  return B(
    c,
    bt: p.border,
    pad: c.ins(20, 56, 70),
    child: MRow(c, gap: 24, align: MAlign.stretch, children: [
      for (final card in cards) MItem(grow: 1, child: card),
    ]),
  );
}

/* -------------------------------------------------------------- docs */
Widget docsSidebar(MockCtx c) {
  final p = c.p;
  const tree = [
    ('Getting started', ['Introduction', 'Installation', 'Quickstart']),
    ('Core concepts', ['Projects', 'Environments', 'Secrets']),
    ('Reference', ['CLI', 'REST API', 'Webhooks']),
  ];
  return B(
    c,
    w: c.v(268, 220, 290),
    br: p.border,
    pad: c.ins(c.v(26, 20, 22)),
    bg: c.isMobile ? p.bg : null,
    child: MCol(c, gap: c.v(26, 22, 22), children: [
      B(
        c,
        h: 32,
        r: 8,
        bg: p.raised,
        pad: EdgeInsets.symmetric(horizontal: c.u(11)),
        align: Alignment.centerLeft,
        child: line(c, w: 80, h: 8, col: p.muted, o: 0.4),
      ),
      for (final (gi, (group, items)) in tree.indexed)
        MCol(c, gap: 10, children: [
          T(c, group, size: 12, weight: 600, color: p.text),
          for (final (i, it) in items.indexed)
            // margin-left: -9 so the highlight's text lines up with the heading.
            Transform.translate(
              offset: Offset(-c.u(9), 0),
              child: B(
                c,
                pad: c.ins(6, 9),
                r: 6,
                bg: gi == 1 && i == 1 ? p.raised : null,
                child: T(
                  c,
                  it,
                  size: 12.5,
                  weight: gi == 1 && i == 1 ? 550 : 430,
                  color: gi == 1 && i == 1 ? p.text : p.muted,
                ),
              ),
            ),
        ]),
    ]),
  );
}

/// Phones: the docs tree hides behind a menu button, search stays one tap away.
Widget docsMobileBar(MockCtx c) {
  final p = c.p;
  return B(
    c,
    pad: c.ins(16, 20),
    bb: p.border,
    child: MRow(c, justify: MJustify.spaceBetween, children: [
      MRow(c, gap: 14, children: [
        burger(c, p.text, s: 20),
        T(c, '${c.item.source.name} Docs', size: 15, weight: 600, color: p.text),
      ]),
      B(c, w: 32, h: 32, r: 8, bg: p.raised),
    ]),
  );
}

const _codeRows = <List<(int, double)>>[
  [(0xFF7DD3FC, 60), (0xFFE5E7EB, 120)],
  [(0xFFC084FC, 40), (0xFFFDE68A, 90), (0xFFE5E7EB, 50)],
  [(0xFF7DD3FC, 80), (0xFF34D399, 140)],
  [(0xFF6B7280, 180)],
];

/// Grows to fill its flex parent.
Widget docsBody(MockCtx c) {
  final p = c.p;
  return MItem(
    grow: 1,
    child: MCol(
      c,
      gap: c.v(20, 18, 16),
      pad: c.v(c.ins(40, 48), c.ins(32, 32), c.ins(22, 20, 32)),
      children: [
        MRow(c, gap: 8, children: [
          T(c, 'Core concepts', size: 12, weight: 430, color: p.muted),
          T(c, '/', size: 12, weight: 430, color: p.muted, o: 0.5),
          T(c, 'Environments', size: 12, weight: 500, color: p.text),
        ]),
        T(c, 'Environments', size: c.v(36, 32, 28), weight: 600, color: p.text),
        if (c.isMobile)
          B(
            c,
            border: p.border,
            r: 8,
            pad: c.ins(10, 12),
            child: MRow(c, justify: MJustify.spaceBetween, children: [
              T(c, 'On this page', size: 12, weight: 500, color: p.text),
              B(c, w: 10, h: 10, r: 2, bg: p.muted, o: 0.4),
            ]),
          ),
        lines(c, n: 3, h: 10, gap: 11, col: p.muted, o: 0.35, last: 0.65),
        B(
          c,
          r: 10,
          bg: p.dark ? const Color(0xFF000000) : const Color(0xFF0E1116),
          pad: c.ins(c.v(18, 18, 14)),
          clip: true,
          child: MCol(c, gap: 9, children: [
            for (final (i, row) in _codeRows.indexed)
              MRow(c, gap: 8, pad: EdgeInsets.only(left: c.u(i == 3 ? 0 : i * 6.0)), children: [
                for (final (col, w) in row) B(c, w: w, h: 8, r: 3, bg: Color(col), o: 0.85),
              ]),
          ]),
        ),
        lines(c, n: 2, h: 10, gap: 11, col: p.muted, o: 0.35, last: 0.5),
        B(
          c,
          r: 10,
          border: p.accent,
          bg: hexA(p.accent, 0x12),
          pad: c.ins(16),
          child: lines(c, n: 2, h: 8, gap: 9, col: p.text, o: 0.4, last: 0.6),
        ),
      ],
    ),
  );
}

Widget docsToc(MockCtx c) {
  final p = c.p;
  return B(
    c,
    w: 220,
    pad: c.ins(44, 26),
    child: MCol(c, gap: 13, children: [
      T(c, 'ON THIS PAGE', size: 11, weight: 600, color: p.muted, track: 0.06),
      for (var i = 0; i < 5; i++)
        line(
          c,
          wf: (50 + noise(i, 31) * 40) / 100,
          h: 8,
          col: i == 1 ? p.accent : p.muted,
          o: i == 1 ? 0.9 : 0.3,
        ),
    ]),
  );
}
