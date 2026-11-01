import 'package:flutter/material.dart';

import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../core/hover_tap.dart';
import '../core/ui_icon.dart';

/// A labelled text field with an optional hint and error, for submission forms.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: UiText.mono(13, bold: true, color: c.text)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: UiText.mono(14, color: c.text),
            cursorColor: c.text,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11.5),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: UiText.small.copyWith(color: c.text3)),
          ],
          if (error != null) ...[
            const SizedBox(height: 6),
            FormError(error!),
          ],
        ],
      ),
    );
  }
}

/// A square checkbox with a long label, the confirmation on a form.
class ConfirmBox extends StatelessWidget {
  const ConfirmBox({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: () => onChanged(!value),
      checked: value,
      minSize: const Size(double.infinity, 48),
      builder: (context, hovered) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value ? c.accent : null,
              border: Border.all(color: hovered ? c.borderStrong : c.border),
            ),
            child: value ? UiIcon(Ui.check, size: 11, color: c.accentFg) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: UiText.body.copyWith(color: c.text2))),
        ],
      ),
    );
  }
}

/// A form problem, announced when it appears.
class FormError extends StatelessWidget {
  const FormError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Text(text, style: UiText.small.copyWith(color: context.ui.text)),
      );
}
