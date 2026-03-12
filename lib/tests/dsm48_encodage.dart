import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../localization.dart';

class Dsm48EncodagePage extends StatefulWidget {
  final String patientId;

  const Dsm48EncodagePage({super.key, required this.patientId});

  @override
  State<Dsm48EncodagePage> createState() => _Dsm48EncodagePageState();
}

class _Dsm48EncodagePageState extends State<Dsm48EncodagePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController();
  final Stopwatch _stopwatch = Stopwatch();

  int _currentIndex = 0;
  final int _totalImages = 48;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _finishEncodage() async {
    _stopwatch.stop();
    final int elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    final int seconds = (elapsedMilliseconds / 1000).truncate();
    final String durationStr = "$seconds s";

    debugPrint(
      "DSM-48 Encodage Completed in: $durationStr for patient ${widget.patientId}",
    );

    try {
      await _firestoreService.saveTestResult(
        patientId: widget.patientId,
        patientIdentifier: widget.patientId,
        score: null, // No score for encodage phase
        totalDuration: durationStr,
        testType: 'DSM-48 Encodage',
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

  void _nextPage() {
    if (_currentIndex < _totalImages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Format string nicely
    String counterText = loc.dsm48ImageCounter.replaceAll(
      '{}',
      '${_currentIndex + 1}',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          loc.dsm48MenuEncodage,
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
                loc.dsm48EncodageInstr,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 18, color: Colors.teal),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 36,
                      color: Colors.teal,
                    ),
                    onPressed: _currentIndex > 0 ? _previousPage : null,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: _totalImages,
                      itemBuilder: (context, index) {
                        // Images are named Picture1.png to Picture48.png
                        final imagePath =
                            'assets/images/dsm48/encodage/Picture${index + 1}.png';
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.teal.shade200,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Picture${index + 1}.png\nNon trouvée',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 36,
                      color: Colors.teal,
                    ),
                    onPressed: _currentIndex < _totalImages - 1
                        ? _nextPage
                        : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    counterText,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentIndex == _totalImages - 1)
                    ElevatedButton.icon(
                      onPressed: _finishEncodage,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        loc.dsm48FinishEncodage,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // Spacer to maintain alignment
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
