import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TmtVisualizer extends StatelessWidget {
  final String testType;
  final List<dynamic> path;

  const TmtVisualizer({
    super.key,
    required this.testType,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // Define the standard layouts based on the test files
        final List<TmtCircleData> allCircles = _getLayoutForTest(testType);
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            size: Size(width, height),
            painter: TmtPathPainter(
              testType: testType,
              path: path,
              circles: allCircles,
            ),
          ),
        );
      },
    );
  }

  List<TmtCircleData> _getLayoutForTest(String type) {
    if (type == "TMT-A") {
      return _tmtALayout;
    } else if (type == "TMT-B") {
      return _tmtBLayout;
    } else if (type == "TMT-C") {
      return _tmtCLayout;
    }
    return [];
  }

  // --- Layout Data (Simplified and scaled to 0..1) ---
  
  static final List<TmtCircleData> _tmtALayout = [
    [0.65, 0.58, "1", true], [0.45, 0.65, "2", true], [0.72, 0.72, "3", true],
    [0.75, 0.40, "4", true], [0.40, 0.40, "5", true], [0.55, 0.48, "6", true],
    [0.35, 0.55, "7", true], [0.25, 0.67, "8", true], [0.28, 0.78, "9", true],
    [0.38, 0.67, "10", true], [0.60, 0.82, "11", true], [0.18, 0.85, "12", true],
    [0.25, 0.46, "13", true], [0.18, 0.58, "14", true], [0.17, 0.18, "15", true],
    [0.30, 0.32, "16", true], [0.56, 0.18, "17", true], [0.52, 0.34, "18", true],
    [0.80, 0.26, "19", true], [0.64, 0.24, "20", true], [0.88, 0.18, "21", true],
    [0.89, 0.40, "22", true], [0.88, 0.85, "23", true], [0.82, 0.55, "24", true],
    [0.78, 0.82, "25", true],
  ].map((e) => TmtCircleData(x: e[0] as double, y: e[1] as double, label: e[2] as String, isWhite: e[3] as bool)).toList();

  static final List<TmtCircleData> _tmtBLayout = [
    [0.68, 0.53, "1", true],  [0.60, 0.60, "1", false], [0.50, 0.62, "2", true], [0.55, 0.65, "2", false],
    [0.73, 0.67, "3", true],  [0.85, 0.65, "3", false], [0.82, 0.45, "4", true], [0.75, 0.38, "4", false],
    [0.45, 0.38, "5", true],  [0.33, 0.37, "5", false], [0.35, 0.48, "6", true], [0.55, 0.46, "6", false],
    [0.40, 0.55, "7", true],  [0.30, 0.56, "7", false], [0.18, 0.74, "8", true], [0.23, 0.66, "8", false],
    [0.28, 0.75, "9", true],  [0.30, 0.85, "9", false], [0.43, 0.77, "10", true], [0.37, 0.66, "10", false],
    [0.55, 0.78, "11", true], [0.60, 0.70, "11", false], [0.22, 0.84, "12", true], [0.12, 0.81, "12", false],
    [0.25, 0.46, "13", true], [0.28, 0.51, "13", false], [0.22, 0.37, "14", true], [0.12, 0.57, "14", false],
    [0.15, 0.17, "15", true], [0.25, 0.13, "15", false], [0.38, 0.17, "16", true], [0.28, 0.29, "16", false],
    [0.50, 0.15, "17", true], [0.63, 0.12, "17", false], [0.40, 0.29, "18", true], [0.51, 0.34, "18", false],
    [0.73, 0.22, "19", true], [0.72, 0.29, "19", false], [0.60, 0.29, "20", true], [0.63, 0.22, "20", false],
    [0.82, 0.16, "21", true], [0.75, 0.11, "21", false], [0.78, 0.34, "22", true], [0.85, 0.37, "22", false],
    [0.85, 0.85, "23", true], [0.70, 0.85, "23", false], [0.68, 0.62, "24", true], [0.79, 0.52, "24", false],
    [0.75, 0.80, "25", true], [0.64, 0.85, "25", false],
  ].map((e) => TmtCircleData(x: e[0] as double, y: e[1] as double, label: e[2] as String, isWhite: e[3] as bool)).toList();

  static final List<TmtCircleData> _tmtCLayout = [
    [0.10, 0.10, "1", true], [0.45, 0.15, "A", true], [0.85, 0.08, "2", true], [0.90, 0.45, "B", true],
    [0.75, 0.65, "3", true], [0.90, 0.90, "C", true], [0.55, 0.85, "4", true], [0.20, 0.90, "D", true],
    [0.05, 0.60, "5", true], [0.30, 0.40, "E", true], [0.70, 0.40, "6", true], [0.60, 0.20, "F", true],
    [0.25, 0.25, "7", true], [0.35, 0.65, "G", true], [0.50, 0.50, "8", true], [0.08, 0.80, "H", true],
  ].map((e) => TmtCircleData(x: e[0] as double, y: e[1] as double, label: e[2] as String, isWhite: e[3] as bool)).toList();
}

