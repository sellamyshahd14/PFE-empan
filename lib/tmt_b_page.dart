import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'services/firestore_service.dart';

class TmtBPage extends StatefulWidget {
  final String patientId;
  final String patientIdentifier;

  const TmtBPage({
    super.key,
    required this.patientId,
    required this.patientIdentifier,
  });

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
  final FirestoreService _firestoreService = FirestoreService();
  final int _maxNumber = 25;
  List<TmtItem> _items = [];
  final List<TmtItem> _connectedItems = [];

  // Logic tracking
  int _nextNumber = 1;
  bool _expectingWhite = true; // Start with 1-White

  final Stopwatch _stopwatch = Stopwatch();
  bool _isTestRunning = false;
  bool _isTestCompleted = false;

  // Feedback state
  bool _showError = false;
  int _errorCount = 0;

  final double _circleSize = 40.0;

  // Fixed positions for TMT-B (normalized 0..1 coordinates)
  // [number, isWhite (1=white, 0=blue/filled), x, y]
  // Mapped from the official TMT-B reference layout
  static const List<List<double>> _normalizedPositions = [
    // White Circles (1-25) - Mapped from Image
    [1, 1, 0.65, 0.62], // 1 (début)
    [2, 1, 0.55, 0.73], // 2
    [3, 1, 0.70, 0.80], // 3
    [4, 1, 0.80, 0.48], // 4
    [5, 1, 0.38, 0.42], // 5
    [6, 1, 0.37, 0.52], // 6
    [7, 1, 0.36, 0.61], // 7
    [8, 1, 0.14, 0.87], // 8
    [9, 1, 0.25, 0.88], // 9
    [10, 1, 0.38, 0.90], // 10
    [11, 1, 0.58, 0.91], // 11
    [12, 1, 0.18, 0.98], // 12
    [13, 1, 0.20, 0.51], // 13
    [14, 1, 0.17, 0.37], // 14
    [15, 1, 0.07, 0.11], // 15
    [16, 1, 0.36, 0.12], // 16
    [17, 1, 0.51, 0.10], // 17
    [18, 1, 0.38, 0.28], // 18
    [19, 1, 0.76, 0.19], // 19
    [20, 1, 0.63, 0.28], // 20
    [21, 1, 0.85, 0.10], // 21
    [22, 1, 0.77, 0.36], // 22
    [23, 1, 0.84, 0.96], // 23
    [24, 1, 0.66, 0.73], // 24
    [25, 1, 0.74, 0.92], // 25 (fin)

    // Black/Blue Circles (1-25) - Mapped from Image
    [1, 0, 0.65, 0.68], // 1-B (Inferred below 1W)
    [2, 0, 0.43, 0.73], // 2-B
    [3, 0, 0.83, 0.74], // 3-B
    [4, 0, 0.71, 0.41], // 4-B
    [5, 0, 0.31, 0.38], // 5-B
    [6, 0, 0.55, 0.51], // 6-B
    [7, 0, 0.24, 0.66], // 7-B
    [8, 0, 0.21, 0.77], // 8-B
    [9, 0, 0.25, 0.82], // 9-B (Inferred room)
    [10, 0, 0.33, 0.76], // 10-B
    [11, 0, 0.60, 0.84], // 11-B
    [12, 0, 0.09, 0.96], // 12-B
    [13, 0, 0.24, 0.58], // 13-B
    [14, 0, 0.08, 0.65], // 14-B
    [15, 0, 0.22, 0.07], // 15-B
    [16, 0, 0.21, 0.28], // 16-B
    [17, 0, 0.64, 0.06], // 17-B
    [18, 0, 0.45, 0.32], // 18-B
    [19, 0, 0.74, 0.29], // 19-B
    [20, 0, 0.59, 0.18], // 20-B
    [21, 0, 0.80, 0.06], // 21-B
    [22, 0, 0.84, 0.40], // 22-B
    [23, 0, 0.92, 0.96], // 23-B (Inferred corner)
    [24, 0, 0.79, 0.61], // 24-B
    [25, 0, 0.60, 0.98], // 25-B
  ];

  @override
  void initState() {
    super.initState();
  }

