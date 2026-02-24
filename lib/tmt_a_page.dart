import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'services/firestore_service.dart';

class TmtAPage extends StatefulWidget {
  final String patientId;
  final String patientIdentifier;

  const TmtAPage({
    super.key,
    required this.patientId,
    required this.patientIdentifier,
  });

  @override
  State<TmtAPage> createState() => _TmtAPageState();
}

class _TmtAPageState extends State<TmtAPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final int _totalCircles = 25;
  List<Offset> _circlePositions = [];
  final List<int> _connectedNumbers = [];
  int _nextExpectedNumber = 1;
  final Stopwatch _stopwatch = Stopwatch();
  bool _isTestRunning = false;
  bool _isTestCompleted = false;

  // Feedback state
  bool _showError = false;
  int _errorCount = 0;

  final double _circleSize = 40.0;

  // Standard TMT-A positions (normalized 0..1 coordinates for each number 1-25)
  // Mapped from the official TMT-A reference layout
  static const List<List<double>> _normalizedPositions = [
    [0.55, 0.55], // 1  (début) — shifted left, away from 3→4 line
    [0.44, 0.62], // 2  — shifted right+up, room for 10
    [0.63, 0.72], // 3
    [0.65, 0.31], // 4
    [0.28, 0.35], // 5
    [0.45, 0.45], // 6
    [0.27, 0.55], // 7
    [0.18, 0.74], // 8  — shifted right, away from 12→13 line
    [0.20, 0.82], // 9  — adjusted to keep distance from 8 and 12
    [0.32, 0.68], // 10 — shifted right, room for 8
    [0.44, 0.87], // 11
    [0.05, 0.87], // 12
    [0.12, 0.44], // 13
    [0.00, 0.60], // 14 — shifted left, away from 12→13 line
    [0.05, 0.05], // 15
    [0.14, 0.22], // 16
    [0.38, 0.05], // 17
    [0.30, 0.25], // 18
    [0.65, 0.18], // 19 — shifted down, away from 20→21 line
    [0.45, 0.12], // 20
    [0.85, 0.05], // 21
    [0.82, 0.31], // 22
    [0.88, 0.87], // 23
    [0.72, 0.50], // 24 — shifted left, away from 22→23 line
    [0.72, 0.85], // 25 (fin)
  ];

  @override
  void initState() {
    super.initState();
  }

  void _generatePositions(Size size) {
    if (_circlePositions.isNotEmpty) {
      return;
    }

    final double margin = 20.0;
    final double usableWidth = size.width - 2 * margin - _circleSize;
    final double usableHeight = size.height - 2 * margin - _circleSize;

    _circlePositions = _normalizedPositions.map((coords) {
      return Offset(
        margin + coords[0] * usableWidth,
        margin + coords[1] * usableHeight,
      );
    }).toList();
  }

  void _handleCircleTap(int number) {
    if (_isTestCompleted) {
      return;
    }

    if (!_isTestRunning) {
      _startTest();
    }

    if (number == _nextExpectedNumber) {
      // Correct
      setState(() {
        _connectedNumbers.add(number);
        _nextExpectedNumber++;
        _showError = false;
      });

      if (number == _totalCircles) {
        _finishTest();
      }
    } else {
      // Incorrect
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
    // Send result to Firestore (Simulation as requested)
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
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to menu
            },
            child: Text(loc.mainMenu, style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _triggerError() {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    _errorCount++;

    // Visual feedback (Flash red)
    setState(() {
      _showError = true;
    });

    // Reset error state after short delay
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
      "TMT-A Completed in: $durationStr for patient ${widget.patientId}",
    );

    try {
      await _firestoreService.saveTestResult(
        patientId: widget.patientId,
        patientIdentifier: widget.patientIdentifier,
        score: 0,
        totalDuration: durationStr,
        testType: 'TMT-A',
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
          loc.tmtATitle,
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
          if (_circlePositions.isEmpty) {
            _generatePositions(constraints.biggest);
          }

          return Stack(
            children: [
              // Lines Layer
              CustomPaint(
                size: Size.infinite,
                painter: LinePainter(
                  positions: _circlePositions,
                  connectedNumbers: _connectedNumbers,
                ),
              ),

              // Circles Layer
              ...List.generate(_circlePositions.length, (index) {
                final int number = index + 1;
                final bool isConnected = number < _nextExpectedNumber;
                return Positioned(
                  left: _circlePositions[index].dx,
                  top: _circlePositions[index].dy,
                  child: GestureDetector(
                    onTap: () => _handleCircleTap(number),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (number == 1)
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
                            color: isConnected ? Colors.teal : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.teal, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "$number",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isConnected ? Colors.white : Colors.teal,
                            ),
                          ),
                        ),
                        if (number == _totalCircles)
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

              // Instructions Overlay (if not started)
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
                      loc.tmtAInstructions,
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

class LinePainter extends CustomPainter {
  final List<Offset> positions;
  final List<int> connectedNumbers;

  LinePainter({required this.positions, required this.connectedNumbers});

  @override
  void paint(Canvas canvas, Size size) {
    if (connectedNumbers.length < 2) return;

    final paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < connectedNumbers.length - 1; i++) {
      final int startNum = connectedNumbers[i];
      final int endNum = connectedNumbers[i + 1];

      // Adjust for labels: Number 1 has "Start" above (~18px), others might have nothing or "End" below
      double yOffsetStart = (startNum == 1) ? 18.0 : 0.0;
      double yOffsetEnd = (endNum == 1) ? 18.0 : 0.0;

      // Constants for centering (radius = 20 since diameter is 40)
      const double radius = 20.0;

      final startPos =
          positions[startNum - 1] + Offset(radius, radius + yOffsetStart);
      final endPos =
          positions[endNum - 1] + Offset(radius, radius + yOffsetEnd);

      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) {
    return oldDelegate.connectedNumbers.length != connectedNumbers.length;
  }
}
