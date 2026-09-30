import 'package:flutter/material.dart';
import '../../widgets/core/bare_input.dart';

import '../../state/saves.dart';
import '../../theme/motion.dart';
import '../../theme/uiverse_colors.dart';
import '../../theme/uiverse_text.dart';
import '../../widgets/core/hover_tap.dart';
import '../../widgets/core/ink_box.dart';
import '../../widgets/core/ui_icon.dart';

/// Collection pills (§10.14): "All" + one per collection with counts, then a
/// dashed "New collection" button that becomes an inline name input.
/// [active] is a collection id or `all`; [onCreate] gets the trimmed name.
class CollectionPills extends StatefulWidget {
  const CollectionPills({
    super.key,
    required this.saves,
    required this.active,
    required this.onSelect,
    required this.onCreate,
  });

  final SavesState saves;
  final String active;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onCreate;

  @override
  State<CollectionPills> createState() => _CollectionPillsState();
}

class _CollectionPillsState extends State<CollectionPills> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final SavesState s = widget.saves;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(label: 'All', count: s.count, selected: widget.active == 'all', onTap: () => widget.onSelect('all')),
        for (final SaveCollection col in s.collections)
          _Pill(
            label: col.name,
            count: s.countIn(col.id),
            selected: widget.active == col.id,
            onTap: () => widget.onSelect(col.id),
          ),
        if (_creating)
          _NewCollectionInput(
            onDone: (String? name) {
              if (name != null && name.trim().isNotEmpty) widget.onCreate(name.trim());
              setState(() => _creating = false);
            },
          )
        else
          _NewCollectionButton(onTap: () => setState(() => _creating = true)),
      ],
    );
  }
}

/// h32, border, 14 px-x, 13px; selected = accent fill, others text-2.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      selected: selected,
      label: '$label $count',
      minSize: const Size(0, 48),
      builder: (context, hovered) {
        final Color fg = selected ? c.accentFg : (hovered ? c.text : c.text2);
        return AnimatedContainer(
          duration: motion(context, kTransition),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? c.accent : null,
            border: Border.all(color: c.border),
          ),
          // widthFactor 1: centre vertically but hug the label; a plain
          // `alignment` would stretch the pill to the full Wrap width.
          child: Center(
            widthFactor: 1,
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  TextSpan(
                    text: ' $count',
                    style: TextStyle(
                      color: fg.withValues(alpha: fg.a * 0.6),
                      fontFeatures: UiText.tabular,
                    ),
                  ),
                ],
              ),
              style: UiText.body.copyWith(color: fg),
            ),
          ),
        );
      },
    );
  }
}

/// Dashed "add" button (§10.14): h32, Plus 14 + label, text-2.
class _NewCollectionButton extends StatelessWidget {
  const _NewCollectionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return HoverTap(
      onTap: onTap,
      label: 'New collection',
      minSize: const Size(0, 48),
      builder: (context, hovered) {
        final Color fg = hovered ? c.text : c.text2;
        return InkBox(
          dashed: true,
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiIcon(Ui.plus, size: 14, color: fg),
                const SizedBox(width: 6),
                Text('New collection', style: UiText.body.copyWith(color: fg)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Inline name input: h32, border, autofocused. Submitting calls [onDone]
/// with the text; losing focus cancels (`null`).
class _NewCollectionInput extends StatefulWidget {
  const _NewCollectionInput({required this.onDone});

  final ValueChanged<String?> onDone;

  @override
  State<_NewCollectionInput> createState() => _NewCollectionInputState();
}

class _NewCollectionInputState extends State<_NewCollectionInput> {
  final TextEditingController _name = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'NewCollection');
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish(null);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _name.dispose();
    super.dispose();
  }

  void _finish(String? name) {
    if (_done) return;
    _done = true;
    widget.onDone(name);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 32,
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(border: Border.all(color: c.border)),
      child: TextField(
        controller: _name,
        focusNode: _focus,
        autofocus: true,
        onSubmitted: _finish,
        onTapOutside: (_) => _focus.unfocus(),
        textInputAction: TextInputAction.done,
        style: UiText.body.copyWith(color: c.text),
        cursorColor: c.text,
        decoration: bareInput(
          hintText: 'Collection name',
          hintStyle: UiText.body.copyWith(color: c.text3),
        ),
      ),
    );
  }
}
