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
            size: Size.square(300),
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
    this.size = const Size(300, 300),
    @required this.password,
  }) : super(key: key);

  final List<int> password;
  final int rowCount;
  final int columnCount;
  final double dotGap;
  final double dotRadius;
  final Size size;
  // final Paint dotPaint;
  // final Paint linePaint;

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  List<Offset> _dotPositions;
  List<int> _selectedDotIndices = [];

  Offset _touchPosition;
  bool _isWrong = false;

  List<Offset> calculateDotPositions() {
    final gridWidth = widget.dotGap * (widget.columnCount - 1);
    final gridHeight = widget.dotGap * (widget.rowCount - 1);
    final shift =
        Offset(widget.size.width - gridWidth, widget.size.height - gridHeight) /
            2;
    List<Offset> dotPositions = [];

    for (var r = 0; r < widget.rowCount; r++) {
      for (var c = 0; c < widget.columnCount; c++) {
        final dot = Offset(c * widget.dotGap, r * widget.dotGap);
        dotPositions.add(dot + shift);
      }
    }
    return dotPositions;
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_isWrong) return;
    setState(() {
      _touchPosition = details.localPosition;
    });
    // if one is close enough and index is not in _selected, add index to _selected and vibrate
    final selectedDotIndex = _dotPositions.indexWhere(
        (position) => (details.localPosition - position).distance < 30);

    if (selectedDotIndex != -1 &&
        !_selectedDotIndices.contains(selectedDotIndex)) {
      setState(() {
        _selectedDotIndices.add(selectedDotIndex);
        print(_selectedDotIndices);
      });
      Vibration.vibrate(duration: 20, amplitude: 255);
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (_isWrong) return;
    // check selected for correctness if selected is not empty
    // if wrong set _isWrong = true for 1 second, call onWrongEntry
    // else call onCorrectEntry
    setState(() {
      _selectedDotIndices = [];
    });
  }

  @override
  void initState() {
    super.initState();
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
        size: widget.size,
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
  });

  final double dotRadius;
  final List<Offset> dotPositions;
  final List<int> selectedDotIndices;
  final Offset touchPosition;

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
