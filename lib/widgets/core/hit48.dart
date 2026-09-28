import 'package:flutter/material.dart';

/// Keeps [child]'s visual size but expands its tap area to at least 48×48 (§14).
class Hit48 extends StatelessWidget {
  const Hit48({super.key, required this.child, required this.onTap, this.label, this.selected});

  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
