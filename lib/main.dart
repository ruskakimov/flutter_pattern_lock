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
          title: Text('Lock screen demo'),
        ),
        body: Center(
          child: LockScreen(
            columnCount: 4,
            rowCount: 4,
            password: [0, 1, 2],
          ),
        ),
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({
    Key key,
    this.rowCount = 3,
    this.columnCount = 3,
    this.dotGap = 100,
    this.dotRadius = 5,
    this.padding = const EdgeInsets.all(30),
    @required this.password,
  }) : super(key: key);

  final List<int> password;
  final int rowCount;
  final int columnCount;
  final double dotGap;
  final double dotRadius;
  final EdgeInsets padding;
  // final Paint dotPaint;
  // final Paint linePaint;

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  Size _canvasSize;

  List<Offset> _dotPositions;
  List<int> _selectedDotIndices = [];

  Offset _touchPosition;
  bool _isWrong = false;

  Size calculateCanvasSize() {
    final gridWidth = widget.dotGap * (widget.columnCount - 1);
    final gridHeight = widget.dotGap * (widget.rowCount - 1);
    return Size(gridWidth + widget.padding.horizontal,
        gridHeight + widget.padding.vertical);
  }

  List<Offset> calculateDotPositions() {
    List<Offset> dotPositions = [];
    for (var r = 0; r < widget.rowCount; r++) {
      for (var c = 0; c < widget.columnCount; c++) {
        final dot = Offset(c * widget.dotGap, r * widget.dotGap);
        dotPositions.add(dot + widget.padding.topLeft);
      }
    }
    return dotPositions;
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_isWrong) return;
    setState(() {
      _touchPosition = details.localPosition;
    });
    final selectedDotIndex = _dotPositions.indexWhere(
        (position) => (details.localPosition - position).distance < 30);

    if (selectedDotIndex != -1 &&
        !_selectedDotIndices.contains(selectedDotIndex)) {
      setState(() {
        _selectedDotIndices.add(selectedDotIndex);
      });
      Vibration.vibrate(duration: 20, amplitude: 255);
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (_isWrong || _selectedDotIndices.isEmpty) return;
    if (_selectedDotIndices.toString() == widget.password.toString()) {
      setState(() {
        _selectedDotIndices = [];
      });
    } else {
      setState(() {
        _isWrong = true;
        _touchPosition = null;
      });
      Vibration.vibrate(duration: 500, amplitude: 255);
      Future.delayed(Duration(milliseconds: 500)).then((_) {
        setState(() {
          _isWrong = false;
          _selectedDotIndices = [];
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _canvasSize = calculateCanvasSize();
    _dotPositions = calculateDotPositions();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: CustomPaint(
        painter: MyPainter(
          dotRadius: widget.dotRadius,
          dotPositions: _dotPositions,
          selectedDotIndices: _selectedDotIndices,
          touchPosition: _touchPosition,
        ),
        size: _canvasSize,
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({
    @required this.dotRadius,
    @required this.dotPositions,
    this.selectedDotIndices,
    this.touchPosition,
    this.dotPaintt,
  });

  final double dotRadius;
  final List<Offset> dotPositions;
  final List<int> selectedDotIndices;
  final Offset touchPosition;
  final Paint dotPaintt;

  @override
  void paint(Canvas canvas, Size size) {
    if (dotPositions == null) return;

    final dotPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final position in dotPositions) {
      canvas.drawCircle(position, dotRadius, dotPaint);
    }

    if (selectedDotIndices.isNotEmpty) {
      final path = Path();
      final firstDotPosition = dotPositions[selectedDotIndices.first];

      path.moveTo(firstDotPosition.dx, firstDotPosition.dy);

      for (final i in selectedDotIndices) {
        final position = dotPositions[i];
        path.lineTo(position.dx, position.dy);
      }
      if (touchPosition != null) {
        path.lineTo(touchPosition.dx, touchPosition.dy);
      }

      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black;

      canvas.drawPath(path, linePaint);

      final selectedDotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black;

      for (final i in selectedDotIndices) {
        final position = dotPositions[i];
        canvas.drawCircle(position, dotRadius, selectedDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
