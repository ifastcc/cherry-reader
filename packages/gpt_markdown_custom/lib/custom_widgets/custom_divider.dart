import 'package:flutter/material.dart';

/// A custom divider widget that extends LeafRenderObjectWidget.
///
/// The [CustomDivider] widget is used to create a horizontal divider line in the UI.
/// It takes an optional [color] parameter to specify the color of the divider,
/// and an optional [height] parameter to set the height of the divider.
///
class CustomDivider extends LeafRenderObjectWidget {
  const CustomDivider({super.key, this.height, this.color});

  /// The color of the divider.
  ///
  /// If not provided, the divider will use the color of the current theme.
  final Color? color;

  /// The height of the divider.
  ///
  /// If not provided, the divider will have a default height of 2.
  final double? height;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderDivider(
      color ?? Theme.of(context).colorScheme.outline,
      MediaQuery.sizeOf(context).width,
      height ?? 2,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderDivider renderObject,
  ) {
    renderObject.color = color ?? Theme.of(context).colorScheme.outline;
    renderObject.height = height ?? 2;
    renderObject.width = MediaQuery.sizeOf(context).width;
  }
}

/// A custom render object for the [CustomDivider] widget.
///
/// The [RenderDivider] class extends RenderBox and is responsible for
/// painting the divider line. It takes a [color], [width], and [height]
/// and uses them to draw a horizontal line in the UI.
///
class RenderDivider extends RenderBox {
  RenderDivider(Color color, double width, double height)
    : _color = color,
      _height = height,
      _width = width;
  Color _color;
  double _height;
  double _width;

  /// The color of the divider.
  set color(Color value) {
    if (value == _color) {
      return;
    }
    _color = value;
    markNeedsPaint();
  }

  /// The height of the divider.
  set height(double value) {
    if (value == _height) {
      return;
    }
    _height = value;
    markNeedsLayout();
  }

  /// The width of the divider.
  set width(double value) {
    if (value == _width) {
      return;
    }
    _width = value;
    markNeedsLayout();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return BoxConstraints.tightFor(
      width: null,
      height: _height,
    ).enforce(constraints).smallest;
  }

  @override
  void performLayout() {
    size = getDryLayout(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawRect(
      offset & Size(Rect.largest.size.width, _height),
      Paint()..color = _color,
    );
  }
}
