import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../widgets/section/section.dart';

/// Directory grid columns (`sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4`):
/// 1 below 640, 2 below 1024, 3 below 1280, else 4.
int directoryColumns(double width) {
  if (width >= Bp.xl) return 4;
  if (width >= Bp.lg) return 3;
  if (width >= Bp.sm) return 2;
  return 1;
}

/// Gap between directory cards, both axes (`gap-4`).
const double kDirectoryGap = 16;

/// A wide-shell page: [PageHeader], then [itemCount] cards in a
/// [directoryColumns] grid (built lazily row by row, `py-8`), then an
/// optional [footer]. Provides its own scroll view.
class DirectoryPage extends StatelessWidget {
  const DirectoryPage({
    super.key,
    required this.title,
    this.sub,
    required this.itemCount,
    required this.itemBuilder,
    this.footer,
  });

  final String title;
  final String? sub;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final int cols = directoryColumns(MediaQuery.sizeOf(context).width);
    final int rows = (itemCount / cols).ceil();
    return CustomScrollView(
      slivers: [
        SliverShell(sliver: SliverToBoxAdapter(child: PageHeader(title: title, sub: sub))),
        SliverShell(
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            sliver: SliverList.separated(
              itemCount: rows,
              separatorBuilder: (context, _) => const SizedBox(height: kDirectoryGap),
              itemBuilder: (context, r) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int c = 0; c < cols; c++) ...[
                    if (c > 0) const SizedBox(width: kDirectoryGap),
                    Expanded(
                      child: r * cols + c < itemCount
                          ? itemBuilder(context, r * cols + c)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (footer != null) SliverShell(sliver: SliverToBoxAdapter(child: footer)),
      ],
    );
  }
}

/// Narrow-shell (max 1100) page body with its own scroll view.
class NarrowPage extends StatelessWidget {
  const NarrowPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Shell(
        wide: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}
