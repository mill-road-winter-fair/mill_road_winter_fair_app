import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The scroll range in which the expanded tile remains in view.
class ExpandedListingScrollBounds {
  Object? _owner;
  double? min;
  double? max;

  void clear(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    min = max = null;
  }
}

class ExpandedListingScrollPhysics extends ScrollPhysics {
  const ExpandedListingScrollPhysics({required this.bounds, super.parent});

  final ExpandedListingScrollBounds bounds;

  @override
  ExpandedListingScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      ExpandedListingScrollPhysics(
          bounds: bounds, parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final min = bounds.min;
    final max = bounds.max;
    if (min != null && max != null) {
      // Allow movement towards the tile during its initial reveal, even if the
      // current offset is outside its newly calculated range.
      final lower = min < position.pixels ? min : position.pixels;
      final upper = max > position.pixels ? max : position.pixels;
      if (value < lower) return value - lower;
      if (value > upper) return value - upper;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

/// Reveals expanded content without taking control back after manual scrolling.
class ExpandedListingReveal extends StatefulWidget {
  const ExpandedListingReveal(
      {super.key, required this.expanded, required this.child, this.bounds});

  final bool expanded;
  final Widget child;
  final ExpandedListingScrollBounds? bounds;

  @override
  State<ExpandedListingReveal> createState() => _ExpandedListingRevealState();
}

class _ExpandedListingRevealState extends State<ExpandedListingReveal>
    with AutomaticKeepAliveClientMixin {
  final _contentKey = GlobalKey();
  ScrollPosition? _position;
  bool _userHasScrolled = false;
  bool _scheduled = false;

  @override
  bool get wantKeepAlive => widget.expanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reconsider visibility after window rotation/resizing.
    MediaQuery.sizeOf(context);
    final position = Scrollable.maybeOf(context)?.position;
    if (_position != position) {
      _position?.removeListener(_onScroll);
      _position = position;
      _position?.addListener(_onScroll);
    }
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(ExpandedListingReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) updateKeepAlive();
    if (!widget.expanded || widget.bounds != oldWidget.bounds) {
      oldWidget.bounds?.clear(this);
    }
    if (widget.expanded && !oldWidget.expanded) {
      _userHasScrolled = false;
      _scheduleReveal();
    }
  }

  void _onScroll() {
    if (widget.expanded &&
        _position?.userScrollDirection != ScrollDirection.idle) {
      _userHasScrolled = true;
    }
  }

  void _scheduleReveal() {
    if (!widget.expanded || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !widget.expanded) return;
      final box = _contentKey.currentContext?.findRenderObject();
      final position = _position;
      if (box is! RenderBox ||
          position == null ||
          !position.hasContentDimensions) {
        return;
      }
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) return;
      final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      final height = position.viewportDimension;
      final bottom = top + box.size.height;
      final start = position.pixels + top;
      final end = position.pixels + bottom - height;
      final bounds = widget.bounds;
      if (bounds != null) {
        // Give the user room beyond either edge without letting a short tile
        // disappear. Scale to the viewport, with a cap for larger screens.
        final leeway = (height * 0.2)
            .clamp(0.0, 120.0)
            .clamp(0.0, box.size.height / 2);
        bounds._owner = this;
        bounds.min = ((start < end ? start : end) - leeway)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
        bounds.max = ((start > end ? start : end) + leeway)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
      }
      // Oversized cards start at the top; the remaining content scrolls normally.
      final delta = box.size.height > height || top < 0
          ? top
          : bottom > height
              ? bottom - height + 8.0
              : 0.0;
      // Preserve manual positioning unless a layout change puts it outside the
      // tile's new range (for example after resizing the window).
      final target = _userHasScrolled
          ? position.pixels.clamp(
              bounds?.min ?? position.pixels, bounds?.max ?? position.pixels)
          : (position.pixels + delta)
              .clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((target - position.pixels).abs() < 1) return;
      position.animateTo(target,
          duration: const Duration(milliseconds: 180), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    widget.bounds?.clear(this);
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _scheduleReveal();
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: SizedBox(key: _contentKey, child: widget.child),
      ),
    );
  }
}
