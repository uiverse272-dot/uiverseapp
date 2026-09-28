import 'package:flutter/material.dart';

import '../data/query.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import 'bottom_nav.dart';
import 'navbar.dart';
import 'rail.dart';
import 'search_field.dart';

/// App chrome around every in-shell screen (§9).
///
/// < 768: Navbar on top, [BottomNav] below the content.
/// ≥ 768: [Rail] (88) on the left, Navbar over the content, no BottomNav.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child, this.readingAs});

  /// Current path (e.g. `/web/saas`) — drives the active nav item.
  final String location;
  final Widget child;

  /// Parse-chip builder for the navbar search dropdown; defaults to [readingAsChips].
  final ReadingAsBuilder? readingAs;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final wide = MediaQuery.sizeOf(context).width >= Bp.md;
    return Material(
      color: c.bg,
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide) Rail(location: location),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Navbar(readingAs: readingAs ?? readingAsChips),
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: !wide,
                      child: child,
                    ),
                  ),
                  if (!wide) BottomNav(location: location),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "dimension: label" chips for a query, via the data layer's [parseQuery] (§10.1).
List<String> readingAsChips(String query) => [
      for (final t in parseQuery(query).terms) '${t.dimension}: ${t.label}',
    ];
