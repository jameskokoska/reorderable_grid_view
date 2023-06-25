import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:reorderable_grid_view/src/reorderable_grid_mixin.dart';
import 'package:reorderable_grid_view/src/reorderable_item.dart';
import 'package:reorderable_grid_view/src/util.dart';

import '../reorderable_grid_view.dart';

// why you want the __items?
class GridChildPosDelegate extends ReorderableChildPosDelegate {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  const GridChildPosDelegate({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
  });

  @override
  Offset getPos(int index, Map<int, ReorderableItemViewState> items,
      BuildContext context) {
    // can I get pos by child?
    var child = items[index];
    // I think the better is use the sliverGrid?
    var childObject = child?.context.findRenderObject();

    // so from the childObject, I still can't get pos?
    if (childObject == null) {
      debug("index: $index is null");
    } else {
      if (childObject is RenderSliver) {
        debug("index: $index, pos: ${childObject.constraints}");
      } else if (childObject is RenderBox) {
        // childObject.localToGlobal(point)
        debug("index: $index, pos: ${childObject.semanticBounds}");
      } else {
        debug("index: $index, $childObject");
      }
    }

    // will it be not ready?
    // index and the next is not ready?
    // ok, but let's do it

    double width;
    RenderObject? renderObject = context.findRenderObject();
    if (renderObject == null) {
      return Offset.zero;
    }

    if (renderObject is RenderSliver) {
      width = renderObject.constraints.crossAxisExtent;
    } else {
      width = (renderObject as RenderBox).size.width;
    }

    double itemWidth =
        (width - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;

    int row = index ~/ crossAxisCount;
    int col = index % crossAxisCount;

    double x = (col - 1) * (itemWidth + crossAxisSpacing);
    double y = (row - 1) * (itemWidth / (childAspectRatio) + mainAxisSpacing);
    return Offset(x, y);
  }
}

class ReorderableWrapperWidget extends StatefulWidget
    with ReorderableGridWidgetMixin {
  @override
  final Future<bool> Function(int oldIndex, int newIndex) onReorder;

  @override
  final DragWidgetBuilderV2? dragWidgetBuilder;

  @override
  final ScrollSpeedController? scrollSpeedController;

  @override
  final PlaceholderBuilder? placeholderBuilder;

  final ReorderableChildPosDelegate? posDelegate;

  @override
  final OnDragStart? onDragStart;

  @override
  final OnDragUpdate? onDragUpdate;

  @override
  final Widget child;

  @override
  final bool? dragEnabled;

  @override
  final Duration? dragStartDelay;

  @override
  final bool? isSliver;

  @override
  final bool restrictDragScope;

  const ReorderableWrapperWidget({
    Key? key,
    required this.child,
    required this.onReorder,
    this.restrictDragScope = false,
    this.dragWidgetBuilder,
    this.scrollSpeedController,
    this.placeholderBuilder,
    this.posDelegate,
    this.onDragStart,
    this.onDragUpdate,
    this.dragEnabled,
    this.dragStartDelay,
    this.isSliver,
  }) : super(key: key);

  @override
  ReorderableWrapperWidgetState createState() {
    return ReorderableWrapperWidgetState();
  }
}

/// Yes we can't get grid delegate here, because we don't know child.
class ReorderableWrapperWidgetState extends State<ReorderableWrapperWidget>
    with
        TickerProviderStateMixin<ReorderableWrapperWidget>,
        ReorderableGridStateMixin {
  ReorderableWrapperWidgetState();
}
