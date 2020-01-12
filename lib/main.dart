import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lock screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Lock screen'),
        ),
        body: LockScreen(),
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({
    Key key,
  }) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  List<Offset> _path = [];
  Offset _touchPosition;
  static const _password = [
    [0, 1],
    [1, 1],
    [1, 2],
    [2, 2],
    [2, 1],
  ];
  bool _isInteractive = true;

  bool isPasswordCorrect() {
    HashMap<Offset, List<int>> polePositionToIndices = HashMap();
    for (int xIndex = 0; xIndex < MyPainter.xValues.length; xIndex++) {
      for (int yIndex = 0; yIndex < MyPainter.yValues.length; yIndex++) {
        final polePosition =
            Offset(MyPainter.xValues[xIndex], MyPainter.yValues[yIndex]);
        polePositionToIndices[polePosition] = [xIndex, yIndex];
      }
    }
    final _enteredPassword = _path
        .map((polePosition) => polePositionToIndices[polePosition])
        .toList();
    return _enteredPassword.toString() == _password.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (DragUpdateDetails details) {
        if (!_isInteractive) return;
        setState(() {
          _touchPosition = details.localPosition;
        });
        for (final x in MyPainter.xValues) {
          for (final y in MyPainter.yValues) {
            final pole = Offset(x, y);
            final isClose = (pole - details.localPosition).distance < 30;
            final isNotSelected = !_path.contains(pole);
            if (isClose && isNotSelected) {
              setState(() {
                _path.add(pole);
                Vibration.vibrate(duration: 20, amplitude: 255);
              });
            }
          }
        }
      },
      onPanEnd: (DragEndDetails details) {
        if (!_isInteractive) return;
        if (isPasswordCorrect()) {
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Text('Correct password'),
            ),
          );
          setState(() {
            _path = [];
          });
        } else {
          Vibration.vibrate(duration: 500, amplitude: 255);
          setState(() {
            _touchPosition = null;
            _isInteractive = false;
          });
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            setState(() {
              _path = [];
              _isInteractive = true;
            });
          });
        }
      },
      child: CustomPaint(
        painter: MyPainter(
          pathPoints: _path,
          touchPosition: _touchPosition,
          color: _isInteractive ? Colors.black : Colors.red,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({
    this.pathPoints,
    this.touchPosition,
    this.color,
  });

  final List<Offset> pathPoints;
  final Offset touchPosition;
  static List<double> xValues;
  static List<double> yValues;
  final Color color;

  void _paintPath(Canvas canvas) {
    if (pathPoints.isEmpty) return;

    final path = Path();

    path.moveTo(pathPoints.first.dx, pathPoints.first.dy);

    for (final point in pathPoints) {
      path.lineTo(point.dx, point.dy);
    }
    if (touchPosition != null) {
      path.lineTo(touchPosition.dx, touchPosition.dy);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color;

    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    xValues = [
      size.width / 2 - 100,
      size.width / 2,
      size.width / 2 + 100,
    ];

    yValues = [
      size.height / 2 - 150,
      size.height / 2 - 50,
      size.height / 2 + 50,
      size.height / 2 + 150,
    ];

    final paint = Paint();
    paint.color = Colors.black;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;

    for (final x in xValues) {
      for (final y in yValues) {
        final position = Offset(x, y);
        if (pathPoints.contains(position)) continue;
        canvas.drawCircle(position, 10, paint);
      }
    }

    _paintPath(canvas);

    paint.style = PaintingStyle.fill;
    paint.color = color;
    for (final point in pathPoints) {
      canvas.drawCircle(point, 10, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
