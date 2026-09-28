/// Content palettes for mock previews (§2.2), ported from web `palettes.ts`.
/// The web ships 16 palettes; order and values here match it exactly.
library;

import 'package:flutter/painting.dart';

import 'models.dart';

const Palette kCarbon = Palette(
  key: 'carbon',
  name: 'Carbon',
  bg: Color(0xFF0B0D10),
  surface: Color(0xFF131720),
  raised: Color(0xFF1B212C),
  text: Color(0xFFF2F5F8),
  muted: Color(0xFF8A94A6),
  accent: Color(0xFF5B8CFF),
  accentFg: Color(0xFF04070D),
  border: Color(0xFF222835),
  chart: <Color>[
    Color(0xFF5B8CFF),
    Color(0xFF3EC9A7),
    Color(0xFFF5B544),
    Color(0xFFFF6B6B),
  ],
  dark: true,
);

const Palette kLedger = Palette(
  key: 'ledger',
  name: 'Ledger',
  bg: Color(0xFF07100C),
  surface: Color(0xFF0E1A14),
  raised: Color(0xFF15251C),
  text: Color(0xFFEAF6EF),
  muted: Color(0xFF7E9A8B),
  accent: Color(0xFF37E29A),
  accentFg: Color(0xFF04150D),
  border: Color(0xFF1B2C22),
  chart: <Color>[
    Color(0xFF37E29A),
    Color(0xFF7FD4FF),
    Color(0xFFFFD166),
    Color(0xFFFF8A7A),
  ],
  dark: true,
);

const Palette kViolet = Palette(
  key: 'violet',
  name: 'Violet AI',
  bg: Color(0xFF0A0713),
  surface: Color(0xFF140E22),
  raised: Color(0xFF1E1533),
  text: Color(0xFFF4F0FF),
  muted: Color(0xFF9A8FBF),
  accent: Color(0xFFA06BFF),
  accentFg: Color(0xFF0A0713),
  border: Color(0xFF241A3B),
  chart: <Color>[
    Color(0xFFA06BFF),
    Color(0xFF6BE3FF),
    Color(0xFFFF7AD9),
    Color(0xFFFFD36B),
  ],
  dark: true,
);

const Palette kPaper = Palette(
  key: 'paper',
  name: 'Paper',
  bg: Color(0xFFFFFFFF),
  surface: Color(0xFFFAFAF9),
  raised: Color(0xFFF4F4F2),
  text: Color(0xFF14110E),
  muted: Color(0xFF7A736B),
  accent: Color(0xFF14110E),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFE7E5E1),
  chart: <Color>[
    Color(0xFF14110E),
    Color(0xFFA8A29A),
    Color(0xFFD6D2CB),
    Color(0xFF8C7D6B),
  ],
  dark: false,
);

const Palette kPorcelain = Palette(
  key: 'porcelain',
  name: 'Porcelain',
  bg: Color(0xFFF7F8FA),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFEEF1F6),
  text: Color(0xFF0E1420),
  muted: Color(0xFF69748A),
  accent: Color(0xFF2C5CFF),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFE2E6EE),
  chart: <Color>[
    Color(0xFF2C5CFF),
    Color(0xFF19C39A),
    Color(0xFFFFAE2E),
    Color(0xFFFF5F5F),
  ],
  dark: false,
);

const Palette kSand = Palette(
  key: 'sand',
  name: 'Sand',
  bg: Color(0xFFFBF7F0),
  surface: Color(0xFFFFFDF9),
  raised: Color(0xFFF2EADF),
  text: Color(0xFF231C12),
  muted: Color(0xFF87786A),
  accent: Color(0xFFB4571F),
  accentFg: Color(0xFFFFF8F0),
  border: Color(0xFFEADFCF),
  chart: <Color>[
    Color(0xFFB4571F),
    Color(0xFFD8A14A),
    Color(0xFF6E7F5B),
    Color(0xFF9C4B3C),
  ],
  dark: false,
);

const Palette kInk = Palette(
  key: 'ink',
  name: 'Ink',
  bg: Color(0xFF111111),
  surface: Color(0xFF191919),
  raised: Color(0xFF232323),
  text: Color(0xFFFAFAFA),
  muted: Color(0xFF8F8F8F),
  accent: Color(0xFFFAFAFA),
  accentFg: Color(0xFF111111),
  border: Color(0xFF2A2A2A),
  chart: <Color>[
    Color(0xFFFAFAFA),
    Color(0xFF8F8F8F),
    Color(0xFF5A5A5A),
    Color(0xFF3A3A3A),
  ],
  dark: true,
);

const Palette kCitrus = Palette(
  key: 'citrus',
  name: 'Citrus',
  bg: Color(0xFFFFFDF5),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFFFF6DC),
  text: Color(0xFF1A1703),
  muted: Color(0xFF7E7856),
  accent: Color(0xFFFF7A1A),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFF0E8CC),
  chart: <Color>[
    Color(0xFFFF7A1A),
    Color(0xFFFFC94D),
    Color(0xFF3BB273),
    Color(0xFF3B6FB2),
  ],
  dark: false,
);

