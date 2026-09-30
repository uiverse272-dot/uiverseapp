import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/ink_box.dart';
import '../../widgets/core/ui_icon.dart';
import '../../widgets/section/section.dart';
import '../../widgets/core/box_button.dart';
import '../directory/directory_page.dart';
import '../../widgets/core/ui_chip.dart';

/// Pre-filled metadata rows the capture pipeline would suggest (web mock).
const List<(String, List<String>)> kSuggestedMetadata = [
  ('Type', ['Landing page', 'SaaS']),
  ('Industry', ['Fintech']),
  ('Style', ['Dark', 'Minimal']),
  ('Components found', ['Navbar', 'Hero', 'Logo cloud', 'Pricing', 'Footer']),
  ('Stack detected', ['Next.js', 'Tailwind']),
];

/// `/upload` (§12): URL input, drop zone, suggested metadata chips,
/// attribution note and "Submit for review". UI only — submitting shows a
/// local confirmation; nothing is sent.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _url = TextEditingController();
  late List<List<String>> _chips = _freshChips();
  bool _submitted = false;

  static List<List<String>> _freshChips() => [for (final (_, chips) in kSuggestedMetadata) [...chips]];

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
        _url.clear();
        _chips = _freshChips();
        _submitted = false;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return NarrowPage(
      children: [
        const PageHeader(
          title: 'Submit a design',
          sub: 'Paste a URL and the capture pipeline does the rest: three viewports, block segmentation, '
              'colour and type extraction, then suggested metadata for you to confirm.',
        ),
        const SizedBox(height: 32),
        if (_submitted)
          _Submitted(url: _url.text.trim(), onAnother: _reset)
        else ...[
          _Panel(children: [
            Text('Site or app URL', style: UiText.mono(13, bold: true, color: c.text)),
            const SizedBox(height: 10),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              style: UiText.mono(14, color: c.text),
              cursorColor: c.text,
              decoration: const InputDecoration(
                hintText: 'https://',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11.5),
              ),
            ),
            const SizedBox(height: 12),
            const DividerWithText('or drop an image'),
            const SizedBox(height: 12),
            const DropZone(),
          ]),
          const SizedBox(height: 16),
          _Panel(children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                UiIcon(Ui.sparkle, size: 15, color: c.text3),
                Text('Suggested metadata', style: UiText.mono(13, bold: true, color: c.text)),
                Text('editable, never a black box', style: UiText.caption.copyWith(color: c.text3)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Everything below arrives pre-filled as removable chips. You confirm; you never fill a form.',
              style: UiText.body.copyWith(color: c.text2),
            ),
            const SizedBox(height: 16),
            for (int r = 0; r < kSuggestedMetadata.length; r++)
              MetadataRow(
                label: kSuggestedMetadata[r].$1,
                chips: _chips[r],
                onRemove: (chip) => setState(() => _chips[r] = [..._chips[r]]..remove(chip)),
              ),
          ]),
          const SizedBox(height: 16),
          _Panel(children: [
            Text('Attribution', style: UiText.mono(13, bold: true, color: c.text)),
            const SizedBox(height: 8),
            Text(
              'Every submission carries the source and a link to it. Code may only be attached when you '
              'are its author or it is published under a licence — captures of third-party sites never '
              'carry their markup.',
              style: UiText.mono(13, height: 1.625, color: c.text2),
            ),
          ]),
          const SizedBox(height: 16),
          BoxButton(
            'Submit for review',
            onTap: () => setState(() => _submitted = true),
            accent: true,
            height: 44,
            style: UiText.mono(14),
          ),
          const SizedBox(height: 16),
          Text(
            'Usually reviewed within 24 hours.',
            textAlign: TextAlign.center,
            style: UiText.small.copyWith(color: c.text3),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Surface panel with 1px border and 20 padding.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return InkBox(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// Hairlines either side of a 12.5 text-3 label (§10.14).
class DividerWithText extends StatelessWidget {
  const DividerWithText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget line() => Expanded(child: Container(height: 1, color: c.border));
    return Row(
      children: [
        line(),
        const SizedBox(width: 8),
        Text(text, style: UiText.chip.copyWith(color: c.text3)),
        const SizedBox(width: 8),
        line(),
      ],
    );
  }
}

/// Dashed 112-tall drop target (§10.14). Visual only.
class DropZone extends StatelessWidget {
  const DropZone({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return InkBox(
      dashed: true,
      child: SizedBox(
        height: 112,
        width: double.infinity,
        child: Center(
          child: Text(
            'Drop a PNG, JPG or MP4',
            textAlign: TextAlign.center,
            style: UiText.body.copyWith(color: c.text3),
          ),
        ),
      ),
    );
  }
}

/// A "label · chips" metadata row with a top rule. The label column is 144
/// wide; below 640 the label stacks above the chips.
class MetadataRow extends StatelessWidget {
  const MetadataRow({super.key, required this.label, required this.chips, required this.onRemove});

  final String label;
  final List<String> chips;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final bool stack = MediaQuery.sizeOf(context).width < Bp.sm;
    final Widget labelText = Text(label, style: UiText.chip.copyWith(color: c.text3));
    final Widget chipWrap = Wrap(
      spacing: 8,
      // Chips lay out 48 tall (hit area) around a ~25 visual.
      runSpacing: 0,
      children: [for (final String chip in chips) RemovableChip(chip, onRemove: () => onRemove(chip), gap: 6, mutedIcon: true)],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: stack
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 8), chipWrap],
            )
          : Row(
              children: [
                SizedBox(width: 144, child: labelText),
                const SizedBox(width: 8),
                Expanded(child: chipWrap),
              ],
            ),
    );
  }
}

/// Local confirmation shown after "Submit for review".
class _Submitted extends StatelessWidget {
  const _Submitted({required this.url, required this.onAnother});

  final String url;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return _Panel(children: [
      Row(
        children: [
          UiIcon(Ui.check, size: 16, color: c.text),
          const SizedBox(width: 8),
          Expanded(child: Text('Submitted for review', style: UiText.mono(14, bold: true, color: c.text))),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '${url.isEmpty ? 'Your design' : url} is in the queue. Usually reviewed within 24 hours.',
        style: UiText.mono(13, height: 1.625, color: c.text2),
      ),
      const SizedBox(height: 4),
      Text(
        'This prototype has no capture pipeline — nothing was uploaded.',
        style: UiText.small.copyWith(color: c.text3),
      ),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerLeft, child: LinkInk('Submit another', onTap: onAnother)),
    ]);
  }
}
