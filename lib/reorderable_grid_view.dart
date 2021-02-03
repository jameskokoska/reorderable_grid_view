import 'package:flutter/material.dart';

const _IS_DEBUG = false;

_debug(String msg) {
  if (_IS_DEBUG) {
    print("ReorderableGridView: " + msg);
  }
}

_Pos _getPos(int index, int crossAxisCount) {
  return _Pos(row: index ~/ crossAxisCount, col: index % crossAxisCount);
}

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
class ReorderableGridView extends StatefulWidget {
  final List<Widget> children;
  final List<Widget> footer;
  final int crossAxisCount;
  final ReorderCallback onReorder;
  final bool primary;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  ReorderableGridView(
      {this.children,
      this.crossAxisCount,
      this.onReorder,
      this.footer,
      this.primary,
      this.mainAxisSpacing = 0.0,
      this.crossAxisSpacing = 0.0,
      this.padding,
      this.shrinkWrap = true})
      : assert(children != null),
        assert(crossAxisCount != null),
        assert(onReorder != null);

  @override
  _ReorderableGridViewState createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView>
    with TickerProviderStateMixin<ReorderableGridView> {
  List<GridItemWrapper> _items = [];

  // The widget to move the dragging widget too after the current index.
  int _nextIndex = 0;

  // The location that the dragging widget occupied before it started to drag.
  int _dragStartIndex = 0;

  // occupies 占用
  // The index that the dragging widget currently occupies.
  int _currentIndex = 0;

  // 好像不能共用controller
  // This controls the entrance of the dragging widget into a new place.
  AnimationController _entranceController;

  // This controls the 'ghost' of the dragging widget, which is left behind
  // where the widget used to be.
  AnimationController _ghostController;

  // How long an animation to reorder an element in the list takes.
  static const Duration _reorderAnimationDuration = Duration(milliseconds: 200);

  // The member of widget.children currently being dragged.
  //
  // Null if no drag is underway.
  Key _dragging;

  _initItems() {
    _items.clear();
    for (var i = 0; i < widget.children.length; i++) {
      _items.add(GridItemWrapper(index: i));
    }
  }

  @override
  void initState() {
    super.initState();
    _debug("initState, child count: ${this.widget.children?.length ?? -1}");
    _entranceController =
        AnimationController(vsync: this, duration: _reorderAnimationDuration);
    _entranceController.addStatusListener(_onEntranceStatusChanged);

    _ghostController =
        AnimationController(vsync: this, duration: _reorderAnimationDuration);

    _initItems();
  }

  @override
  void didUpdateWidget(covariant ReorderableGridView oldWidget) {
    _initItems();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ghostController.dispose();
    super.dispose();
  }

  // Places the value from startIndex one space before the element at endIndex.
  void reorder(int startIndex, int endIndex) {
    // what to do??
    setState(() {
      if (startIndex != endIndex) widget.onReorder(startIndex, endIndex);
      // Animates leftover space in the drop area closed.
      // _ghostController.reverse(from: 0);
      _entranceController.reverse(from: 0);
      _initItems();
      _dragging = null;
    });
  }

  // Drops toWrap into the last position it was hovering over.
  void onDragEnded() {
    reorder(_dragStartIndex, _currentIndex);
  }

  // Animates the droppable space from _currentIndex to _nextIndex.
  void _requestAnimationToNextIndex() {
    _debug(
        "_requestAnimationToNextIndex, state: ${_entranceController.status}");
    if (_entranceController.isCompleted) {
      if (_nextIndex == _currentIndex) {
        return;
      }

      var temp = new List<int>.generate(_items.length, (index) => index);

      // 怎么处理连续滑动？？
      var old = temp.removeAt(_dragStartIndex);
      temp.insert(_nextIndex, old);

      for (var i = 0; i < _items.length; i++) {
        _items[i].nextIndex = temp.indexOf(i);
      }
      _debug("items: ${_items.map((e) => e.toString()).join(",")}");

      _currentIndex = _nextIndex;
      // _ghostController.reverse(from: 1.0);
      _entranceController.forward(from: 0.0);
    }
  }

  // Requests animation to the latest next index if it changes during an animation.
  void _onEntranceStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _items.forEach((element) {
        element.animFinish();
      });
      setState(() {
        _requestAnimationToNextIndex();
      });
    }
  }

  Widget _wrap(Widget toWrap, int index) {
    // var box = context.findRenderObject() as RenderBox;
    // now box is null.
    // print(box.size);
    // can I get width and height here?

    assert(toWrap.key != null);
    Widget buildDragTarget(BuildContext context, List<Key> acceptedCandidates,
        List<dynamic> rejectedCandidates, BoxConstraints constraints) {
      // now let's try scroll??
      Widget child = LongPressDraggable<Key>(
        data: toWrap.key,
        maxSimultaneousDrags: 1,
        // feed back is the view follow pointer
        feedback: Container(
          // actually, this constraints is not necessary here.
          // but how to calculate the toWrap size and give feedback.
          constraints: constraints,
          child: Material(elevation: 3.0, child: toWrap),
        ),
        child: _dragging == toWrap.key ? SizedBox() : toWrap,
        childWhenDragging: const SizedBox(),
        onDragStarted: () {
          _dragStartIndex = index;
          _currentIndex = index;

          // this is will set _entranceController to complete state.
          // ok ready to start animation
          _entranceController.value = 1.0;
          _dragging = toWrap.key;
        },
        onDragCompleted: onDragEnded,
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          onDragEnded();
        },
      );

      // why at here is 0??
      print("index: $index, _items's len: ${_items.length}");
      var item = _items[index];

      // any better way to do this?
      var fromPos = item.getBeginOffset(this.widget.crossAxisCount);
      var toPos = item.getEndOffset(this.widget.crossAxisCount);
      if (fromPos != toPos || item.hasMoved()) {
        // 如何同时移动？？
        return SlideTransition(
          position: Tween<Offset>(begin: fromPos, end: toPos)
              .animate(_entranceController),
          child: child,
        );
      } else {
        _debug("build no animation for pos: $index");
      }
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // I think it's strange that I can get the right constraints at here.
        return DragTarget<Key>(
          builder: (context, acceptedCandidates, rejectedCandidates) =>
              buildDragTarget(
                  context, acceptedCandidates, rejectedCandidates, constraints),
          onWillAccept: (Key toAccept) {
            _debug("onWillAccept called for index: $index");
            // how can we change the state?
            setState(() {
              _nextIndex = index;
              _requestAnimationToNextIndex();
            });

            // now let's try scroll.
            return _dragging == toAccept && toAccept != toWrap.key;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var children = List<Widget>();
    for (var i = 0; i < widget.children.length; i++) {
      children.add(_wrap(widget.children[i], i));
    }

    return GridView.count(
      children: children..addAll(widget.footer ?? []),
      crossAxisCount: widget.crossAxisCount,
      primary: widget.primary,
      mainAxisSpacing: widget.mainAxisSpacing,
      crossAxisSpacing: widget.crossAxisSpacing,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
    );
  }
}

class GridItemWrapper {
  int index;
  int curIndex;
  int nextIndex;

  GridItemWrapper({this.index}) : assert(index != null) {
    curIndex = index;
    nextIndex = index;
  }

  Offset getBeginOffset(int crossAxisCount) {
    var origin = _getPos(index, crossAxisCount);
    var pos = _getPos(curIndex, crossAxisCount);
    return Offset(
        (pos.col - origin.col).toDouble(), (pos.row - origin.row).toDouble());
  }

  Offset getEndOffset(int crossAxisCount) {
    var origin = _getPos(index, crossAxisCount);
    var pos = _getPos(nextIndex, crossAxisCount);
    return Offset(
        (pos.col - origin.col).toDouble(), (pos.row - origin.row).toDouble());
  }

  void animFinish() {
    curIndex = nextIndex;
  }

  bool hasMoved() {
    return index != curIndex;
  }

  @override
  String toString() {
    return 'GridItemWrapper{index: $index, curIndex: $curIndex, nextIndex: $nextIndex}';
  }
}

class _Pos {
  int row;
  int col;

  _Pos({this.row, this.col})
      : assert(row != null),
        assert(col != null);
}