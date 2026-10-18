import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../data/models.dart';
import 'mock_screen.dart';

/// A feed-style [MockScreen] (fixed `item.aspect` frame) that sits out fast
/// flings, like [Image] does for network images.
///
/// While the enclosing [Scrollable] is moving too fast for a preview to be
/// seen, it paints just the palette background at the same size and builds
/// the mock on the first frame the scroll slows down. Cards flung past are
/// then never built at all.
class ScrollAwareMock extends StatefulWidget {
  const ScrollAwareMock({super.key, required this.item});

  final Item item;

  @override
  State<ScrollAwareMock> createState() => _ScrollAwareMockState();
}

class _ScrollAwareMockState extends State<ScrollAwareMock> {
  bool _ready = false;
  bool _waiting = false;

  /// Built once per item: the same instance across rebuilds keeps the mock
  /// subtree from being rebuilt.
  late Widget _mock = MockScreen(item: widget.item);

  @override
  void didUpdateWidget(ScrollAwareMock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.item, widget.item)) _mock = MockScreen(item: widget.item);
  }

  void _waitForSlowScroll() {
    if (_waiting) return;
    _waiting = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _waiting = false;
      if (!mounted || _ready) return;
      if (Scrollable.recommendDeferredLoadingForContext(context)) {
        _waitForSlowScroll();
      } else {
        setState(() => _ready = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      if (Scrollable.recommendDeferredLoadingForContext(context)) {
        _waitForSlowScroll();
        return AspectRatio(
          aspectRatio: widget.item.aspect,
          child: ColoredBox(color: widget.item.palette.bg),
        );
      }
      _ready = true;
    }
    return _mock;
  }
}
