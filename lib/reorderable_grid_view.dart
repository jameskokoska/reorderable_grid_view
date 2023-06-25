import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/src/reorderable_wrapper_widget.dart';
import 'package:reorderable_grid_view/src/reorderable_item.dart';

export 'src/reorderable_sliver_grid_view.dart' show ReorderableSliverGridView;
export 'src/reorderable_wrapper_widget.dart' show ReorderableWrapperWidget;
export 'src/reorderable_item.dart' show ReorderableItemView;

/// Build the drag widget under finger when dragging.
/// The index here represents the index of current dragging widget
/// The child here represents the current index widget
/// [dragWidgetScreenshot] If you pass screenshotDragWidget true, then will take a screenshot of the drag widget.
/// deprecated , use DragWidgetBuilderV2 instead
@Deprecated("")
typedef DragWidgetBuilder = Widget Function(int index, Widget child);

class DragWidgetBuilderV2 {
  /// if ture, will create a screenshot fo the drag widget
  final bool isScreenshotDragWidget;

  /// [screenshot] will not null if you provide isTakeScreenshotDragWidget = ture.
  final Widget Function(int index, Widget child, ImageProvider? screenshot)
      builder;

  DragWidgetBuilderV2(
      {this.isScreenshotDragWidget = false, required this.builder});

  /// a helper method to covert deprecated build to current builder
  static DragWidgetBuilderV2? createByOldBuilder9(
      DragWidgetBuilder? oldBuilder) {
    if (oldBuilder == null) return null;
    return DragWidgetBuilderV2(
        isScreenshotDragWidget: false,
        builder: (int index, Widget child, ImageProvider? screenshot) =>
            oldBuilder(index, child));
  }
}
// typedef DragWidgetBuilderV2 = Widget Function(int index, Widget child, ByteData? dragWidgetScreenshot);

/// Control the scroll speed if drag over the boundary.
/// We can pass time here??
/// [timeInMilliSecond] is the time passed.
/// [overPercentage] is the scroll over the boundary percentage
/// [overSize] is the pixel drag over the boundary
/// [itemSize] is the drag item size
/// Maybe you need decide the scroll speed by the given param.
/// return how many pixels when scroll in 14ms(maybe a frame). 5 is the default
typedef ScrollSpeedController = double Function(
    int timeInMilliSecond, double overSize, double itemSize);

/// build the target placeholder
typedef PlaceholderBuilder = Widget Function(
    int dropIndex, int dropInddex, Widget dragWidget);

/// The drag and drop life cycle.
typedef OnDragStart = void Function(int dragIndex);

/// Called when the position of the dragged widget changes.
///
/// [dragIndex] is the index of the item that is dragged.
/// [position] is the current position of the pointer in the
/// global coordinate system. [delta] is the offset of the current
/// position relative to the position of the last drag update call.
typedef OnDragUpdate = void Function(
    int dragIndex, Offset position, Offset delta);

/// Usage:
/// ```
/// ReorderableGridView(
///   crossAxisCount: 3,
///   children: this.data.map((e) => buildItem("$e")).toList(),
///   onReorder: (oldIndex, newIndex) {
///     setState(() {
///       final element = data.removeAt(oldIndex);
///       data.insert(newIndex, element);
///     });
///   },
/// )
///```
/// I think it's borrowing to pass those params.
/// Will it to hard to calculate the position by delegator? not by crossAxis
/// and spacing?
/// And the SliverGridDelete need an constraint to get a layout but, I don't have the
/// constraint, and that method look called by the framework.
/// So I need the crossAxisCount, spacing to determine the pos.
class ReorderableGridView extends StatelessWidget {
  final Future<bool> Function(int oldIndex, int newIndex) onReorder;
  final DragWidgetBuilderV2? dragWidgetBuilderV2;
  final ScrollSpeedController? scrollSpeedController;
  final PlaceholderBuilder? placeholderBuilder;
  final OnDragStart? onDragStart;
  final OnDragUpdate? onDragUpdate;

  final bool? primary;
  final bool shrinkWrap;
  final bool restrictDragScope;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final double? cacheExtent;
  final int? semanticChildCount;

  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Clip clipBehavior;
  final String? restorationId;

  final SliverChildDelegate childrenDelegate;

  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final DragStartBehavior dragStartBehavior;

