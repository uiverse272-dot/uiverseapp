import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/prompt.dart';
import '../router/routes.dart';
import '../state/prompt_quota.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/hover_tap.dart';
import '../widgets/core/ui_icon.dart';
import '../widgets/save/save_button.dart';
import 'parts.dart';

/// How long "Copied" replaces "Copy prompt" (§6).
const Duration kPromptCopiedFor = Duration(milliseconds: 1400);

/// Opens the implementation-prompt generator for [item] (§10.13): full screen
/// on phones, otherwise a centred square sheet over the `overlay` scrim.
Future<void> showPromptDialog(BuildContext context, Item item) {
  final d = motion(context, kSheet);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: context.ui.overlay,
    transitionDuration: d,
    transitionBuilder: (context, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: kEase);
      return AnimatedBuilder(
        animation: t,
        child: child,
        builder: (context, child) => Opacity(
          opacity: t.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t.value)),
            child: Transform.scale(scale: 0.99 + 0.01 * t.value, child: child),
          ),
        ),
      );
    },
    pageBuilder: (context, _, _) => _PromptSheet(item: item),
  );
}

/// Positions [PromptDialog]: edge to edge on phones, 1020 × min(720, 90%h) otherwise.
class _PromptSheet extends StatelessWidget {
  const _PromptSheet({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final c = context.ui;
    final dialog = PromptDialog(item: item);
    if (size.width < Bp.md) {
      return Material(color: c.bg, child: SafeArea(child: dialog));
    }
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 1020,
              maxHeight: math.min(720, size.height * 0.9),
            ),
            child: Material(
              color: c.bg,
              shape: Border.all(color: c.border),
              child: dialog,
            ),
          ),
        ),
      ),
    );
  }
}

/// The prompt generator body: options, editable prompt and footer.
class PromptDialog extends ConsumerStatefulWidget {
  const PromptDialog({super.key, required this.item});

  final Item item;

