/// Deterministic pseudo-random helpers, bit-exact with web `data.ts`
/// (FNV-1a hash + a mulberry32-style mixer).
///
/// All arithmetic is kept as unsigned 32-bit values. JS bitwise operators
/// work modulo 2^32, so masking with [_mask] at each step yields the same bits
/// as the web's `Math.imul`, `|`, `^` and `>>> 0`. Multiplication is split into
/// 16-bit halves so it never exceeds 53 bits (safe on the VM and on the web).
library;

const int _mask = 0xFFFFFFFF;

/// `Math.imul(a, b) >>> 0`.
int _imul(int a, int b) {
  final int aHi = (a >> 16) & 0xFFFF;
  final int aLo = a & 0xFFFF;
  final int bHi = (b >> 16) & 0xFFFF;
  final int bLo = b & 0xFFFF;
  return (aLo * bLo + ((((aHi * bLo + aLo * bHi) & 0xFFFF) << 16))) & _mask;
}

/// FNV-1a over UTF-16 code units, as an unsigned 32-bit int (web `hash`).
int hash32(String str) {
  int h = 2166136261;
  for (int i = 0; i < str.length; i++) {
    h ^= str.codeUnitAt(i);
    h = _imul(h, 16777619);
  }
  return h;
}

/// Integer in `[min, max)` derived from [seed] (web `rnd`).
int rnd(String seed, int min, int max) {
  int t = (hash32(seed) + 0x6d2b79f5) & _mask;
  t = _imul(t ^ (t >> 15), t | 1);
  t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & _mask)) & _mask;
  final double r = (t ^ (t >> 14)) / 4294967296;
  return (min + r * (max - min)).floor();
}
