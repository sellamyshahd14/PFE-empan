import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'services/firestore_service.dart';

import 'dart:async';

class StartEmpanPage extends StatefulWidget {
  final String patientId;
  const StartEmpanPage({super.key, required this.patientId});

  @override
  State<StartEmpanPage> createState() => _StartEmpanPageState();
}

class _StartEmpanPageState extends State<StartEmpanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).welcome,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(height: 40),
            // Name field removed, using ID from previous screen
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmpanDirect(patientName: widget.patientId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).startTest,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmpanDirect extends StatefulWidget {
  final String patientName;
  const EmpanDirect({super.key, required this.patientName});

  @override
  State<EmpanDirect> createState() => _EmpanDirectState();
}

class _EmpanDirectState extends State<EmpanDirect>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late final AudioRecorder _audioRecorder;
  // ignore: unused_field
  String? _audioPath;
  bool _isListening = false;
  bool _isPlaying = false;
  String _spokenText = "";
  // ignore: unused_field
  double _score = 0.0;
  int _currentIndex = 0;
  bool _isTestStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  // ignore: unused_field
  String _formattedTime = "00:00";
  bool _showFeedback = false;
  String? _lastIncorrectInput;

  // Animation controller for the mic "breathing" effect
  late AnimationController _micAnimController;
  late Animation<double> _micAnimation;

  final List<String> _sequences = [
    "5 8 2",
    "4 9 6",
    "6 4 3 9",
    "7 2 8 6",
    "4 2 7 3 1",
    "7 5 8 3 6",
    "6 1 9 4 7 3",
    "3 9 2 4 8 7",
    "5 9 1 7 4 2 8",
    "4 1 7 9 3 8 6",
    "5 8 1 9 2 6 4 7",
    "3 8 2 9 5 1 7 4",
    "2 7 5 8 6 2 3 6 5",
    "7 1 3 9 4 2 5 6 8",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _audioRecorder = AudioRecorder();
    _initSpeech();
    _initTts();

    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _micAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startTest() async {
    // Start global recording
    /*
    try {
      if (await Permission.microphone.request().isGranted) {
        final dir = await getTemporaryDirectory();
        String fileName =
            'empan_test_${widget.patientName}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        String path = '${dir.path}/$fileName';

        // Ensure no previous recording is running
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }

        await _audioRecorder.start(const RecordConfig(), path: path);
        debugPrint("Recording started to: $path");
      } else {
        debugPrint("ERROR: Microphone permission NOT granted");
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
    */

    setState(() {
      _isTestStarted = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _formattedTime = _formatTime(_stopwatch.elapsed);
        });
      });
    });
    _speakSequence();
  }

  Future<void> _stopTest() async {
    _stopwatch.stop();
    _timer?.cancel();

    // Stop global recording
    /*
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _audioPath = path;
        });
        debugPrint("Recording saved to: $path");
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
    */
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _initSpeech() async {
    await Permission.microphone.request();
  }

  void _initTts() async {
    try {
      await _flutterTts.setLanguage("ar");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }

    _flutterTts.setCompletionHandler(() {
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _speakSequence() async {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _showFeedback = false; // Hide previous feedback
      _spokenText = "";
    });

    String sequence = _sequences[_currentIndex];
    List<String> numbers = sequence.split(' ');

    for (String number in numbers) {
      String arabicWord = _getArabicWord(number);
      await _flutterTts.speak(arabicWord);
      // Simple fixed delay, no complex awaiting completion
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    setState(() => _isPlaying = false);
  }

  String _getArabicWord(String digit) {
    switch (digit) {
      case '0':
        return 'صفر';
      case '1':
        return 'واحد';
      case '2':
        return 'اثنان';
      case '3':
        return 'ثلاثة';
      case '4':
        return 'أربعة';
      case '5':
        return 'خمسة';
      case '6':
        return 'ستة';
      case '7':
        return 'سبعة';
      case '8':
        return 'ثمانية';
      case '9':
        return 'تسعة';
      default:
        return digit;
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'ar-TN',
          onResult: (val) {
            setState(() {
              _spokenText = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  bool _isValidated = false;

  void _validate() {
    String targetDigits = _sequences[_currentIndex].replaceAll(' ', '');
    String cleanSpoken = _spokenText.replaceAll(RegExp(r'[^0-9]'), '');

    bool isCorrect = false;
    if (cleanSpoken.contains(targetDigits)) {
      isCorrect = true;
    }

    if (isCorrect) {
      setState(() {
        _score += 0.5;
        _showFeedback = false;
        _isValidated = true; // Mark as validated
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).correctFeedback),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _showFeedback = true;
        _lastIncorrectInput = _spokenText;
        _isValidated = true; // Even if wrong, it's validated
      });
    }
  }

  void _next() {
    if (!_isValidated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).validateFirstMsg),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentIndex < _sequences.length - 1) {
      setState(() {
        _currentIndex++;
        _spokenText = "";
        _isListening = false;
        _showFeedback = false;
        _lastIncorrectInput = null;
        _isValidated = false; // Reset for next sequence
      });
      _speech.stop();
    } else {
      _showFinalScore();
    }
  }

  final FirestoreService _firestoreService = FirestoreService();

  void _showFinalScore() async {
    _stopTest(); // Stop timer

    // Save to Firestore
    try {
      await _firestoreService.saveTestResult(
        patientId: widget.patientName, // This is the 'docId' passed from login
        patientIdentifier:
            "Unknown", // We could pass this if we had it, or look it up. Using placeholder for now to keep it simple.
        score: _score,
        totalDuration: _formattedTime,
      );
      debugPrint("Result Saved!");
    } catch (e) {
      debugPrint("Error Saving Result: $e");
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).testFinishedTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).testFinishedMsg,
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 10),
            Text(
              "Score: $_score",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.teal,
              ),
            ),
            Text(
              "Time: $_formattedTime",
              style: GoogleFonts.cairo(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Return to Login Page (Root)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              AppLocalizations.of(context).mainMenu,
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _flutterTts.stop();
    _timer?.cancel();
    _micAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-start removed as requested

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey for serenity
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).testTitle,
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${AppLocalizations.of(context).sequenceLabel} ${_currentIndex + 1}/${_sequences.length}",
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _sequences.length,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 2. Central Text
            Text(
              AppLocalizations.of(context).repeatSequence,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Play Button
            ElevatedButton.icon(
              onPressed: _isPlaying
                  ? null
                  : () {
                      if (!_isTestStarted) {
                        _startTest(); // Start timer on first play
                      }
                      _speakSequence();
                    },
              icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
              label: Text(
                _isPlaying
                    ? AppLocalizations.of(context).playBtn
                    : AppLocalizations.of(context).listenBtn,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 3. Mic Button with Animation
            GestureDetector(
              onTap: _listen,
              child: AnimatedBuilder(
                animation: _micAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80 * (_isListening ? _micAnimation.value : 1.0),
                    height: 80 * (_isListening ? _micAnimation.value : 1.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.withValues(
                        alpha: _isListening ? 0.2 : 0.0,
                      ),
                    ),
                    child: child,
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  AppLocalizations.of(context).listening,
                  style: GoogleFonts.cairo(color: Colors.teal),
                ),
              ),

            // Visualization of Spoken Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                _spokenText,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // 4. Feedback Card
            if (_showFeedback && _lastIncorrectInput != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.cairo(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text:
                                      "${AppLocalizations.of(context).wrongFeedback} ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: AppLocalizations.of(context).heard,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          _lastIncorrectInput!, // Arabic text
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Action Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Validate Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _validate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).validateBtn,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Next Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).nextBtn,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Finish Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showFinalScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).finishTest,
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
