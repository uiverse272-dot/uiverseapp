import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Closes transient layers (popovers, menus, expanded panels, pickers) on
/// Android back and Esc, innermost first, before any route is popped (§14).
///
/// While [active], this layer sits on top of a global stack; the most
/// recently activated layer is dismissed first. Routes (the detail overlay,
/// dialogs, bottom sheets) need no wrapper: once no layer is open, back and
/// Esc pop the top route. [BackDismissRoot] wires both inputs.
class BackDismiss extends StatefulWidget {
  const BackDismiss({super.key, required this.active, required this.onDismiss, required this.child});

  /// Whether the layer is currently open.
  final bool active;

  /// Closes the layer.
  final VoidCallback onDismiss;
  final Widget child;

  /// Dismisses the innermost open layer; `false` when none is open.
  static bool dismissTop() {
    if (_open.isEmpty) return false;
    _open.last.widget.onDismiss();
    return true;
  }

  /// Number of open layers (for tests).
  @visibleForTesting
  static int get openCount => _open.length;

  static final List<_BackDismissState> _open = [];

  @override
  State<BackDismiss> createState() => _BackDismissState();
}

class _BackDismissState extends State<BackDismiss> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(BackDismiss oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    BackDismiss._open.remove(this);
    super.dispose();
  }

  void _sync() {
    final open = BackDismiss._open;
    if (widget.active && !open.contains(this)) open.add(this);
    if (!widget.active) open.remove(this);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Routes Android back and the Esc key to [BackDismiss] layers first, then
/// to the router's [backButtonDispatcher] (which pops the top route).
///
/// Install once, above the app's navigator. Esc is also removed from the
/// default shortcuts (see [kEscapeShortcutOverride]) so a dialog is not
/// dismissed twice.
class BackDismissRoot extends StatefulWidget {
  const BackDismissRoot({super.key, required this.backButtonDispatcher, required this.child});

  final BackButtonDispatcher backButtonDispatcher;
  final Widget child;

  @override
  State<BackDismissRoot> createState() => _BackDismissRootState();
}

class _BackDismissRootState extends State<BackDismissRoot> {
  ChildBackButtonDispatcher? _child;

  @override
  void initState() {
    super.initState();
    // The Router below registers its own callback on the root dispatcher
    // while building; a child can only take priority once that exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _child == null) _attach();
    });
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(BackDismissRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backButtonDispatcher != widget.backButtonDispatcher) {
      _detach(oldWidget.backButtonDispatcher);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _child == null) _attach();
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _detach(widget.backButtonDispatcher);
    super.dispose();
  }

  void _attach() {
    _child = widget.backButtonDispatcher.createChildBackButtonDispatcher()
      ..addCallback(_onBack)
      ..takePriority();
  }

  void _detach(BackButtonDispatcher parent) {
    final child = _child;
    if (child == null) return;
    child.removeCallback(_onBack);
    parent.forget(child);
    _child = null;
  }

  Future<bool> _onBack() => SynchronousFuture<bool>(BackDismiss.dismissTop());

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (BackDismiss.dismissTop()) return true;
    final dispatcher = widget.backButtonDispatcher;
    // A root dispatcher pops the top route, if any; nothing happens otherwise
    // (unlike the system back, Esc never exits the app).
    if (dispatcher is RootBackButtonDispatcher) dispatcher.didPopRoute().ignore();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shortcut override for `WidgetsApp.shortcuts`: Esc is handled by
/// [BackDismissRoot], so the default Esc → [DismissIntent] mapping is
/// disabled to avoid closing a dialog and then the route beneath it.
final Map<ShortcutActivator, Intent> kEscapeShortcutOverride = {
  ...WidgetsApp.defaultShortcuts,
  const SingleActivator(LogicalKeyboardKey.escape): const DoNothingAndStopPropagationIntent(),
};
