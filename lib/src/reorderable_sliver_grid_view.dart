import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:reorderable_grid_view/src/sliver_grid_with_reorderable_pos_delegate.dart';
import 'package:reorderable_grid_view/src/util.dart';

import '../reorderable_grid_view.dart';

class ReorderableSliverGridView extends StatelessWidget {
  final List<Widget> children;
  final List<Widget>? header;
  final List<Widget>? footer;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  final Future<bool> Function(int oldIndex, int newIndex) onReorder;
  final DragWidgetBuilderV2? dragWidgetBuilderV2;
  final ScrollSpeedController? scrollSpeedController;
  final PlaceholderBuilder? placeholderBuilder;
  final OnDragStart? onDragStart;
  final OnDragUpdate? onDragUpdate;
  final Duration dragStartDelay;
  final bool dragEnabled;

  const ReorderableSliverGridView({
    Key? key,
    this.children = const <Widget>[],
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.childAspectRatio,
    required this.onReorder,
    this.dragWidgetBuilderV2,
    this.header,
    this.footer,
    this.dragStartDelay = kLongPressTimeout,
    this.scrollSpeedController,
    this.placeholderBuilder,
    this.onDragStart,
    this.onDragUpdate,
    this.dragEnabled = true,
  }) : super(key: key);

  const ReorderableSliverGridView.count({
    Key? key,
    required int crossAxisCount,
    required Future<bool> Function(int oldIndex, int newIndex) onReorder,
    DragWidgetBuilderV2? dragWidgetBuilderV2,
    List<Widget>? footer,
    List<Widget>? header,
    OnDragStart? onDragStart,
    OnDragUpdate? onDragUpdate,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    Duration dragStartDelay = kLongPressTimeout,
    children = const <Widget>[],
    bool dragEnabled = true,
  }) : this(
          key: key,
          onReorder: onReorder,
          children: children,
          footer: footer,
          header: header,
          crossAxisCount: crossAxisCount,
          dragWidgetBuilderV2: dragWidgetBuilderV2,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          dragStartDelay: dragStartDelay,
          dragEnabled: dragEnabled,
        );

  @override
  Widget build(BuildContext context) {
    debug("header: $header");
    var child = SliverGridWithReorderablePosDelegate.count(
        key: key,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
        children: ReorderableItemView.wrapMeList(header, children, footer));

    return ReorderableWrapperWidget(
      onReorder: onReorder,
      dragWidgetBuilder: dragWidgetBuilderV2,
      scrollSpeedController: scrollSpeedController,
      placeholderBuilder: placeholderBuilder,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      isSliver: true,
      child: child,
    );
  }
}
