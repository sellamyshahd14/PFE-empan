import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TmtBPage extends StatefulWidget {
  final String patientId;

  const TmtBPage({super.key, required this.patientId});

  @override
  State<TmtBPage> createState() => _TmtBPageState();
}

class TmtItem {
  final int number;
  final bool isWhite; // true for White (First), false for Blue (Second)
  Offset position;

  TmtItem({
    required this.number,
    required this.isWhite,
    this.position = Offset.zero,
  });

  @override
  String toString() => '$number-${isWhite ? "W" : "B"}';
}

class _TmtBPageState extends State<TmtBPage> {
  final int _maxNumber = 25;
  List<TmtItem> _items = [];
  List<TmtItem> _connectedItems = [];

  // Logic tracking
  int _nextNumber = 1;
  bool _expectingWhite = true; // Start with 1-White

  Stopwatch _stopwatch = Stopwatch();
  bool _isTestRunning = false;
  bool _isTestCompleted = false;

  // Feedback state
  bool _showError = false;

  // Canvas size for randomization
  // Reduced size for TMT-B to fit 50 items
  final double _circleSize = 40.0;

  @override
  void initState() {
    super.initState();
  }

  void _generatePositions(Size size) {
    if (_items.isNotEmpty) return;

    // Generate items: 1..25 White and 1..25 Blue
    List<TmtItem> tempItems = [];
    for (int i = 1; i <= _maxNumber; i++) {
      tempItems.add(TmtItem(number: i, isWhite: true));
      tempItems.add(TmtItem(number: i, isWhite: false));
    }

    final random = Random();
    final double width = size.width;
    final double height = size.height;
    final double margin = 30.0; // Reduced margin

    // Shuffle strictly for checking positions, but ultimately we need random POSITIONS
    // We assign random positions to the list.

    List<Offset> positions = [];

    // Position generation
    for (int i = 0; i < tempItems.length; i++) {
      Offset newPos = Offset.zero;
      bool valid = false;
      int itemAttempts = 0;

      while (!valid && itemAttempts < 200) {
        double x =
            margin + random.nextDouble() * (width - 2 * margin - _circleSize);
        double y =
            margin + random.nextDouble() * (height - 2 * margin - _circleSize);
        newPos = Offset(x, y);

        bool overlaps = false;
        for (Offset pos in positions) {
          if ((pos - newPos).distance < _circleSize * 1.2) {
            // Tighter checking
            overlaps = true;
            break;
          }
        }

        if (!overlaps) valid = true;
        itemAttempts++;
      }

      // If failed to find space, just place randomly (fallback)
      if (!valid) {
        double x =
            margin + random.nextDouble() * (width - 2 * margin - _circleSize);
        double y =
            margin + random.nextDouble() * (height - 2 * margin - _circleSize);
        newPos = Offset(x, y);
      }

      positions.add(newPos);
      tempItems[i].position = newPos;
    }

    // Shuffle the array so drawing order (z-index) is random too?
    // Actually we just want the display to act randomly.
    // Let's shuffle the list so 1-W isn't always drawn first in the Stack (though z-index doesn't matter much here).
    tempItems.shuffle();

    // Directly assign
    _items = tempItems;
  }

