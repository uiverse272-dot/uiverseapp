import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import 'hover_tap.dart';

/// Text link, announced as a link and keyboard-focusable.
///
/// Default (`link-ink`, §10.6): always underlined 1px ~3px below the text,
/// colour → accent on hover. [LinkInk.quiet]: `text-2`, hover → `text` +
/// underline (e.g. "Save as a layout →", numbered section links).
class LinkInk extends StatelessWidget {
  const LinkInk(
    this.label, {
    super.key,
    required this.onTap,
    this.size = 12,
    this.leading,
    this.semanticLabel,
  })  : _quiet = false,
        style = null,
        maxLines = null,
        minSize = const Size(0, 32);

  /// Quiet variant: no underline at rest. [style] defaults to [UiText.chip].
  const LinkInk.quiet(
    this.label, {
    super.key,
    required this.onTap,
    this.style,
    this.maxLines,
    this.minSize = const Size(48, 48),
    this.semanticLabel,
  })  : _quiet = true,
        size = 12,
        leading = null;

  final String label;
  final VoidCallback? onTap;
  final bool _quiet;

  /// Font size of the default variant (12 in section heads, 11.5 in Pick of the week).
  final double size;

  /// Default variant: optional icon builder shown before the label (e.g. Close
  /// on "Clear"); receives the current colour.
  final Widget Function(Color color)? leading;

  /// Quiet variant: text style without colour.
  final TextStyle? style;

  /// Quiet variant: clamp to this many lines with an ellipsis.
  final int? maxLines;

  /// Minimum hit area.
  final Size minSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      link: true,
      label: semanticLabel ?? (_quiet ? null : label),
      minSize: minSize,
      builder: (context, hovered) {
        if (_quiet) {
          return Text(
            label,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: (style ?? UiText.chip).copyWith(
              color: hovered ? c.text : c.text2,
              decoration: hovered ? TextDecoration.underline : null,
              decorationColor: c.text,
            ),
          );
        }
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

  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // The link is a span inside the paragraph, so the paragraph itself takes
    // keyboard focus and activates the link (2px accent outline, §14).
    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: _focused
            ? BoxDecoration(border: Border.all(color: context.ui.focus, width: 2))
            : const BoxDecoration(),
        child: Text.rich(
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
        ),
      ),
    );
  }
}