  final Duration? dragStartDelay;
  final bool? dragEnabled;

  ReorderableGridView.builder({
    Key? key,
    required Future<bool> Function(int oldIndex, int newIndex) onReorder,
    ScrollSpeedController? scrollSpeedController,
    DragWidgetBuilder? dragWidgetBuilder,
    DragWidgetBuilderV2? dragWidgetBuilderV2,
    PlaceholderBuilder? placeholderBuilder,
    OnDragStart? onDragStart,
    OnDragUpdate? onDragUpdate,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required SliverGridDelegate gridDelegate,
    required IndexedWidgetBuilder itemBuilder,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    Duration? dragStartDelay,
    bool? dragEnabled,
    bool restrictDragScope = false,
  }) : this(
          key: key,
          onReorder: onReorder,
          dragWidgetBuilderV2: dragWidgetBuilderV2 ??
              DragWidgetBuilderV2.createByOldBuilder9(dragWidgetBuilder),
          scrollSpeedController: scrollSpeedController,
          placeholderBuilder: placeholderBuilder,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,

          // how to determine the
          childrenDelegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              Widget child = itemBuilder(context, index);
              assert(() {
                if (child.key == null) {
                  throw FlutterError(
                    'Every item of ReorderableGridView must have a key.',
                  );
                }
                return true;
              }());
              return ReorderableItemView(
                key: child.key!,
                index: index,
                child: child,
              );
            },
            childCount: itemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          ),

          gridDelegate: gridDelegate,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount ?? itemCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          dragStartDelay: dragStartDelay,
          dragEnabled: dragEnabled,
          restrictDragScope: restrictDragScope,
        );

  factory ReorderableGridView.count({
    Key? key,
    required Future<bool> Function(int oldIndex, int newIndex) onReorder,
    DragWidgetBuilder? dragWidgetBuilder,
    DragWidgetBuilderV2? dragWidgetBuilderV2,
    ScrollSpeedController? scrollSpeedController,
    PlaceholderBuilder? placeholderBuilder,
    OnDragStart? onDragStart,
    OnDragUpdate? onDragUpdate,
    List<Widget>? footer,
    List<Widget>? header,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    double? mainAxisExtent,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required int crossAxisCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    Duration? dragStartDelay,
    bool? dragEnabled,
    restrictDragScope = false,
  }) {
    assert(
      children.every((Widget w) => w.key != null),
      'All children of this widget must have a key.',
    );
    return ReorderableGridView(
      key: key,
      onReorder: onReorder,
      dragWidgetBuilderV2: dragWidgetBuilderV2 ??
          DragWidgetBuilderV2.createByOldBuilder9(dragWidgetBuilder),
      scrollSpeedController: scrollSpeedController,
      placeholderBuilder: placeholderBuilder,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      childrenDelegate: SliverChildListDelegate(
        ReorderableItemView.wrapMeList(header, children, footer),
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount ?? children.length,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      dragEnabled: dragEnabled,
      dragStartDelay: dragStartDelay,
      restrictDragScope: restrictDragScope,
    );
  }

  const ReorderableGridView({
    Key? key,
    required this.onReorder,
    this.dragWidgetBuilderV2,
    this.scrollSpeedController,
    this.placeholderBuilder,
    this.onDragStart,
    this.onDragUpdate,
    required this.gridDelegate,
    required this.childrenDelegate,
    this.restrictDragScope = false,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.cacheExtent,
    this.semanticChildCount,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.controller,
    this.dragStartBehavior = DragStartBehavior.start,
    this.dragStartDelay,
    this.dragEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReorderableWrapperWidget(
      onReorder: onReorder,
      dragWidgetBuilder: dragWidgetBuilderV2,
      scrollSpeedController: scrollSpeedController,
      placeholderBuilder: placeholderBuilder,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      dragEnabled: dragEnabled,
      dragStartDelay: dragStartDelay,
      restrictDragScope: restrictDragScope,
      child: GridView.custom(
        key: key,
        gridDelegate: gridDelegate,
        childrenDelegate: childrenDelegate,
        controller: controller,
        reverse: reverse,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        cacheExtent: cacheExtent,
        semanticChildCount: semanticChildCount,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
        dragStartBehavior: dragStartBehavior,
      ),
    );
  }
}
