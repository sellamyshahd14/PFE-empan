import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../localization.dart';

class Dsm48Set2Page extends StatefulWidget {
  final String patientId;

  const Dsm48Set2Page({super.key, required this.patientId});

  @override
  State<Dsm48Set2Page> createState() => _Dsm48Set2PageState();
}

class _Dsm48Set2PageState extends State<Dsm48Set2Page> {
  final FirestoreService _firestoreService = FirestoreService();
  final Stopwatch _stopwatch = Stopwatch();

  int _currentIndex = 0;
  int _score = 0;
  final int _totalImages = 48;

  // Extracted from Correction DSM.pdf for Set 2
  final List<String> _correctAnswers = [
    'A',
    'B',
    'A',
    'B',
    'B',
    'A',
    'B',
    'A',
    'A',
    'B',
    'B',
    'A',
    'A',
    'B',
    'A',
    'B',
    'A',
    'B',
    'B',
    'A',
    'B',
    'B',
    'B',
    'A',
    'A',
    'A',
    'B',
    'A',
    'B',
    'B',
    'B',
    'A',
    'B',
    'A',
    'B',
    'A',
    'A',
    'B',
    'A',
    'A',
    'A',
    'B',
    'A',
    'B',
    'A',
    'B',
    'A',
    'B',
  ];

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _handleSelection(String selection) {
    if (selection == _correctAnswers[_currentIndex]) {
      _score++;
    }

    if (_currentIndex < _totalImages - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishTest();
    }
  }

  void _finishTest() async {
    _stopwatch.stop();
    final int elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    final int seconds = (elapsedMilliseconds / 1000).truncate();
    final String durationStr = "$seconds s";

    debugPrint(
      "DSM-48 Set 2 Completed in: $durationStr for patient ${widget.patientId} (Score: $_score)",
    );

    try {
      await _firestoreService.saveTestResult(
        patientId: widget.patientId,
        patientIdentifier: widget.patientId,
        score: _score.toDouble(),
        totalDuration: durationStr,
        testType: 'DSM-48 Set 2',
      );
    } catch (e) {
      debugPrint("Error saving result: $e");
    }

    if (!mounted) return;

    final loc = AppLocalizations.of(context);
    String scoreText = loc.dsm48Score.replaceAll('{}', '$_score');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            loc.bravo,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.testSuccess,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 16),
              Text(
                scoreText,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to DSM-48 menu
              },
              child: Text(loc.mainMenu, style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Images are named set2_pair1_A.png, set2_pair2_A.png, etc.
    final String imagePathA =
        'assets/images/dsm48/set2/set2_pair${_currentIndex + 1}_A.png';
    final String imagePathB =
        'assets/images/dsm48/set2/set2_pair${_currentIndex + 1}_B.png';
    final String counterText = loc.dsm48ImageCounter.replaceAll(
      '{}',
      '${_currentIndex + 1}',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          loc.dsm48MenuSet2,
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                loc.dsm48SetInstr,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 18, color: Colors.teal),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Text(
                counterText,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      // Image A
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _handleSelection('A'),
                          child: _buildImageCard(imagePathA, 'A'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Image B
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _handleSelection('B'),
                          child: _buildImageCard(imagePathB, 'B'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String assetPath, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InteractiveViewer(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image $label non trouvée',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
