/// Number and time formatting (§13), ported from web `data.ts`.
library;

/// `842`, `1.2k`, `12k`, `1.2M` (web `compact`).
String compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
  return '$n';
}

/// `today`, `3d ago`, `2w ago`, `4mo ago`, `1y ago` (web `timeAgo`).
String timeAgo(int days) {
  if (days < 1) return 'today';
  if (days < 7) return '${days}d ago';
  if (days < 30) return '${days ~/ 7}w ago';
  if (days < 365) return '${days ~/ 30}mo ago';
  return '${days ~/ 365}y ago';
}
