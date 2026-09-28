import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import 'core/hover_tap.dart';
import 'core/ui_icon.dart';

/// How long the Check icon replaces Copy after a successful copy (§6).
const Duration kCopiedFor = Duration(milliseconds: 1200);

/// Inline copy-to-clipboard button (§10.11).
///
/// Shows [label] (or [value]) followed by a Copy icon that appears on hover —
/// always on touch platforms — and swaps to Check for [kCopiedFor] after a copy.
class CopyValue extends StatefulWidget {
  const CopyValue(
    this.value, {
    super.key,
    this.mono = false,
    this.bordered = false,
    this.label,
  });

  /// Text placed on the clipboard.
  final String value;

  /// Mono 11.5 (hex values) instead of plain 12.5 (labels).
  final bool mono;

  /// 1px border so it reads as a chip.
  final bool bordered;

  /// Visible text; defaults to [value].
  final String? label;

  @override
  State<CopyValue> createState() => _CopyValueState();
}

class _CopyValueState extends State<CopyValue> {
  bool _done = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.value));
    } on PlatformException catch (e) {
      debugPrint('CopyValue: clipboard write failed ($e)');
      return;
    }
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _done = true);
    _timer = Timer(kCopiedFor, () {
      if (mounted) setState(() => _done = false);
    });
  }

  static bool _isTouch(TargetPlatform p) =>
      p == TargetPlatform.android || p == TargetPlatform.iOS || p == TargetPlatform.fuchsia;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final touch = _isTouch(Theme.of(context).platform);
    final style = widget.mono ? UiText.monoValue : UiText.chip;
    return HoverTap(
      onTap: _copy,
      label: widget.label ?? 'Copy ${widget.value}',
      builder: (context, hovered) => AnimatedContainer(
        duration: motion(context, kTransition),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: hovered ? c.bgSubtle : null,
          border: widget.bordered ? Border.all(color: c.border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.label ?? widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: c.text),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedOpacity(
              duration: motion(context, kTransition),
              opacity: touch || hovered || _done ? 1 : 0,
              child: UiIcon(_done ? Ui.check : Ui.copy, size: 12, color: c.text3),
            ),
          ],
        ),
      ),
    );
  }
}
