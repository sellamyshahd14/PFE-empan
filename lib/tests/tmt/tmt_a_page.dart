import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TmtAPage extends StatefulWidget {
  final String patientId;

  const TmtAPage({super.key, required this.patientId});

  @override
  State<TmtAPage> createState() => _TmtAPageState();
}

class _TmtAPageState extends State<TmtAPage> {
  final int _totalCircles = 25;
  List<Offset> _circlePositions = [];
  List<int> _connectedNumbers = [];
  int _nextExpectedNumber = 1;
  Stopwatch _stopwatch = Stopwatch();
  bool _isTestRunning = false;
  bool _isTestCompleted = false;

  // Feedback state
  bool _showError = false;

  // Canvas size for randomization
  final double _circleSize = 50.0;

  @override
  void initState() {
    super.initState();
    // Delay initialization of positions until we have layout info,
    // but for simplicity we'll generate them in build or post-frame.
    // However, generating in build is bad for randomness stability.
    // We'll trust LayoutBuilder in build to generate them ONCE properly.
  }

  void _generatePositions(Size size) {
    if (_circlePositions.isNotEmpty) return;

    final random = Random();
    final double width = size.width;
    final double height = size.height;
    final double margin = 40.0; // Margin from edges

    List<Offset> positions = [];

    // Attempt to generate random positions
    // This is a naive approach; for production, a proper packing algorithm is better,
    // but for 25 items on a screen it usually works ok with enough retry attempts.

    // Grid approach to ensure distribution?
    // Let's try pure random with distance check first.

    int attempts = 0;
    while (positions.length < _totalCircles && attempts < 1000) {
      double x =
          margin + random.nextDouble() * (width - 2 * margin - _circleSize);
      double y =
          margin + random.nextDouble() * (height - 2 * margin - _circleSize);

      Offset newPos = Offset(x, y);

      bool tooClose = false;
      for (Offset pos in positions) {
        if ((pos - newPos).distance < _circleSize * 1.5) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        positions.add(newPos);
      }
      attempts++;
    }

    // Fallback if we couldn't place all (rare on modern phones for 25 dots)
    // Just place remaining randomly without check if stuck
    while (positions.length < _totalCircles) {
      double x = margin + random.nextDouble() * (width - 2 * margin);
      double y = margin + random.nextDouble() * (height - 2 * margin);
      positions.add(Offset(x, y));
    }

    // Assign directly without setState as this is called during build/layout
    _circlePositions = positions;
  }

  void _handleCircleTap(int number) {
    if (_isTestCompleted) return;

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
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to menu
            },
            child: Text("القائمة الرئيسية", style: GoogleFonts.cairo()),
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

  void _submitResult() {
    final int elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    debugPrint(
      "TMT-A Completed in: $elapsedMilliseconds ms for patient ${widget.patientId}",
    );
    // TODO: Send to Firestore collection 'tests_results' with field 'temps_tmt_a'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _showError ? Colors.red[100] : Colors.white,
      appBar: AppBar(
        title: Text(
          "اختبار TMT-A",
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
                    child: Container(
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.white : Colors.teal,
                        ),
                      ),
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
                      "اضغط على الأرقام بالترتيب من 1 إلى 25.\nاضغط على 1 للبدء.",
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
      // connectedNumbers stores the actual numbers (1-based index)
      // positions is 0-based index list where index 0 is number 1
      final startPos =
          positions[connectedNumbers[i] - 1] +
          const Offset(25, 25); // + radius to center
      final endPos =
          positions[connectedNumbers[i + 1] - 1] + const Offset(25, 25);

      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) {
    return oldDelegate.connectedNumbers.length != connectedNumbers.length;
  }
}
