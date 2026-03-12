import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/firestore_service.dart';
import '../localization.dart';

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
  final FirestoreService _firestoreService = FirestoreService();
  final int _maxNumber = 25;
  List<TmtItem> _items = [];
  final List<TmtItem> _connectedItems = [];

  // Logic tracking
  int _nextNumber = 1;

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
    [1, 1, 0.68, 0.53], // 1 (début)
    [2, 1, 0.50, 0.62], // 2W
    [3, 1, 0.73, 0.67], // 3W
    [4, 1, 0.82, 0.45], // 4W
    [
      5,
      1,
      0.45,
      0.38,
    ], // 5W - Move right slightly (away from 13W/14W) - Push up to clear 4B
    [6, 1, 0.35, 0.48], // 6W
    [7, 1, 0.40, 0.55], // 7W - Move up slightly to clear 8B
    [8, 1, 0.18, 0.74], // 8W
    [9, 1, 0.28, 0.75], // 9W - Push up to clear 8B
    [10, 1, 0.43, 0.77], // 10W - Push right to clear 8B->9W trace
    [11, 1, 0.55, 0.78], // 11W
    [12, 1, 0.22, 0.84], // 12W - Push up to clear 11B
    [13, 1, 0.25, 0.46], // 13W
    [14, 1, 0.22, 0.37], // 14W
    [15, 1, 0.15, 0.17], // 15W
    [16, 1, 0.38, 0.17], // 16W
    [17, 1, 0.50, 0.15], // 17W
    [18, 1, 0.40, 0.29], // 18W
    [19, 1, 0.73, 0.22], // 19W
    [20, 1, 0.60, 0.29], // 20W
    [21, 1, 0.82, 0.16], // 21W
    [22, 1, 0.78, 0.34], // 22W
    [23, 1, 0.85, 0.85], // 23W
    [24, 1, 0.68, 0.62], // 24W - Push right slightly to clear 2B->3W
    [25, 1, 0.75, 0.80], // 25W
    // Black/Blue Circles (1-25) - Mapped from Image
    [2, 0, 0.55, 0.65], // 2-B
    [3, 0, 0.85, 0.65], // 3-B
    [4, 0, 0.75, 0.38], // 4-B
    [5, 0, 0.33, 0.37], // 5-B - Push left more
    [6, 0, 0.55, 0.46], // 6-B
    [7, 0, 0.30, 0.56], // 7-B - Push lower left
    [8, 0, 0.23, 0.66], // 8-B - Push left away from 7W and down
    [9, 0, 0.30, 0.85], // 9-B
    [10, 0, 0.37, 0.66], // 10-B - Keep clear of 8B
    [11, 0, 0.60, 0.70], // 11-B
    [12, 0, 0.12, 0.81], // 12-B - More left and down
    [13, 0, 0.28, 0.51], // 13-B
    [14, 0, 0.12, 0.57], // 14-B - Push further left and down
    [15, 0, 0.25, 0.13], // 15-B
    [16, 0, 0.28, 0.29], // 16-B
    [17, 0, 0.63, 0.12], // 17-B
    [18, 0, 0.51, 0.34], // 18-B
    [19, 0, 0.72, 0.29], // 19-B
    [20, 0, 0.63, 0.22], // 20-B
    [21, 0, 0.75, 0.11], // 21-B
    [22, 0, 0.85, 0.37], // 22-B
    [23, 0, 0.70, 0.85], // 23-B
    [24, 0, 0.79, 0.52], // 24-B
    [25, 0, 0.64, 0.85], // 25-B
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

    // 0. Find min and max to scale to the full screen dynamically
    double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (final pos in _normalizedPositions) {
      if (pos[2] < minX) minX = pos[2];
      if (pos[2] > maxX) maxX = pos[2];
      if (pos[3] < minY) minY = pos[3];
      if (pos[3] > maxY) maxY = pos[3];
    }
    double rangeX = maxX - minX;
    double rangeY = maxY - minY;

    // 1. Initialize with target positions from reference image, scaled to screen
    for (final pos in _normalizedPositions) {
      final int number = pos[0].toInt();
      final bool isWhite = pos[1] == 1.0;

      final double normalizedX = (pos[2] - minX) / rangeX;
      final double normalizedY = (pos[3] - minY) / rangeY;

      final double x = margin + normalizedX * usableWidth;
      final double y = margin + normalizedY * usableHeight;

      tempItems.add(
        TmtItem(number: number, isWhite: isWhite, position: Offset(x, y)),
      );
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
    if (_isTestCompleted) return;

    if (!_isTestRunning) {
      _startTest();
    }

    // Check correctness
    bool isCorrect = false;

    // The sequence follows: 1W -> 2B -> 3W -> 4B ... -> 25W
    bool expectedIsWhite = (_nextNumber % 2 != 0);

    if (item.number == _nextNumber && item.isWhite == expectedIsWhite) {
      isCorrect = true;
    }

    if (isCorrect) {
      setState(() {
        _connectedItems.add(item);
        _nextNumber++;
        _showError = false;
      });

      // Completion check: Connected 25-White
      if (item.number == _maxNumber && item.isWhite) {
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
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(
            loc.bravo,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Text(
            loc.testSuccess,
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
        );
      },
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

    debugPrint(
      "TMT-B Completed in: $durationStr for patient ${widget.patientId}",
    );

    try {
      await _firestoreService.saveTestResult(
        patientId: widget.patientId,
        patientIdentifier: widget.patientId, // Defaulting to docId
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
                loc.finishTest, // Finish test mapped to localized Arabic
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
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
                  bool isEnd =
                      (item.number == 25 &&
                      item.isWhite); // Changed back to White

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
                              loc.startNode,
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
                              loc.endNode,
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
                        loc.tmtBInstr,
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
