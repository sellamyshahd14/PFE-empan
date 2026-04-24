import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization.dart';
import '../services/firestore_service.dart';

import 'dart:async';

class EmpanInverse extends StatefulWidget {
  final String patientDocId;
  final String patientIdentifier;

  const EmpanInverse({
    super.key,
    required this.patientDocId,
    required this.patientIdentifier,
  });

  @override
  State<EmpanInverse> createState() => _EmpanInverseState();
}

class _EmpanInverseState extends State<EmpanInverse>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late final AudioRecorder _audioRecorder;
  bool _isListening = false;
  bool _isFinished = false;
  bool _isPlaying = false;
  String _spokenText = "";
  String _previousSpokenText = "";
  double _score = 0.0;
  int _currentIndex = 0;
  int _attemptCount = 0;
  final Set<int> _scoredIndices = {};
  double _soundLevel = 0.0;
  bool _isTestStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _listenTimer; // Hard stop timer for mic
  Timer? _guardianTimer; // Polling guardian to restart mic on early close
  String _formattedTime = "00:00";
  bool _showFeedback = false;
  String? _lastIncorrectInput;
  bool _isFluentRunning = false;
  bool _isPaused = false;

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
  }

  Future<void> _stopTest() async {
    _stopwatch.stop();
    _timer?.cancel();
    _listenTimer?.cancel();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _togglePause() {
    if (!_isTestStarted || _isFinished) return;

    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _stopwatch.stop();
        _timer?.cancel();
        _flutterTts.stop();
        _speech.stop();
        _stopGuardian();
        _listenTimer?.cancel();
        _isListening = false;
        _isPlaying = false;
        _isFluentRunning = false;
      } else {
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _formattedTime = _formatTime(_stopwatch.elapsed);
            });
          }
        });
        // Automatically reopen mic/stt without erasing
        _listen(resume: true);
      }
    });
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint("STT Status: $status"),
      onError: (error) => debugPrint("STT Error: $error"),
    );
    if (!available) {
      debugPrint("STT Not Available");
    }
  }

  void _initTts() async {
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setSpeechRate(0.65);
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

    // Stop mic if it is active before playing the sequence
    if (_isListening) {
      _listenTimer?.cancel();
      _speech.stop();
      setState(() => _isListening = false);
    }

    // Start the test timer on first interaction
    if (!_isTestStarted) {
      _startTest();
    }

    setState(() {
      _isPlaying = true;
      _showFeedback = false;
      _spokenText = "";
    });

    String lang = AppLocalizations.of(context).locale.languageCode;
    await _flutterTts.setLanguage(lang == 'ar' ? 'ar' : 'fr-FR');

    if (_currentIndex == 0) {
      String introSentence = AppLocalizations.of(context).empanInverseIntro;
      await _flutterTts.speak(introSentence);
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    String sequence = _sequences[_currentIndex];
    List<String> numbers = sequence.split(' ');

    for (String number in numbers) {
      String word = _getLocalizedWord(number);
      await _flutterTts.speak(word);
      await Future.delayed(const Duration(milliseconds: 900));
    }
    setState(() => _isPlaying = false);
  }

  // Combined Listen + 3s Pause + Cue + Record
  Future<void> _runFluentSequence() async {
    if (_isFluentRunning || _isPlaying || _isListening) return;
    if (_attemptCount >= 2 || _scoredIndices.contains(_currentIndex)) return;

    setState(() {
      _isFluentRunning = true;
      _attemptCount++;
    });

    // 1. Speak numbers
    await _speakSequence();

    // 2. Wait 3 seconds
    await Future.delayed(const Duration(milliseconds: 1500));

    // 3. Play Cue
    String cue = AppLocalizations.of(context).onCommenceCue;
    await _flutterTts.speak(cue);
    // Give cue time to finish
    await Future.delayed(const Duration(milliseconds: 1500));

    // 4. Start Listening
    _listen();

    setState(() => _isFluentRunning = false);
  }

  // Purely for the small "Re-record" button (user calls it "the arrow")
  void _listenOnly() async {
    if (_isPlaying || _isFluentRunning) return;
    if (_scoredIndices.contains(_currentIndex)) return;

    // Immediately clear current state to "erase" visible response
    setState(() {
      _spokenText = "";
      _previousSpokenText = "";
      _showFeedback = false;
      _lastIncorrectInput = null;
    });

    // If already listening, stop first and small delay
    if (_isListening) {
      _stopGuardian();
      _listenTimer?.cancel();
      await _speech.stop();
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _listen(resume: false);
  }

  String _getLocalizedWord(String digit) {
    String lang = AppLocalizations.of(context).locale.languageCode;
    if (lang == 'fr') {
      switch (digit) {
        case '0': return 'zéro';
        case '1': return 'un';
        case '2': return 'deux';
        case '3': return 'trois';
        case '4': return 'quatre';
        case '5': return 'cinq';
        case '6': return 'six';
        case '7': return 'sept';
        case '8': return 'huit';
        case '9': return 'neuf';
        default: return digit;
      }
    } else {
      switch (digit) {
        case '0': return 'صفر';
        case '1': return 'واحد';
        case '2': return 'اثنان';
        case '3': return 'ثلاثة';
        case '4': return 'أربعة';
        case '5': return 'خمسة';
        case '6': return 'ستة';
        case '7': return 'سبعة';
        case '8': return 'ثمانية';
        case '9': return 'تسعة';
        default: return digit;
      }
    }
  }

  String _normalizeDigits(String input) {
    const Map<String, String> wordToDigit = {
      'واحد': '1', 'واحده': '1', 'احد': '1', 'un': '1', 'une': '1',
      'اثنان': '2', 'اثنين': '2', 'إثنان': '2', 'إثنين': '2', 'deux': '2',
      'ثلاثة': '3', 'ثلاثه': '3', 'trois': '3',
      'أربعة': '4', 'أربعه': '4', 'اربعة': '4', 'اربعه': '4', 'quatre': '4',
      'خمسة': '5', 'خمسه': '5', 'cinq': '5',
      'ستة': '6', 'سته': '6', 'six': '6',
      'سبعة': '7', 'سبعه': '7', 'sept': '7',
      'ثمانية': '8', 'ثمانيه': '8', 'huit': '8',
      'تسعة': '9', 'تسعه': '9', 'neuf': '9',
      'صفر': '0', 'zéro': '0', 'zero': '0',
    };
    const Map<String, String> arabicToLatin = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };

    String result = input.toLowerCase();
    wordToDigit.forEach((word, digit) {
      result = result.replaceAll(word, digit);
    });
    arabicToLatin.forEach((arabic, latin) {
      result = result.replaceAll(arabic, latin);
    });
    return result.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _listen({bool resume = false}) async {
    if (!_isListening) {
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
          if (!resume) {
            _spokenText = "";
            _previousSpokenText = "";
          }
        });
        _startSttSession();

        // Hard 60-second force-stop timer
        _listenTimer?.cancel();
        _listenTimer = Timer(const Duration(seconds: 60), () {
          _stopGuardian();
          if (_isListening) {
            _speech.stop();
            setState(() => _isListening = false);
          }
        });

        // Polling guardian: check every 1s if STT stopped early → restart
        _guardianTimer?.cancel();
        _guardianTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!_isListening) {
            t.cancel();
            return;
          }
          if (!_speech.isListening) {
            _startSttSession();
          }
        });
      }
    } else {
      _stopGuardian();
      _listenTimer?.cancel();
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _startSttSession() {
    String lang = AppLocalizations.of(context).locale.languageCode;
    
    // Commit the current spoken text before starting a new session
    _previousSpokenText = _spokenText;
    
    _speech.listen(
      localeId: lang == 'ar' ? 'ar-TN' : null,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 30),
      partialResults: true,
      onSoundLevelChange: (level) {
        setState(() { _soundLevel = level; });
      },
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty && mounted) {
          setState(() {
            String newWords = val.recognizedWords;
            _spokenText = _previousSpokenText.isEmpty 
                ? newWords 
                : "$_previousSpokenText $newWords".trim();
          });
        }
      },
    );
  }

  void _stopGuardian() {
    _guardianTimer?.cancel();
    _guardianTimer = null;
  }

  bool _isValidated = false;

  void _validate() {
    // Stop mic and guardian if still active
    if (_isListening) {
      _stopGuardian();
      _listenTimer?.cancel();
      _speech.stop();
      setState(() => _isListening = false);
    }

    // If already scored for this sequence, do nothing
    if (_scoredIndices.contains(_currentIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).correctFeedback),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Empan Inverse: the answer must be the REVERSE of the sequence
    String targetDigitsReversed =
        _sequences[_currentIndex].split(' ').reversed.join('');
    String cleanSpoken = _normalizeDigits(_spokenText);

    bool isCorrect = false;
    if (cleanSpoken.contains(targetDigitsReversed)) {
      isCorrect = true;
    }

    if (isCorrect) {
      setState(() {
        if (!_scoredIndices.contains(_currentIndex)) {
          _score += 0.5;
          _scoredIndices.add(_currentIndex);
        }
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
        _attemptCount = 0; // Reset for next sequence
        _spokenText = "";
        _isListening = false;
        _showFeedback = false;
        _lastIncorrectInput = null;
        _isValidated = false;
      });
      _stopGuardian();
      _listenTimer?.cancel();
      _speech.stop();

      // AUTO-TRIGGER: Launch next sequence automatically after 1.5s (except for the very first one)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _currentIndex > 0) {
          _runFluentSequence();
        }
      });
    } else {
      _showFinalScore();
    }
  }

  final FirestoreService _firestoreService = FirestoreService();

  void _showFinalScore() async {
    if (_isFinished) return;
    setState(() => _isFinished = true);

    _stopTest();

    try {
      await _firestoreService.saveTestResult(
        patientDocId: widget.patientDocId,
        patientIdentifier: widget.patientIdentifier,
        score: _score,
        totalDuration: _formattedTime,
        testType: 'Empan Inverse',
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
              Navigator.of(context).pop(); // Close Dialog
              Navigator.of(context).pop(); // Close Test Page
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

  void _showExitConfirmationDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          loc.exitWithoutSaving,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          loc.exitConfirmBody,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel, style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // exit test
            },
            child: Text(
              loc.exitWithoutSaving,
              style: GoogleFonts.cairo(color: Colors.red),
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
    _listenTimer?.cancel();
    _guardianTimer?.cancel();
    _micAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: _isFinished ? null : _showFinalScore,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: Text(
                AppLocalizations.of(context).finishTest,
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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

            // 2. Fluent Flow Buttons
            Center(
              child: Column(
                children: [
                  // MAIN BUTTON: Full Sequence (Listen + 3s + Cue + Record)
                  GestureDetector(
                    onTap: (_attemptCount >= 2 || _scoredIndices.contains(_currentIndex) || _isFluentRunning || _isPlaying || _isListening || _isPaused)
                        ? null
                        : _runFluentSequence,
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isPlaying || _isListening || _isFluentRunning)
                            AnimatedBuilder(
                              animation: _micAnimation,
                              builder: (context, child) {
                                // FIXED: Use Transform.scale instead of changing width/height
                                // to prevent layout shifts (screen shaking).
                                double scale = 1.0 + (_soundLevel.clamp(0, 10) / 15);
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (_isPlaying || _isFluentRunning)
                                          ? Colors.teal.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_attemptCount >= 2 ||
                                      _scoredIndices.contains(_currentIndex) || _isPaused)
                                  ? Colors.grey
                                  : (_isListening
                                      ? Colors.orange
                                      : Colors.teal),
                              boxShadow: [
                                BoxShadow(
                                  color: ((_attemptCount >= 2 ||
                                              _scoredIndices
                                                  .contains(_currentIndex)) || _isPaused)
                                          ? Colors.grey
                                          : (_isListening
                                              ? Colors.orange
                                              : Colors.teal)
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.volume_up,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Attempt Counter for Main Button
                  Text(
                    AppLocalizations.of(context)
                        .attemptsLabel
                        .replaceFirst('{}', '$_attemptCount')
                        .replaceFirst('/3', '/2'), // UI requirement check: user said "repeat 2 times not 3"
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _attemptCount >= 2 ? Colors.red : Colors.grey[700],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            onPressed: (_scoredIndices.contains(_currentIndex) ||
                                    _isFluentRunning ||
                                    _isPlaying ||
                                    _isPaused)
                                ? null
                                : _listenOnly,
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.teal, width: 2),
                              ),
                              child: const Icon(Icons.replay,
                                  color: Colors.teal, size: 30),
                            ),
                            tooltip: "Erase and restart recording",
                          ),
                          Text(
                            AppLocalizations.of(context).repeatSequence,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Column(
                        children: [
                          IconButton(
                            onPressed: _togglePause,
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _isPaused ? Colors.red : Colors.orange,
                                    width: 2),
                              ),
                              child: Icon(
                                _isPaused
                                    ? Icons.play_circle_outline
                                    : Icons.pause_circle_outline,
                                color: _isPaused ? Colors.red : Colors.orange,
                                size: 30,
                              ),
                            ),
                            tooltip: _isPaused ? "Play" : "Pause",
                          ),
                          Text(
                            _isPaused ? "Play" : "Pause",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: _isPaused ? Colors.red : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isListening)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      AppLocalizations.of(context).listening,
                      style: GoogleFonts.cairo(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isPaused ? null : () {
                      _stopGuardian();
                      _listenTimer?.cancel();
                      _speech.stop();
                      setState(() => _isListening = false);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      AppLocalizations.of(context).finishTest, // MODIFIED: localized
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
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

            if (_spokenText.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_spokenText.startsWith("manual:"))
                      Text(
                        '⌨️ Tapped: ${_normalizeDigits(_spokenText)}', // MODIFIED: consistency with Direct
                        style: GoogleFonts.cairo(fontSize: 12),
                      )
                    else
                      Text(
                        '🎤 STT: $_spokenText',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                    Text(
                      '🔢 Mapped: ${_normalizeDigits(_spokenText)}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                    // MODIFIED: '✅ Expected' row NOT added to ensure patient privacy
                  ],
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
                          onPressed: _isPaused ? null : _validate,
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
                          onPressed: _isPaused ? null : _next,
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
                      onPressed: (_isFinished || _isPaused) ? null : _showFinalScore,
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
      ),
    );
  }
}
