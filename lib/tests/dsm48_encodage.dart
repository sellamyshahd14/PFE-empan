import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../localization.dart';

class Dsm48EncodagePage extends StatefulWidget {
  final String patientDocId;
  final String patientIdentifier;

  const Dsm48EncodagePage({
    super.key,
    required this.patientDocId,
    required this.patientIdentifier,
  });

  @override
  State<Dsm48EncodagePage> createState() => _Dsm48EncodagePageState();
}

class _Dsm48EncodagePageState extends State<Dsm48EncodagePage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController();
  final Stopwatch _stopwatch = Stopwatch();

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _spokenText = "";
  double _soundLevel = 0.0;
  List<String> _transcriptions = List.filled(48, "");

  int _currentIndex = 0;
  bool _isFinished = false; // NEW: Lock to prevent duplicate saves
  final int _totalImages = 48;

  Timer? _listenTimer;
  Timer? _guardianTimer;

  late AnimationController _micController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initSpeech();
    _initTts();

    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _micController, curve: Curves.easeInOut),
    );

    // Initial sequence trigger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakQuestionAndListen();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopwatch.stop();
    _listenTimer?.cancel();
    _guardianTimer?.cancel();
    _micController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  void _initSpeech() async {
    await Permission.microphone.request();
  }

  void _initTts() async {
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
      _startListening();
    });
  }

  Future<void> _speakQuestionAndListen() async {
    if (_isSpeaking) return;
    
    // Stop current mic if any
    if (_isListening) {
      _stopListening();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final loc = AppLocalizations.of(context);
    setState(() => _isSpeaking = true);
    
    await _flutterTts.setLanguage(loc.locale.languageCode == 'ar' ? 'ar' : 'fr-FR');
    await _flutterTts.speak(loc.dsm48EncodageQuestion);
  }

  void _startListening() async {
    if (_isListening) return;

    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint("STT Status: $status"),
      onError: (error) {
        debugPrint("STT Error: $error");
        bool isSilenceError = error.errorMsg == "error_no_match" || 
                             error.errorMsg == "error_speech_timeout";

        if (mounted && !isSilenceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur STT: ${error.errorMsg}')),
          );
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _spokenText = "";
      });

      _startSttSession();

      _listenTimer?.cancel();
      _listenTimer = Timer(const Duration(seconds: 60), () {
        _stopGuardian();
        if (_isListening) {
          _speech.stop();
          setState(() => _isListening = false);
        }
      });

      _guardianTimer?.cancel();
      _guardianTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!_isListening) {
          t.cancel();
          return;
        }
        if (!_speech.isListening) {
          debugPrint("Guardian: STT dropped, restarting...");
          _startSttSession();
        }
      });
    }
  }

  void _startSttSession() {
    final loc = AppLocalizations.of(context);
    _speech.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
          if (_spokenText.trim().isNotEmpty) {
            _transcriptions[_currentIndex] = _spokenText;
          }
        });
      },
      localeId: loc.locale.languageCode == 'ar' ? 'ar-SA' : null,
      onSoundLevelChange: (level) {
        setState(() => _soundLevel = level);
      },
      pauseFor: const Duration(seconds: 30),
      cancelOnError: false,
    );
  }

  void _stopListening() {
    _stopGuardian();
    _listenTimer?.cancel();
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _stopGuardian() {
    _guardianTimer?.cancel();
    _guardianTimer = null;
  }

  void _finishEncodage() async {
    if (_isFinished) return;
    setState(() => _isFinished = true);

    _stopListening();
    _stopwatch.stop();
    final int elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    final int seconds = (elapsedMilliseconds / 1000).truncate();
    final String durationStr = "$seconds s";

    debugPrint(
      "DSM-48 Encodage Completed in: $durationStr for patient ${widget.patientDocId}",
    );

    try {
      await _firestoreService.saveTestResult(
        patientDocId: widget.patientDocId,
        patientIdentifier: widget.patientIdentifier,
        score: null, 
        totalDuration: durationStr,
        testType: 'DSM-48 Encodage',
        metadata: {
          'transcriptions': _transcriptions,
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          size: 36,
                          color: Colors.teal,
                        ),
                        // MODIFIED: In reverse mode, back arrow goes NEXT
                        onPressed: _currentIndex < _totalImages - 1 ? _nextPage : null,
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          reverse: true, // MODIFIED: RTL French clinical booklet convention
                          physics: const BouncingScrollPhysics(), // MODIFIED: Always allow scrolling
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _speakQuestionAndListen();
                          },
                          itemCount: _totalImages,
                          itemBuilder: (context, index) {
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
                        // MODIFIED: In reverse mode, forward arrow goes PREVIOUS
                        onPressed: _currentIndex > 0 ? _previousPage : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Recording Section
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isListening)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.teal, size: 36),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_none, color: Colors.grey, size: 36),
                    ),
                  const SizedBox(height: 8),
                  if (_isListening)
                    Text(
                      loc.dsm48Listening,
                      style: GoogleFonts.cairo(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  if (_spokenText.isNotEmpty)
                    Text(
                      '"$_spokenText"',
                      style: GoogleFonts.cairo(
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                          fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    )
                  else if (!_isListening && _transcriptions[_currentIndex].isEmpty)
                    Text(
                      loc.dsm48VoiceError,
                      style: GoogleFonts.cairo(
                          color: Colors.red.shade700,
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
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
                      onPressed: _isFinished ? null : _finishEncodage,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        loc.dsm48FinishEncodage,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
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
                    const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
