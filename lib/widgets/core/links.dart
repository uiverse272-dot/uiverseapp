import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import 'hover_tap.dart';

/// `link-ink` text link (§10.6): 1px underline ~3px below the text, colour
/// → accent on hover. Announced as a link.
class LinkInk extends StatelessWidget {
  const LinkInk(
    this.label, {
    super.key,
    required this.onTap,
    this.size = 12,
    this.leading,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;

  /// Font size (12 in section heads, 11.5 in Pick of the week).
  final double size;

  /// Optional icon builder shown before the label (e.g. Close on "Clear");
  /// receives the current colour.
  final Widget Function(Color color)? leading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      link: true,
      label: semanticLabel ?? label,
      minSize: const Size(0, 32),
      builder: (context, hovered) {
        final color = hovered ? c.accent : c.text;
        final text = DecoratedBox(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color))),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(label, style: UiText.mono(size, height: 1.2).copyWith(color: color)),
          ),
        );
        if (leading == null) return text;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [leading!(color), const SizedBox(width: 4), text],
        );
      },
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
