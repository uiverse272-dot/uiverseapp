/// Small building blocks shared by the detail view, its tabs and the Breakdown.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/hover_tap.dart';

/// Navigates to [path], replacing the current location (closes an overlay).
/// No-op outside a router (widget tests).
void goTo(BuildContext context, String path) => GoRouter.maybeOf(context)?.go(path);

/// `surface` box with a 1px border, 20 padding and a "title ····· note" header (§10.10).
class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, this.note, this.subtitle, required this.child});

  final String title;

  /// Right-aligned 11.5 text-3 note.
  final String? note;

  /// Line under the title (12 text-3), e.g. "Laptop → tablet → mobile".
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: subtitle == null ? 16 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: UiText.panelTitle.copyWith(color: c.text)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    note ?? '',
                    textAlign: TextAlign.right,
                    style: UiText.caption.copyWith(color: c.text3),
                  ),
                ),
              ],
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(subtitle!, style: UiText.small.copyWith(color: c.text3)),
            ),
          child,
        ],
      ),
    );
  }
}

/// Two children side by side at ≥[breakpoint] (flex [a]:[b], [gap] apart),
/// otherwise stacked with [gap] between.
class SplitRow extends StatelessWidget {
  const SplitRow({
    super.key,
    required this.first,
    required this.second,
    this.a = 1,
    this.b = 1,
    this.gap = 16,
    this.breakpoint = Bp.lg,
  });

  final Widget first;
  final Widget second;
  final int a;
  final int b;
  final double gap;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < breakpoint) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, SizedBox(height: gap), second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: a, child: first),
        SizedBox(width: gap),
        Expanded(flex: b, child: second),
      ],
    );
  }
}

/// A text link: text-2, hover → text + underline (e.g. "Save as a layout →").
class TextLink extends StatelessWidget {
  const TextLink(this.text, {super.key, required this.onTap, this.style});

  final String text;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      link: true,
      builder: (context, hovered) => Text(
        text,
        style: (style ?? UiText.chip).copyWith(
          color: hovered ? c.text : c.text2,
          decoration: hovered ? TextDecoration.underline : null,
        ),
      ),
    );
  }
}

/// A paragraph with one underlined inline link: `before` **link** `after`.
class InlineLinkText extends StatefulWidget {
  const InlineLinkText({
    super.key,
    required this.before,
    required this.link,
    required this.after,
    required this.onTap,
    required this.style,
  });

  final String before;
  final String link;
  final String after;
  final VoidCallback onTap;
  final TextStyle style;

  @override
  State<InlineLinkText> createState() => _InlineLinkTextState();
}

class _InlineLinkTextState extends State<InlineLinkText> {
  late final TapGestureRecognizer _tap = TapGestureRecognizer()..onTap = () => widget.onTap();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          TextSpan(text: widget.before),
          TextSpan(
            text: widget.link,
            recognizer: _tap,
            mouseCursor: SystemMouseCursors.click,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          TextSpan(text: widget.after),
        ],
      ),
    );
  }
}

/// `n` with thousands separators, like JS `toLocaleString()` (1234 → "1,234").
String groupThousands(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// JS number formatting for design values: 68.0 → "68", 13.5 → "13.5".
String jsNum(double v) => v == v.truncateToDouble() ? '${v.toInt()}' : '$v';
