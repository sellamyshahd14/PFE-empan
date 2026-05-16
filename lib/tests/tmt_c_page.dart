import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../localization.dart';

class TmtCPage extends StatefulWidget {
  final String patientDocId;
  final String patientIdentifier;

  const TmtCPage({
    super.key,
    required this.patientDocId,
    required this.patientIdentifier,
  });

  @override
  State<TmtCPage> createState() => _TmtCPageState();
}

class TmtCItem {
  final String label;
  final int sequenceOrder; // 0 to 15
  Offset position;

  TmtCItem({
    required this.label,
    required this.sequenceOrder,
    this.position = Offset.zero,
  });
}

class _TmtCPageState extends State<TmtCPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final int _totalItems = 16;
  List<TmtCItem> _items = [];
  final List<TmtCItem> _connectedItems = [];

  int _nextStepIndex = 0; // 0 to 15
  final Stopwatch _stopwatch = Stopwatch();
  bool _isTestRunning = false;
  bool _isTestCompleted = false;
  int _errorCount = 0;

  final double _circleSize = 45.0;

  // Normalized positions for 16 circles (1-A-2-B...8-H)
  // Balanced across the screen to avoid condensed areas
  static const List<List<double>> _normalizedSettings = [
    [0.10, 0.10], // 0: "1" (Start - Top Left)
    [0.45, 0.15], // 1: "A" (Top Mid)
    [0.85, 0.08], // 2: "2" (Top Right)
    [0.90, 0.45], // 3: "B" (Center Right)
    [0.75, 0.65], // 4: "3" (Low Right)
    [0.90, 0.90], // 5: "C" (Bottom Right)
    [0.55, 0.85], // 6: "4" (Bottom Mid)
    [0.20, 0.90], // 7: "D" (Bottom Left)
    [0.05, 0.60], // 8: "5" (Center Left)
    [0.30, 0.40], // 9: "E" (Mid Left)
    [0.70, 0.40], // 10: "6" (Mid Right)
    [0.60, 0.20], // 11: "F" (Upper Mid)
    [0.25, 0.25], // 12: "7" (Upper Left)
    [0.35, 0.65], // 13: "G" (Lower Mid Left)
    [0.50, 0.50], // 14: "8" (Center)
    [0.08, 0.80], // 15: "H" (Finish - Bottom Left-ish)
  ];

  final List<String> _labels = [
    "1",
    "A",
    "2",
    "B",
    "3",
    "C",
    "4",
    "D",
    "5",
    "E",
    "6",
    "F",
    "7",
    "G",
    "8",
    "H",
  ];

  @override
  void initState() {
    super.initState();
  }

  void _generateItems(Size size) {
    if (_items.isNotEmpty) return;

    final double margin = 40.0;
    final double usableWidth = size.width - 2 * margin - _circleSize;
    final double usableHeight = size.height - 2 * margin - _circleSize;

    for (int i = 0; i < _totalItems; i++) {
      _items.add(
        TmtCItem(
          label: _labels[i],
          sequenceOrder: i,
          position: Offset(
            margin + _normalizedSettings[i][0] * usableWidth,
            margin + _normalizedSettings[i][1] * usableHeight,
          ),
        ),
      );
    }
  }

  void _onCircleTap(TmtCItem item) {
    if (_isTestCompleted) return;

    if (!_isTestRunning) {
      setState(() {
        _isTestRunning = true;
        _stopwatch.start();
      });
    }

    // Ignore if tapping the same circle that is already the end of the trail
    if (_connectedItems.isNotEmpty && _connectedItems.last == item) return;

    // Track error if not sequential (Free movement logic)
    if (item.sequenceOrder != _nextStepIndex) {
      _errorCount++;
    }

    setState(() {
      _connectedItems.add(item);
      _nextStepIndex = item.sequenceOrder + 1;
    });

    // Finish test if "H" (Index 15) is reached
    if (item.sequenceOrder == 15) {
      _finishTest();
    }
  }

  void _finishTest() {
    _stopwatch.stop();
    setState(() => _isTestCompleted = true);
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
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to menu
              },
              child: Text(loc.mainMenu, style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );
  }

  void _submitResult() async {
    final int seconds = (_stopwatch.elapsedMilliseconds / 1000).truncate();
    final String durationStr = "$seconds s";

    final int connectionsCount = _connectedItems.length > 0
        ? _connectedItems.length - 1
        : 0;
    try {
      await _firestoreService.saveTestResult(
        patientDocId: widget.patientDocId,
        patientIdentifier: widget.patientIdentifier,
        score: (connectionsCount - _errorCount).toDouble(),
        totalDuration: durationStr,
        errors: _errorCount,
        testType: 'TMT-C',
        metadata: {
          'mistakes': _errorCount,
          'path': _connectedItems.map((item) => item.label).toList(),
          'totalActions': _connectedItems.length,
        },
      );
    } catch (e) {
      debugPrint("Error saving TMT-C: $e");
    }
  }

  Future<void> _requestExit() async {
    if (_isTestCompleted) {
      Navigator.of(context).pop();
      return;
    }

    final loc = AppLocalizations.of(context);
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          loc.exitWithoutSaving,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(loc.exitConfirmBody, style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel, style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              loc.exitWithoutSaving,
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return PopScope(
      canPop: _isTestCompleted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _requestExit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leadingWidth: 100,
          leading: Directionality(
            textDirection: TextDirection.ltr,
            child: TextButton(
              onPressed: _finishTest,
              child: Text(
                loc.finishTest,
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            loc.tmtCTitle,
            style: GoogleFonts.cairo(color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _requestExit,
                tooltip: loc.exitWithoutSaving,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _generateItems(constraints.biggest);

              return Stack(
                children: [
                  // Lines Layer
                  CustomPaint(
                    size: Size.infinite,
                    painter: LinePainterC(
                      connectedItems: _connectedItems,
                      circleSize: _circleSize,
                    ),
                  ),

                  // Circles Layer
                  ..._items.map((item) {
                    bool isStart = item.sequenceOrder == 0;
                    bool isEnd = item.sequenceOrder == 15;

                    return Positioned(
                      left: item.position.dx,
                      top: item.position.dy,
                      child: GestureDetector(
                        onTap: () => _onCircleTap(item),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: _circleSize,
                              height: _circleSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.label,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            if (isStart)
                              Text(
                                loc.startNode,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
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
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          loc.tmtCInstr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.teal[900],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class LinePainterC extends CustomPainter {
  final List<TmtCItem> connectedItems;
  final double circleSize;

  LinePainterC({required this.connectedItems, required this.circleSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (connectedItems.length < 2) return;
    final paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < connectedItems.length - 1; i++) {
      final startPos =
          connectedItems[i].position + Offset(circleSize / 2, circleSize / 2);
      final endPos =
          connectedItems[i + 1].position +
          Offset(circleSize / 2, circleSize / 2);
      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainterC oldDelegate) => true;
}
