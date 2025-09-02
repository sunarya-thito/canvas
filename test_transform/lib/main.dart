import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(title: 'Flutter Demo', home: App()));
}

Offset _getShearFromPolygon(Polygon transformedPolygon) {
  final Offset transformedTopLeft = transformedPolygon.topLeft;
  final Offset transformedTopRight = transformedPolygon.topRight;
  final Offset transformedBottomLeft = transformedPolygon.bottomLeft;

  // Calculate the transformed top edge vector
  // This corresponds to the original (W, 0) vector transformed
  final double v_top_t_dx = transformedTopRight.dx - transformedTopLeft.dx;
  final double v_top_t_dy = transformedTopRight.dy - transformedTopLeft.dy;

  // shear.dy = atan2( (W*sin(shear.dy)), (W*cos(shear.dy)) )
  final double dy = atan2(v_top_t_dy, v_top_t_dx);

  // Calculate the transformed left edge vector
  // This corresponds to the original (0, H) vector transformed
  final double v_left_t_dx = transformedBottomLeft.dx - transformedTopLeft.dx;
  final double v_left_t_dy = transformedBottomLeft.dy - transformedTopLeft.dy;

  // shear.dx = atan2( (H*sin(shear.dx)), (H*cos(shear.dx)) )
  final double dx = atan2(v_left_t_dx, v_left_t_dy);

  return Offset(dx, dy);
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final Offset _parentShear = const Offset(45 / 180 * pi, -60 / 180 * pi);
  final Offset _shear = const Offset(30 / 180 * pi, -30 / 180 * pi);

  Offset _shearDelta = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    var transform =
        computeShearMatrix(_parentShear) * computeShearMatrix(_shear);
    var (
      positionDelta,
      shearDelta,
      sizeDelta,
      polygon,
    ) = resizeGlobalShearMatrix(
      computeShearMatrix(_parentShear),
      transform,
      Offset.zero,
      Size(100, 100),
      Alignment.center,
      _shearDelta,
    );
    var newTransform =
        computeShearMatrix(_parentShear) *
        computeShearMatrix(_shear + shearDelta) *
        Matrix4.translationValues(positionDelta.dx, positionDelta.dy, 0);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform(
                    transform: newTransform,
                    child: Container(
                      width: 100 + sizeDelta.width,
                      height: 100 + sizeDelta.height,
                      color: Colors.blue,
                      child: Text('Container'),
                    ),
                  ),
                  CustomPaint(
                    size: Size(100, 100),
                    painter: PolygonPainter(
                      polygon,
                      Colors.red.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // slider
          Slider(
            value: _shearDelta.dx,
            min: 0,
            max: 180,
            onChanged: (value) {
              setState(() {
                _shearDelta = Offset(value, _shearDelta.dy);
              });
            },
          ),
          Slider(
            value: _shearDelta.dy,
            min: 0,
            max: 180,
            onChanged: (value) {
              setState(() {
                _shearDelta = Offset(_shearDelta.dx, value);
              });
            },
          ),
        ],
      ),
    );
  }
}

Matrix4 computeShearMatrix(Offset shear) {
  final shearMatrix =
      Matrix4.identity()
        ..setEntry(0, 1, tan(shear.dx))
        ..setEntry(1, 0, tan(shear.dy));
  final scaleMatrix =
      Matrix4.identity()
        ..setEntry(1, 1, cos(shear.dx))
        ..setEntry(0, 0, cos(shear.dy));
  return shearMatrix * scaleMatrix;
}

Offset computeShearFromMatrix(Matrix4 matrix) {
  // Extract the sine and cosine components for dx and dy
  // from the matrix entries.
  // sin(shear.dx) is at matrix.entry(0, 1)
  // cos(shear.dx) is at matrix.entry(1, 1)
  // sin(shear.dy) is at matrix.entry(1, 0)
  // cos(shear.dy) is at matrix.entry(0, 0)

  final double sinDx = matrix.entry(0, 1);
  final double cosDx = matrix.entry(1, 1);

  final double sinDy = matrix.entry(1, 0);
  final double cosDy = matrix.entry(0, 0);

  // Use atan2 to compute dx and dy from their sine and cosine values.
  // atan2(y, x) computes the arc tangent of y/x, using the signs
  // of both arguments to determine the quadrant of the result.
  final double dx = atan2(sinDx, cosDx);
  final double dy = atan2(sinDy, cosDy);

  return Offset(dx, dy);
}

