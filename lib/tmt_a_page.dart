import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'services/firestore_service.dart';

class TmtAPage extends StatefulWidget {
  final String patientId;

  const TmtAPage({super.key, required this.patientId});

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

  // Canvas size for randomization
  // Reduced to 40.0 to match TMT-B and prevent overlap
  final double _circleSize = 40.0;

  @override
  void initState() {
    super.initState();
    // Delay initialization of positions until we have layout info,
    // but for simplicity we'll generate them in build or post-frame.
    // However, generating in build is bad for randomness stability.
    // We'll trust LayoutBuilder in build to generate them ONCE properly.
  }

  void _generatePositions(Size size) {
    if (_circlePositions.isNotEmpty) {
      return;
    }

    final random = Random();
    final double width = size.width;
    final double height = size.height;
    final double margin = 30.0; // Reduced margin to give more space

    List<Offset> positions = [];
    int globalAttempts = 0;

    // Retry the entire generation if we get stuck (up to 10 times)
    while (positions.length < _totalCircles && globalAttempts < 10) {
      positions.clear();
      int placedCount = 0;
      int itemAttempts = 0;

      while (placedCount < _totalCircles && itemAttempts < 5000) {
        double x =
            margin + random.nextDouble() * (width - 2 * margin - _circleSize);
        double y =
            margin + random.nextDouble() * (height - 2 * margin - _circleSize);

        Offset newPos = Offset(x, y);

        bool tooClose = false;
        for (Offset pos in positions) {
          // Use slightly larger distance buffer (1.3x) for better spacing
          if ((pos - newPos).distance < _circleSize * 1.3) {
            tooClose = true;
            break;
          }
        }

        if (!tooClose) {
          positions.add(newPos);
          placedCount++;
        }
        itemAttempts++;
      }
      globalAttempts++;
    }

    // If we still failed (extremely unlikely on modern screens), fallback to grid or uncheck
    if (positions.length < _totalCircles) {
      // Emergency fallback: just fill remaining randomly (overlap possible but rare)
      while (positions.length < _totalCircles) {
        double x = margin + random.nextDouble() * (width - 2 * margin);
        double y = margin + random.nextDouble() * (height - 2 * margin);
        positions.add(Offset(x, y));
      }
    }

    _circlePositions = positions;
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
        patientIdentifier:
            "Unknown", // Passed ID is DocID, display ID unknown here
        score: 0,
        totalDuration: durationStr,
        testType: 'TMT-A',
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
                if (_isTestRunning) {
                  _finishTest();
                } else {
                  Navigator.pop(context);
                }
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