class TmtCircleData {
  final double x;
  final double y;
  final String label;
  final bool isWhite;

  TmtCircleData({required this.x, required this.y, required this.label, required this.isWhite});
  
  String get identifier => isWhite ? "$label-W" : "$label-B";
}

class TmtPathPainter extends CustomPainter {
  final String testType;
  final List<dynamic> path;
  final List<TmtCircleData> circles;

  TmtPathPainter({
    required this.testType,
    required this.path,
    required this.circles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double margin = 20.0;
    final double circleSize = 24.0;
    final double usableWidth = size.width - 2 * margin - circleSize;
    final double usableHeight = size.height - 2 * margin - circleSize;

    // 1. Draw all circles first
    for (var circle in circles) {
      final pos = Offset(
        margin + circle.x * usableWidth + circleSize / 2,
        margin + circle.y * usableHeight + circleSize / 2,
      );

      final paint = Paint()
        ..color = circle.isWhite ? Colors.white : Colors.teal
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = Colors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(pos, circleSize / 2, paint);
      canvas.drawCircle(pos, circleSize / 2, borderPaint);

      // Label
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: circle.label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: circle.isWhite ? Colors.teal : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // 2. Draw the patient's path
    if (path.isEmpty) return;

    final pathPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final errorPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    Offset? lastPos;
    String? lastLabel;

    for (int i = 0; i < path.length; i++) {
      final currentLabel = path[i].toString();
      TmtCircleData? circle;

      // Find circle matching this path step
      if (testType == "TMT-A") {
        circle = circles.firstWhere((c) => c.label == currentLabel);
      } else if (testType == "TMT-B") {
        // Path for B is "1-W", "1-B", etc.
        circle = circles.firstWhere((c) => c.identifier == currentLabel);
      } else { // TMT-C
        circle = circles.firstWhere((c) => c.label == currentLabel);
      }

      final currentPos = Offset(
        margin + circle.x * usableWidth + circleSize / 2,
        margin + circle.y * usableHeight + circleSize / 2,
      );

      if (lastPos != null) {
        // Check if this connection was sequential (correct) or an error
        bool isCorrect = _isConnectionCorrect(testType, lastLabel!, currentLabel);
        canvas.drawLine(lastPos, currentPos, isCorrect ? pathPaint : errorPaint);
      }

      lastPos = currentPos;
      lastLabel = currentLabel;
    }
  }

  bool _isConnectionCorrect(String type, String prev, String curr) {
    if (type == "TMT-A") {
      return (int.tryParse(curr) ?? 0) == (int.tryParse(prev) ?? 0) + 1;
    } else if (type == "TMT-B") {
       // Sequence: 1-W -> 1-B -> 2-W -> 2-B ...
       final prevParts = prev.split('-');
       final currParts = curr.split('-');
       final prevNum = int.parse(prevParts[0]);
       final prevCol = prevParts[1];
       final currNum = int.parse(currParts[0]);
       final currCol = currParts[1];

       if (prevCol == 'W') {
         return (currNum == prevNum && currCol == 'B');
       } else {
         return (currNum == prevNum + 1 && currCol == 'W');
       }
    } else { // TMT-C: 1, A, 2, B ...
      final labels = ["1", "A", "2", "B", "3", "C", "4", "D", "5", "E", "6", "F", "7", "G", "8", "H"];
      final prevIdx = labels.indexOf(prev);
      final currIdx = labels.indexOf(curr);
      return currIdx == prevIdx + 1;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