const Palette kOcean = Palette(
  key: 'ocean',
  name: 'Ocean',
  bg: Color(0xFF05161F),
  surface: Color(0xFF0B2231),
  raised: Color(0xFF123043),
  text: Color(0xFFEAF7FF),
  muted: Color(0xFF7FA3B8),
  accent: Color(0xFF31C5F5),
  accentFg: Color(0xFF05161F),
  border: Color(0xFF17394C),
  chart: <Color>[
    Color(0xFF31C5F5),
    Color(0xFF5BE0C0),
    Color(0xFFFFD479),
    Color(0xFFFF8BA0),
  ],
  dark: true,
);

const Palette kRose = Palette(
  key: 'rose',
  name: 'Rose',
  bg: Color(0xFFFFF8F9),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFFDEDF0),
  text: Color(0xFF2B0F16),
  muted: Color(0xFF8C6670),
  accent: Color(0xFFE5486E),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFF6DDE3),
  chart: <Color>[
    Color(0xFFE5486E),
    Color(0xFFF59BAF),
    Color(0xFF7A5CD1),
    Color(0xFF3CB9A0),
  ],
  dark: false,
);

const Palette kForest = Palette(
  key: 'forest',
  name: 'Forest',
  bg: Color(0xFFF6F8F5),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFE9EFE7),
  text: Color(0xFF101A12),
  muted: Color(0xFF63776A),
  accent: Color(0xFF2E6B47),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFDEE6DB),
  chart: <Color>[
    Color(0xFF2E6B47),
    Color(0xFF7FB08D),
    Color(0xFFC9A227),
    Color(0xFF4F6D9E),
  ],
  dark: false,
);

const Palette kNoir = Palette(
  key: 'noir',
  name: 'Noir Luxe',
  bg: Color(0xFF0C0A08),
  surface: Color(0xFF151210),
  raised: Color(0xFF1E1A16),
  text: Color(0xFFF3EDE4),
  muted: Color(0xFF9B8F80),
  accent: Color(0xFFC8A96A),
  accentFg: Color(0xFF100D0A),
  border: Color(0xFF26211B),
  chart: <Color>[
    Color(0xFFC8A96A),
    Color(0xFF8C7A5B),
    Color(0xFFF3EDE4),
    Color(0xFF5C5142),
  ],
  dark: true,
);

const Palette kElectric = Palette(
  key: 'electric',
  name: 'Electric',
  bg: Color(0xFF08090B),
  surface: Color(0xFF101216),
  raised: Color(0xFF181C22),
  text: Color(0xFFF7F8FA),
  muted: Color(0xFF858C99),
  accent: Color(0xFFC8FF2D),
  accentFg: Color(0xFF0B0D07),
  border: Color(0xFF1E232B),
  chart: <Color>[
    Color(0xFFC8FF2D),
    Color(0xFF2DE2FF),
    Color(0xFFFF4D8D),
    Color(0xFFFFB020),
  ],
  dark: true,
);

const Palette kCloud = Palette(
  key: 'cloud',
  name: 'Cloud',
  bg: Color(0xFFFAFBFF),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFEFF2FD),
  text: Color(0xFF0D1024),
  muted: Color(0xFF6B7194),
  accent: Color(0xFF4B44E8),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFE5E8F7),
  chart: <Color>[
    Color(0xFF4B44E8),
    Color(0xFF28C2B4),
    Color(0xFFFFB43D),
    Color(0xFFFF6F91),
  ],
  dark: false,
);

const Palette kConcrete = Palette(
  key: 'concrete',
  name: 'Concrete',
  bg: Color(0xFFEFEFEC),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFE3E3DE),
  text: Color(0xFF101010),
  muted: Color(0xFF6E6E68),
  accent: Color(0xFF0F0F0F),
  accentFg: Color(0xFFF3F3EF),
  border: Color(0xFFD8D8D2),
  chart: <Color>[
    Color(0xFF0F0F0F),
    Color(0xFF767670),
    Color(0xFFB4B4AE),
    Color(0xFFE0402F),
  ],
  dark: false,
);

const Palette kMint = Palette(
  key: 'mint',
  name: 'Mint',
  bg: Color(0xFFF4FBF9),
  surface: Color(0xFFFFFFFF),
  raised: Color(0xFFE4F5F0),
  text: Color(0xFF06201A),
  muted: Color(0xFF5F8078),
  accent: Color(0xFF00A884),
  accentFg: Color(0xFFFFFFFF),
  border: Color(0xFFD7EBE5),
  chart: <Color>[
    Color(0xFF00A884),
    Color(0xFF5AC8FA),
    Color(0xFFFFC53D),
    Color(0xFFFF7A85),
  ],
  dark: false,
);

/// All palettes, in web order (`PALETTES`).
const List<Palette> kPalettes = <Palette>[
  kCarbon,
  kLedger,
  kViolet,
  kPaper,
  kPorcelain,
  kSand,
  kInk,
  kCitrus,
  kOcean,
  kRose,
  kForest,
  kNoir,
  kElectric,
  kCloud,
  kConcrete,
  kMint,
];

/// Palette for [key], falling back to [kCarbon] (web `paletteByKey`).
Palette paletteByKey(String key) {
  for (final Palette p in kPalettes) {
    if (p.key == key) return p;
  }
  return kCarbon;
}

/// `#RRGGBB` (uppercase) for a colour — the form the web palettes use.
String hexOf(Color c) {
  final String hex = (c.toARGB32() & 0xFFFFFF).toRadixString(16);
  return '#${hex.padLeft(6, '0').toUpperCase()}';
}
