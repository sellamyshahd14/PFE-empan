import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../localization.dart';

class Dsm48SetPage extends StatefulWidget {
  final String patientDocId;
  final String patientIdentifier;
  final int setIndex; // 1, 2, or 3
  final List<String> correctAnswers;
  final List<String> itemTypes;
  final String setLabel; // e.g. "Set 1"

  const Dsm48SetPage({
    super.key,
    required this.patientDocId,
    required this.patientIdentifier,
    required this.setIndex,
    required this.correctAnswers,
    required this.itemTypes,
    required this.setLabel,
  });

  @override
  State<Dsm48SetPage> createState() => _Dsm48SetPageState();
}

class _Dsm48SetPageState extends State<Dsm48SetPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Stopwatch _stopwatch = Stopwatch();

  int _currentIndex = 0;
  int _score = 0;
  final int _totalImages = 48;
  bool _isFinished = false;
  late final List<bool?> _itemResults;
  late final List<String?> _patientChoices;

  @override
  void initState() {
    super.initState();
    _itemResults = List.filled(_totalImages, null);
    _patientChoices = List.filled(_totalImages, null);
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache first pair
    _precachePair(0);
    // Precache next pair (ahead of time)
    _precachePair(1);
  }

  void _precachePair(int index) {
    if (index >= _totalImages) return;
    
    final String pathA = 'assets/images/dsm48/set${widget.setIndex}/set${widget.setIndex}_pair${index + 1}_A.png';
    final String pathB = 'assets/images/dsm48/set${widget.setIndex}/set${widget.setIndex}_pair${index + 1}_B.png';
    
    precacheImage(AssetImage(pathA), context);
    precacheImage(AssetImage(pathB), context);
  }

  void _handleSelection(String selection) {
    bool isCorrect = selection == widget.correctAnswers[_currentIndex];
    _itemResults[_currentIndex] = isCorrect;
    _patientChoices[_currentIndex] = selection;
    if (isCorrect) {
      _score++;
    }

    if (_currentIndex < _totalImages - 1) {
      setState(() {
        _currentIndex++;
      });
      // Precache the one after next
      _precachePair(_currentIndex + 1);
    } else {
      _finishTest();
    }
  }

  void _finishTest() async {
    if (_isFinished) return;
    setState(() => _isFinished = true);

    _stopwatch.stop();
    final int elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    final int seconds = (elapsedMilliseconds / 1000).truncate();
    final String durationStr = "$seconds s";

    // Build detailed results for the dashboard
    final List<Map<String, dynamic>> tableFormat = List.generate(_totalImages, (index) {
      return {
        'numero': index + 1,
        'categorie': widget.itemTypes[index],
        'attendu': widget.correctAnswers[index],
        'patient': _patientChoices[index] ?? '-',
        'isCorrect': _itemResults[index] ?? false,
      };
    });

    try {
      await _firestoreService.saveTestResult(
        patientDocId: widget.patientDocId,
        patientIdentifier: widget.patientIdentifier,
        score: _score.toDouble(),
        totalDuration: durationStr,
        testType: 'DSM-48 ${widget.setLabel}',
        metadata: {
          'tableFormat': tableFormat,
        },
      );
    } catch (e) {
      debugPrint("Error saving result: $e");
    }

    if (!mounted) return;

    final loc = AppLocalizations.of(context);
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
          content: Text(
            loc.testSuccess,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(),
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

    // Images are named setX_pairY_A.png, etc.
    final String imagePathA =
        'assets/images/dsm48/set${widget.setIndex}/set${widget.setIndex}_pair${_currentIndex + 1}_A.png';
    final String imagePathB =
        'assets/images/dsm48/set${widget.setIndex}/set${widget.setIndex}_pair${_currentIndex + 1}_B.png';
    final String counterText = loc.dsm48ImageCounter.replaceAll(
      '{}',
      '${_currentIndex + 1}',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.setLabel,
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
    final loc = AppLocalizations.of(context);
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
                        loc.imageNotFoundError.replaceAll('{}', label),
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
