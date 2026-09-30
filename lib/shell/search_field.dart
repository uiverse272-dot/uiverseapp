import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';
import '../theme/motion.dart';
import '../theme/uiverse_colors.dart';
import '../theme/uiverse_text.dart';
import '../widgets/core/back_dismiss.dart';
import '../widgets/core/ui_icon.dart';
import '../widgets/core/hover_tap.dart';

/// Given the typed query, the "Reading as" chip labels (`"Style: dark"`, …).
///
/// The parser lives in the data layer; pass e.g.
/// `(q) => [for (final t in parseQuery(q).terms) '${t.dimension}: ${t.label}']`.
typedef ReadingAsBuilder = List<String> Function(String query);

/// Example queries rotated in the big field's placeholder every 3.2s.
const List<String> kSearchExamples = [
  'dark fintech dashboard',
  'minimal saas pricing section',
  'luxury ecommerce landing page',
  'ios onboarding flow',
  'editorial blog layout',
];

/// Search input (§10.1). [SearchField.compact] sits in the yellow navbar cell;
/// [SearchField.big] heads the /search page. Submitting goes to `/search?q=`.
class SearchField extends StatefulWidget {
  const SearchField.compact({super.key, this.readingAs, this.initialQuery = '', this.onSubmit})
      : big = false;

  const SearchField.big({super.key, this.readingAs, this.initialQuery = '', this.onSubmit})
      : big = true;

  final bool big;
  final ReadingAsBuilder? readingAs;
  final String initialQuery;

  /// Overrides the default navigation to `/search?q=` (receives the trimmed query).
  final ValueChanged<String>? onSubmit;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _q = TextEditingController(text: widget.initialQuery);
  final FocusNode _focus = FocusNode(debugLabel: 'SearchField');
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final Object _tapGroup = Object();
  Timer? _blurTimer;
  Timer? _rotate;
  bool _focused = false;
  int _example = 0;
  double _width = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    _q.addListener(_sync);
    if (widget.big) {
      _rotate = Timer.periodic(const Duration(milliseconds: 3200), (_) {
        setState(() => _example = (_example + 1) % kSearchExamples.length);
      });
    } else {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  @override
  void dispose() {
    if (!widget.big) HardwareKeyboard.instance.removeHandler(_onKey);
    _blurTimer?.cancel();
    _rotate?.cancel();
    _focus.dispose();
    _q.dispose();
    super.dispose();
  }

  /// `/` or Ctrl/⌘+K focuses the navbar field unless another text field has focus.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || _focus.hasFocus) return false;
    final primary = FocusManager.instance.primaryFocus?.context;
    if (primary != null && primary.findAncestorWidgetOfExactType<EditableText>() != null) {
      return false;
    }
    final kb = HardwareKeyboard.instance;
    final isK = e.logicalKey == LogicalKeyboardKey.keyK &&
        (kb.isControlPressed || kb.isMetaPressed);
    if (e.logicalKey == LogicalKeyboardKey.slash || isK) {
      _focus.requestFocus();
      return true;
    }
    return false;
  }

  void _onFocus() {
    _blurTimer?.cancel();
    if (_focus.hasFocus) {
      _focused = true;
      _sync();
    } else {
      // Dropdown closes 140ms after blur so a tap on it can land (§6).
      _blurTimer = Timer(kDur, () {
        _focused = false;
        _sync();
      });
    }
  }

  void _sync() {
    if (!mounted) return;
    final open = _focused && _q.text.trim().isNotEmpty;
    if (open != _portal.isShowing) open ? _portal.show() : _portal.hide();
    setState(() {});
  }

  /// Esc / back: close the dropdown and leave the field.
  void _dismiss() {
    _blurTimer?.cancel();
    _focus.unfocus();
    _focused = false;
    _sync();
  }