  @override
  ConsumerState<PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends ConsumerState<PromptDialog> {
  PromptOptions _opts = defaultPromptOptions;
  late final TextEditingController _text =
      TextEditingController(text: buildPrompt(widget.item, _opts));
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  /// Changing an option regenerates the prompt, discarding manual edits.
  void _set(PromptOptions next) {
    setState(() {
      _opts = next;
      _text.text = buildPrompt(widget.item, next);
    });
  }

  Future<void> _copy() async {
    if (ref.read(promptQuotaProvider).locked) return;
    try {
      await Clipboard.setData(ClipboardData(text: _text.text));
    } on PlatformException catch (e) {
      debugPrint('PromptDialog: clipboard write failed ($e)');
      return;
    }
    if (!mounted) return;
    ref.read(promptQuotaProvider.notifier).consume();
    _timer?.cancel();
    setState(() => _copied = true);
    _timer = Timer(kPromptCopiedFor, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _close() => Navigator.of(context).maybePop().ignore();

  void _seePro() {
    final router = GoRouter.maybeOf(context);
    _close();
    router?.go(Routes.pricing);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= Bp.md;
    final quota = ref.watch(promptQuotaProvider);

    final options = _Options(opts: _opts, onChanged: _set);
    final output = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: quota.locked
              ? _Locked(
                  limit: quota.limit,
                  onSeePro: _seePro,
                  onReset: () => ref.read(promptQuotaProvider.notifier).reset(),
                )
              : TextField(
                  controller: _text,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: UiText.mono(12, height: 1.625, color: c.text),
                  cursorColor: c.text,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
        ),
        _Footer(
          item: widget.item,
          tokens: estimateTokens(_text.text),
          quota: quota,
          copied: _copied,
          onCopy: _copy,
        ),
      ],
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: 'Generate implementation prompt',
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(item: widget.item, onClose: _close),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 264,
                        decoration: BoxDecoration(border: Border(right: BorderSide(color: c.border))),
                        child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: options),
                      ),
                      Expanded(child: output),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Stacked above the prompt; capped so the text area stays usable.
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: size.height * 0.42),
                        child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: options),
                      ),
                      Container(height: 1, color: c.border),
                      Expanded(child: output),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item, required this.onClose});

  final Item item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          UiIcon(Ui.sparkle, size: 16, color: c.text3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Generate implementation prompt',
                    style: UiText.panelTitle.copyWith(color: c.text),
                  ),
                ),
                Text(
                  '${item.title} · ${item.source.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.small.copyWith(color: c.text3),
                ),
              ],
            ),
          ),
          HoverTap(
            onTap: onClose,
            label: 'Close',
            builder: (context, hovered) => Container(
              width: 32,
              height: 32,
              color: hovered ? c.bgSubtle : null,
              alignment: Alignment.center,
              child: UiIcon(Ui.close, size: 16, color: hovered ? c.text : c.text2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.opts, required this.onChanged});

  final PromptOptions opts;
  final ValueChanged<PromptOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final includes = <(String, bool, PromptOptions Function(bool))>[
      ('Section breakdown', opts.includeSections, (v) => opts.copyWith(includeSections: v)),
      ('Colour tokens', opts.includeTokens, (v) => opts.copyWith(includeTokens: v)),
      ('Type scale', opts.includeType, (v) => opts.copyWith(includeType: v)),
      ('Layout & responsive', opts.includeLayout, (v) => opts.copyWith(includeLayout: v)),
      ('Accessibility requirements', opts.includeA11y, (v) => opts.copyWith(includeA11y: v)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          label: 'Target tool',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in ToolId.values)
                HoverTap(
                  onTap: () => onChanged(opts.copyWith(tool: t)),
                  selected: opts.tool == t,
                  builder: (context, hovered) {
                    final on = opts.tool == t;
                    final fg = on ? c.accentFg : c.text;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      color: on ? c.accent : (hovered ? c.bgSubtle : null),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.label, style: UiText.body.copyWith(color: fg)),
                          Text(
                            t.hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.meta.copyWith(
                              color: on ? c.accentFg.withValues(alpha: 0.7) : c.text3,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        _Group(
          label: 'Stack',
          child: Wrap(
            spacing: 6,
            children: [
              for (final s in StackId.values)
                HoverTap(
                  onTap: () => onChanged(opts.copyWith(stack: s)),
                  selected: opts.stack == s,
                  builder: (context, hovered) {
                    final on = opts.stack == s;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? c.accent : (hovered ? c.bgSubtle : null),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        s.label,
                        style: UiText.chip.copyWith(color: on ? c.accentFg : c.text),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        _Group(
          label: 'Include',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, on, next) in includes)
                Semantics(
                  checked: on,
                  child: HoverTap(
                    onTap: () => onChanged(next(!on)),
                    builder: (context, hovered) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      color: hovered ? c.bgSubtle : null,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: on ? c.accent : null,
                              border: Border.all(color: on ? c.border : c.borderStrong),
                            ),
                            child: on ? UiIcon(Ui.check, size: 11, color: c.accentFg) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(label, style: UiText.chip.copyWith(color: c.text))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Text(
              label.toUpperCase(),
              style: UiText.overline.copyWith(color: context.ui.text3),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.limit, required this.onSeePro, required this.onReset});

  final int limit;
  final VoidCallback onSeePro;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You've used your $limit free prompts this month",
                textAlign: TextAlign.center,
                style: UiText.sectionHead.copyWith(color: c.text),
              ),
              const SizedBox(height: 12),
              Text(
                'Pro removes the limit. Browsing, saving and the Breakdown tab stay unlimited on '
                'Free — only generated output is metered.',
                textAlign: TextAlign.center,
                style: UiText.mono(13.5, height: 1.625, color: c.text2),
              ),
              const SizedBox(height: 16),
              HoverTap(
                onTap: onSeePro,
                link: true,
                builder: (context, hovered) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: c.accent,
                  child: Text('See Pro', style: UiText.button.copyWith(color: c.accentFg)),
                ),
              ),
              HoverTap(
                onTap: onReset,
                builder: (context, hovered) => Text(
                  'Reset counter (demo only)',
                  style: UiText.small.copyWith(
                    color: hovered ? c.text : c.text3,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.item,
    required this.tokens,
    required this.quota,
    required this.copied,
    required this.onCopy,
  });

  final Item item;
  final int tokens;
  final PromptQuota quota;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final enabled = !quota.locked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '~${groupThousands(tokens)} tokens · ${quota.remaining} of ${quota.limit} left this month',
              style: UiText.caption.copyWith(color: c.text3),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SaveButton(item.slug, variant: SaveButtonVariant.inline),
              const SizedBox(width: 8),
              HoverTap(
                onTap: enabled ? onCopy : null,
                label: copied ? 'Copied' : 'Copy prompt',
                builder: (context, hovered) => Opacity(
                  opacity: !enabled ? 0.4 : (hovered ? 0.9 : 1),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: c.accent,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UiIcon(copied ? Ui.check : Ui.copy, size: 14, color: c.accentFg),
                        const SizedBox(width: 6),
                        Text(
                          copied ? 'Copied' : 'Copy prompt',
                          style: UiText.button.copyWith(color: c.accentFg),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