// returns a shear delta
(Offset positionDelta, Offset shearDelta, Size sizeDelta, List<Offset> polygon)
resizeGlobalShearMatrix(
  Matrix4 parentMatrix,
  Matrix4 matrix,
  Offset position,
  Size size,
  Alignment anchor,
  Offset sizeDelta,
) {
  Offset topLeft = position;
  Offset topRight = position + Offset(size.width, 0);
  Offset bottomLeft = position + Offset(0, size.height);
  Offset bottomRight = position + Offset(size.width, size.height);
  topLeft = transformOffset(topLeft, matrix);
  topRight = transformOffset(topRight, matrix);
  bottomLeft = transformOffset(bottomLeft, matrix);
  bottomRight = transformOffset(bottomRight, matrix);
  Rect rect = _fromPoints(topLeft, topRight, bottomLeft, bottomRight);
  Offset origin = rect.topLeft + anchor.alongSize(rect.size);
  var newTopLeft =
      topLeft + _shiftOffset(topLeft, sizeDelta, origin, rect.size);
  var newTopRight =
      topRight + _shiftOffset(topRight, sizeDelta, origin, rect.size);
  var newBottomLeft =
      bottomLeft + _shiftOffset(bottomLeft, sizeDelta, origin, rect.size);
  var newBottomRight =
      bottomRight + _shiftOffset(bottomRight, sizeDelta, origin, rect.size);
  Offset currentShear = computeShearFromMatrix(matrix);
  final newWidth = (newTopRight - newTopLeft).distance;
  final newHeight = (newBottomLeft - newTopLeft).distance;
  final visualSizeDelta = Size(newWidth - size.width, newHeight - size.height);
  Offset newSheared = _getShearFromPolygon((
    topLeft: newTopLeft,
    topRight: newTopRight,
    bottomRight: newBottomRight,
    bottomLeft: newBottomLeft,
  ));
  return (
    newTopLeft - topLeft,
    newSheared - currentShear,
    visualSizeDelta,
    [newTopLeft, newTopRight, newBottomRight, newBottomLeft],
  );
}

typedef Polygon =
    ({Offset topLeft, Offset topRight, Offset bottomRight, Offset bottomLeft});

Polygon _transformPolygon(Polygon polygon, Matrix4 matrix) {
  return (
    topLeft: transformOffset(polygon.topLeft, matrix),
    topRight: transformOffset(polygon.topRight, matrix),
    bottomRight: transformOffset(polygon.bottomRight, matrix),
    bottomLeft: transformOffset(polygon.bottomLeft, matrix),
  );
}

extension PolygonExtension on Polygon {
  Polygon transform(Matrix4 matrix) {
    return _transformPolygon(this, matrix);
  }
}

Offset _shiftOffset(Offset offset, Offset delta, Offset origin, Size size) {
  return Offset(
    (offset.dx - origin.dx) / size.width * delta.dx,
    (offset.dy - origin.dy) / size.height * delta.dy,
  );
}

Rect _fromPoints(
  Offset topLeft,
  Offset topRight,
  Offset bottomLeft,
  Offset bottomRight,
) {
  return Rect.fromPoints(
    Offset(min(topLeft.dx, bottomLeft.dx), min(topLeft.dy, topRight.dy)),
    Offset(
      max(topRight.dx, bottomRight.dx),
      max(bottomLeft.dy, bottomRight.dy),
    ),
  );
}

Offset _convertAlignmentToOffset(Alignment alignment) {
  // alignment is in the range of -1 to 1, where 0 is the center
  // convert to the range of 0 to 1 where 0.5 is the center
  return Offset((alignment.x + 1) / 2, (alignment.y + 1) / 2);
}

Offset transformOffset(Offset offset, Matrix4 transform) {
  return MatrixUtils.transformPoint(transform, offset);
}

void printShearMatrix(Matrix4 shearMatrix) {
  var shear = computeShearFromMatrix(shearMatrix);
  printShear(shear);
}

void printShear(Offset shear) {
  print('shear: ${shear.dx * 180 / pi}, ${shear.dy * 180 / pi}');
}

class PolygonPainter extends CustomPainter {
  final List<Offset> polygon;
  final Color color;

  PolygonPainter(this.polygon, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(polygon[0].dx, polygon[0].dy);
    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(polygon[i].dx, polygon[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
