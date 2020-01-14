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
            columnCount: 3,
            rowCount: 3,
            dotGap: 100,
            dotRadius: 5,
            password: [1, 3, 4, 6, 7, 5, 2],
            onCorrect: () {
              print('correct!');
            },
            onWrong: () {
              print('wrong!');
            },
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
    @required this.password,
    this.onCorrect,
    this.onWrong,
  }) : super(key: key);

  final List<int> password;
  final int rowCount;
  final int columnCount;
  final double dotGap;
  final double dotRadius;
  final Function onCorrect;
  final Function onWrong;

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  List<int> _selectedDotIndices = [];

  Offset _touchPosition;
  bool _isWrong = false;

  void onPanUpdate(DragUpdateDetails details) {
    if (_isWrong) return;
    setState(() {
      _touchPosition = details.localPosition;
    });
    final selectedDotIndex = MyPainter.dotPositions.indexWhere(
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
      widget.onCorrect();
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Correct password'),
      ));
    } else {
      setState(() {
        _isWrong = true;
        _touchPosition = null;
      });
      Vibration.vibrate(duration: 300, amplitude: 255);
      widget.onWrong();
      print(_selectedDotIndices);
      Future.delayed(Duration(milliseconds: 500)).then((_) {
        setState(() {
          _isWrong = false;
          _selectedDotIndices = [];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: CustomPaint(
        painter: MyPainter(
          rowCount: widget.rowCount,
          columnCount: widget.columnCount,
          dotGap: widget.dotGap,
          dotRadius: widget.dotRadius,
          selectedDotIndices: _selectedDotIndices,
          touchPosition: _touchPosition,
          selectColor: _isWrong ? Colors.red : Colors.blue,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter({
    @required this.rowCount,
    @required this.columnCount,
    @required this.dotGap,
    @required this.dotRadius,
    this.selectedDotIndices,
    this.touchPosition,
    this.selectColor,
  });

  final int rowCount;
  final int columnCount;
  final double dotGap;
  final double dotRadius;
  final List<int> selectedDotIndices;
  final Offset touchPosition;
  final Color selectColor;

  static List<Offset> dotPositions;
  static String serializedLayoutState;

  List<Offset> calculateDotPositions(Size canvasSize) {
    final gridWidth = dotGap * (columnCount - 1);
    final gridHeight = dotGap * (rowCount - 1);
    final shiftToCenter =
        Offset(canvasSize.width - gridWidth, canvasSize.height - gridHeight) /
            2;
    List<Offset> dotPositions = [];
    for (var r = 0; r < rowCount; r++) {
      for (var c = 0; c < columnCount; c++) {
        final dot = Offset(c * dotGap, r * dotGap);
        dotPositions.add(dot + shiftToCenter);
      }
    }
    return dotPositions;
  }

  String serializeLayoutState(Size size) {
    return '$rowCount $columnCount $dotGap ${size.toString()}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (MyPainter.dotPositions == null ||
        MyPainter.serializedLayoutState != serializeLayoutState(size)) {
      MyPainter.dotPositions = calculateDotPositions(size);
      MyPainter.serializedLayoutState = serializeLayoutState(size);
      print('recalculated dot positions');
    }

    final dotPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

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
        ..color = selectColor ?? Colors.black;

      canvas.drawPath(path, linePaint);

      final selectedDotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = selectColor ?? Colors.black;

      for (final i in selectedDotIndices) {
        final position = dotPositions[i];
        canvas.drawCircle(position, dotRadius, selectedDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
