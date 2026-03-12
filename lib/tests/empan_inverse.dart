import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization.dart';
import '../services/firestore_service.dart';

import 'dart:async';

class EmpanInverseDirect extends StatefulWidget {
  final String patientName;
  const EmpanInverseDirect({super.key, required this.patientName});

  @override
  State<EmpanInverseDirect> createState() => _EmpanInverseDirectState();
}

class _EmpanInverseDirectState extends State<EmpanInverseDirect>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late final AudioRecorder _audioRecorder;
  bool _isListening = false;
  bool _isPlaying = false;
  String _spokenText = "";
  double _score = 0.0;
  int _currentIndex = 0;
  bool _isTestStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = "00:00";
  bool _showFeedback = false;
  String? _lastIncorrectInput;

  late AnimationController _micAnimController;
  late Animation<double> _micAnimation;

  // Empan Inverse sequences
  final List<String> _sequences = [
    "2 4",
    "5 8",
    "6 2 9",
    "4 1 5",
    "3 2 7 9",
    "4 9 6 8",
    "1 5 2 8 6",
    "6 1 8 4 3",
    "5 3 9 4 1 8",
    "7 2 4 8 5 6",
    "8 1 2 9 3 6 5",
    "4 7 3 9 1 2 8",
    "9 4 3 7 6 2 5 8",
    "7 2 8 1 9 6 5 3",
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
      _showFeedback = false;
      _spokenText = "";
    });

    String sequence = _sequences[_currentIndex];
    List<String> numbers = sequence.split(' ');

    for (String number in numbers) {
      String arabicWord = _getArabicWord(number);
      await _flutterTts.speak(arabicWord);
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
    // REVERSED LOGIC FOR EMPAN INVERSE
    String targetDigitsReversed = _sequences[_currentIndex]
        .split(' ')
        .reversed
        .join('');
    String cleanSpoken = _spokenText.replaceAll(RegExp(r'[^0-9]'), '');

    bool isCorrect = false;
    if (cleanSpoken.contains(targetDigitsReversed)) {
      isCorrect = true;
    }

    if (isCorrect) {
      setState(() {
        _score += 0.5;
        _showFeedback = false;
        _isValidated = true;
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
        _isValidated = true;
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
        _isValidated = false;
      });
      _speech.stop();
    } else {
      _showFinalScore();
    }
  }

  final FirestoreService _firestoreService = FirestoreService();

  void _showFinalScore() async {
    _stopTest();

    try {
      await _firestoreService.saveTestResult(
        patientId: widget.patientName,
        patientIdentifier: "Unknown",
        score: _score,
        totalDuration: _formattedTime,
        testType: 'Empan Inverse', // Explicitly setting the test type
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          ).empanInverseTest, // Using new translation
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
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

            ElevatedButton.icon(
              onPressed: _isPlaying
                  ? null
                  : () {
                      if (!_isTestStarted) {
                        _startTest();
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

            Padding(
              padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