  void _generatePositions(Size size) {
    if (_items.isNotEmpty) {
      return;
    }

    final double margin = 20.0;
    final double usableWidth = size.width - 2 * margin - _circleSize;
    final double usableHeight = size.height - 2 * margin - _circleSize;

    // Safety padding: circles shouldn't be closer than this center-to-center
    final double minAllowedDistance = _circleSize + 12.0;

    List<TmtItem> tempItems = [];

    // 1. Initialize with target positions from reference image
    for (final pos in _normalizedPositions) {
      final int number = pos[0].toInt();
      final bool isWhite = pos[1] == 1.0;
      final double x = margin + pos[2] * usableWidth;
      final double y = margin + pos[3] * usableHeight;

      tempItems.add(TmtItem(
        number: number,
        isWhite: isWhite,
        position: Offset(x, y),
      ));
    }

    // 2. Iterative Relaxation (Collision Resolution)
    // We run multiple passes to push overlapping circles away from each other
    // while trying to stay close to the original relative layout.
    for (int iteration = 0; iteration < 50; iteration++) {
      bool changed = false;
      for (int i = 0; i < tempItems.length; i++) {
        for (int j = i + 1; j < tempItems.length; j++) {
          final itemA = tempItems[i];
          final itemB = tempItems[j];

          final dx = itemB.position.dx - itemA.position.dx;
          final dy = itemB.position.dy - itemA.position.dy;
          final double distance = Offset(dx, dy).distance;

          if (distance < minAllowedDistance) {
            changed = true;
            // Avoid division by zero if they are at the exact same spot
            final double actualDist = distance == 0 ? 0.1 : distance;
            final double overlap = minAllowedDistance - actualDist;

            // Vector to push them apart
            final double pushX = (dx / actualDist) * overlap * 0.5;
            final double pushY = (dy / actualDist) * overlap * 0.5;

            // Move both in opposite directions
            itemA.position = Offset(
              (itemA.position.dx - pushX).clamp(margin, margin + usableWidth),
              (itemA.position.dy - pushY).clamp(margin, margin + usableHeight),
            );
            itemB.position = Offset(
              (itemB.position.dx + pushX).clamp(margin, margin + usableWidth),
              (itemB.position.dy + pushY).clamp(margin, margin + usableHeight),
            );
          }
        }
      }
      if (!changed) break; // Optimization: stop if no more collisions
    }

    _items = tempItems;
  }

  void _handleCircleTap(TmtItem item) {
    if (_isTestCompleted) {
      return;
    }

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

    // Show completion dialog
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          loc.wellDone,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          loc.testCompletedSuccess,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(loc.mainMenu, style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _triggerError() {
    HapticFeedback.mediumImpact();

    _errorCount++;

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

  void _submitResult() async {
    final int elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    final int seconds = (elapsedMilliseconds / 1000).truncate();
    final String durationStr = "$seconds s";

    try {
      debugPrint("SAVING RESULT: Identifier = ${widget.patientIdentifier}");
      await _firestoreService.saveTestResult(
        patientId: widget.patientId,
        patientIdentifier: widget.patientIdentifier,
        score: 0,
        totalDuration: durationStr,
        testType: 'TMT-B',
        errors: _errorCount,
      );
    } catch (e) {
      debugPrint("Error saving result: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _showError ? Colors.red[100] : Colors.white,
      appBar: AppBar(
        title: Text(
          loc.tmtBTitle,
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: Text(
                loc.finishTest,
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_items.isEmpty) {
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
                            loc.startLabel,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (isEnd)
                          Text(
                            loc.endLabel,
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
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      loc.tmtBInstructions,
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
      double yOffset1 = 0;
      if (connectedItems[i].number == 1 && connectedItems[i].isWhite) {
        yOffset1 = 18;
      }

      double yOffset2 = 0;
      if (connectedItems[i + 1].number == 1 && connectedItems[i + 1].isWhite) {
        yOffset2 = 18;
      }

      final startPos = connectedItems[i].position +
          Offset(circleSize / 2, circleSize / 2 + yOffset1);
      final endPos = connectedItems[i + 1].position +
          Offset(circleSize / 2, circleSize / 2 + yOffset2);

      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainterB oldDelegate) {
    return oldDelegate.connectedItems.length != connectedItems.length;
  }
}