  void _handleCircleTap(TmtItem item) {
    if (_isTestCompleted) return;

    if (!_isTestRunning) {
      _startTest();
    }

    // Check correctness
    bool isCorrect = false;

    if (item.number == _nextNumber && item.isWhite == _expectingWhite) {
      isCorrect = true;
    }

    if (isCorrect) {
      setState(() {
        _connectedItems.add(item);

        // Update expectation
        if (_expectingWhite) {
          // Was expecting White, now expect Blue of SAME number
          _expectingWhite = false;
        } else {
          // Was expecting Blue, now expect White of NEXT number
          _expectingWhite = true;
          _nextNumber++;
        }

        _showError = false;
      });

      // Completion check: Connected 25-Blue (which is 25, false)
      if (item.number == _maxNumber && !item.isWhite) {
        _finishTest();
      }
    } else {
      _triggerError();
    }
  }

  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _stopwatch.start();
    });
  }

  void _finishTest() {
    _stopwatch.stop();
    setState(() {
      _isTestCompleted = true;
    });
    _submitResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "أحسنت!",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "لقد أتممت الاختبار بنجاح.",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text("القائمة الرئيسية", style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _triggerError() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showError = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showError = false;
        });
      }
    });
  }

  void _submitResult() {
    final int elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    debugPrint(
      "TMT-B Completed in: $elapsedMilliseconds ms for patient ${widget.patientId}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _showError ? Colors.red[100] : Colors.white,
      appBar: AppBar(
        title: Text(
          "اختبار TMT-B",
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_items.isEmpty) {
            // Run ONE time generation
            _generatePositions(constraints.biggest);
          }

          return Stack(
            children: [
              // Lines Layer
              CustomPaint(
                size: Size.infinite,
                painter: LinePainterB(
                  connectedItems: _connectedItems,
                  circleSize: _circleSize,
                ),
              ),

              // Circles Layer
              ..._items.map((item) {
                // Colors definition
                // White Circle: White bg, Teal text/border
                // Blue Circle: Teal bg, White text

                Color bgColor;
                Color textColor;
                Color borderColor = Colors.teal;

                if (item.isWhite) {
                  bgColor = Colors.white;
                  textColor = Colors.teal;
                } else {
                  bgColor = Colors.teal;
                  textColor = Colors.white;
                }

                // If connected, maybe slightly dim or keep as is?
                // Requirement: Alternating colors. We keep original colors but maybe add visual check?
                // TMT usually just draws the line. The node itself stays same.

                // Special Labels
                bool isStart = (item.number == 1 && item.isWhite);
                bool isEnd = (item.number == _maxNumber && !item.isWhite);

                return Positioned(
                  left: item.position.dx,
                  top: item.position.dy,
                  child: GestureDetector(
                    onTap: () => _handleCircleTap(item),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isStart)
                          Text(
                            "بداية",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                        Container(
                          width: _circleSize,
                          height: _circleSize,
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${item.number}",
                            style: GoogleFonts.outfit(
                              fontSize: 16, // Smaller font for smaller circle
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),

                        if (isEnd)
                          Text(
                            "نهاية",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              if (!_isTestRunning && !_isTestCompleted)
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      "اربط الأرقام بالترتيب مع التناوب بين الألوان.\n1 (أبيض) -> 1 (أزرق) -> 2 (أبيض) -> 2 (أزرق)...",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class LinePainterB extends CustomPainter {
  final List<TmtItem> connectedItems;
  final double circleSize;

  LinePainterB({required this.connectedItems, required this.circleSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (connectedItems.length < 2) return;

    final paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < connectedItems.length - 1; i++) {
      // Adjust for column shift (text label above)
      // The top-left of the Positioned is item.position.
      // If "Start" label is present, drawing might be offset visually if we don't account for it,
      // but the item.position reflects the Positioned widget's top-left.
      // Inside the Positioned, we have a Column.
      // If label is present, the circle is pushed down.
      // This makes line drawing tricky if we don't know the exact offset.

      // SIMPLIFICATION: We will ignore the label offset for the line calculation for now
      // OR we simply assume the click area (and visual center) is the circle center.
      // To do this cleanly, position should be the CIRCLE's top-left, and label painted outside or Positioned separately.
      // BUT, current implementation puts them in a column.

      // Let's adjust:
      // Center = item.pos + circleSize/2.
      // Visual adjustment needed if Column has text.

      // Safer approach: Calculate Text Height?
      // Start Label: "بداية" ~ 18px height?
      // Let's guess ~18.0 if start/end.

      double yOffset1 = 0;
      if (connectedItems[i].number == 1 && connectedItems[i].isWhite)
        yOffset1 = 18;

      double yOffset2 = 0;
      if (connectedItems[i + 1].number == 1 && connectedItems[i + 1].isWhite)
        yOffset2 = 18;

      // Note: "End" text is BELOW, so it doesn't push the circle down. "Start" is ABOVE.

      final startPos =
          connectedItems[i].position +
          Offset(circleSize / 2, circleSize / 2 + yOffset1);
      final endPos =
          connectedItems[i + 1].position +
          Offset(circleSize / 2, circleSize / 2 + yOffset2);

      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainterB oldDelegate) {
    return oldDelegate.connectedItems.length != connectedItems.length;
  }
}