  void _submit() {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    _focus.unfocus();
    _blurTimer?.cancel();
    _focused = false;
    _sync();
    final onSubmit = widget.onSubmit;
    if (onSubmit != null) {
      onSubmit(q);
    } else {
      context.go(Routes.searchFor(q));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final big = widget.big;
    final fg = big ? c.text : c.onSignal;
    final showKbd = !big && MediaQuery.sizeOf(context).width >= 1024;

    final box = BoxDecoration(
      color: big ? c.surface : null,
      border: Border.all(color: big ? c.border : c.onSignal),
      boxShadow: _focus.hasFocus ? [hardShadow(3, fg)] : null,
    );
    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: big ? 16 : 12),
      child: Row(
        children: [
          UiIcon(Ui.search, size: big ? 19 : 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            // The compact field sits on the signal-yellow cell, where the
            // signal selection colour would be invisible; tint with ink instead.
            child: TextSelectionTheme(
              data: big
                  ? TextSelectionTheme.of(context)
                  : TextSelectionTheme.of(context).copyWith(selectionColor: c.onSignal.withValues(alpha: 0.25)),
              child: TextField(
                controller: _q,
                focusNode: _focus,
                groupId: _tapGroup,
                onTapOutside: (_) => _focus.unfocus(),
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.search,
                style: UiText.mono(big ? 15 : 13, color: fg),
                cursorColor: fg,
                decoration: InputDecoration.collapsed(
                  hintText: big
                      ? 'Try: ${kSearchExamples[_example]}'
                      : 'Site, component, style, or industry',
                  hintStyle: UiText.mono(
                    big ? 15 : 13,
                    color: big ? c.text3 : c.onSignal.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          if (showKbd) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: fg)),
              child: Text('⌘K', style: UiText.mono(10.5, height: 1.2, color: fg)),
            ),
          ],
        ],
      ),
    );

    // The compact box is 40 tall but lays out 48 so the field's tap target
    // meets 48dp (§14); the box is drawn centred in it.
    final Widget field = big
        ? Container(height: 52, decoration: box, child: row)
        : SizedBox(
            height: 48,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(top: 4, bottom: 4, child: DecoratedBox(decoration: box)),
                row,
              ],
            ),
          );

    return LayoutBuilder(
      builder: (context, box) {
        _width = box.maxWidth;
        return BackDismiss(
          active: _portal.isShowing,
          onDismiss: _dismiss,
          child: CompositedTransformTarget(
            link: _link,
            child: OverlayPortal(
              controller: _portal,
              overlayChildBuilder: _dropdown,
              child: field,
            ),
          ),
        );
      },
    );
  }

  Widget _dropdown(BuildContext context) {
    final c = context.ui;
    final q = _q.text.trim();
    final chips = q.isEmpty ? const <String>[] : (widget.readingAs?.call(q) ?? const <String>[]);
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        // 6 below the visible box (the compact box is inset 4 in its 48 layout).
        offset: Offset(0, widget.big ? 6 : 2),
        child: TapRegion(
          groupId: _tapGroup,
          child: SizedBox(
            width: _width,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: motion(context, kFadeIn),
              builder: (context, t, child) => Opacity(opacity: t, child: child),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    boxShadow: [hardShadow(Lift.l3, c.border)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (chips.isNotEmpty) _readingAs(context, chips),
                      HoverTap(
                        onTap: _submit,
                        minSize: const Size(double.infinity, 48),
                        builder: (context, hovered) => Container(
                          color: hovered ? c.bgSubtle : null,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              UiIcon(Ui.search, size: 14, color: c.text3),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Search for ',
                                    children: [
                                      TextSpan(
                                        text: '“${_q.text}”',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.body.copyWith(color: c.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _readingAs(BuildContext context, List<String> chips) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Reading as', style: UiText.caption.copyWith(color: c.text3)),
          for (final chip in chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: c.signal, border: Border.all(color: c.border)),
              child: Text(chip, style: UiText.meta.copyWith(color: c.onSignal)),
            ),
        ],
      ),
    );
  }
}
