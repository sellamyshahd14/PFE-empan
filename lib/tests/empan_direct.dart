import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization.dart';
import '../services/firestore_service.dart';

import 'dart:async';
import 'package:flutter/services.dart';

class EmpanDirect extends StatefulWidget {
  final String patientDocId;
  final String patientIdentifier;

  const EmpanDirect({
    super.key,
    required this.patientDocId,
    required this.patientIdentifier,
  });

  @override
  State<EmpanDirect> createState() => _EmpanDirectState();
}

class _EmpanDirectState extends State<EmpanDirect> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late final AudioRecorder _audioRecorder;
  
  bool _isListening = false;
  bool _isPlaying = false;
  String _spokenText = "";
  String _accumulatedDigits = "";
  double _soundLevel = 0.0;
  double _score = 0.0;
  int _currentIndex = 0;
  int _attemptCount = 0;
  final Set<int> _scoredIndices = {};
  bool _isTestStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _listenTimer; // Force stop timer
  Timer? _guardianTimer; // Check for early closure
  String _formattedTime = "00:00";
  bool _showFeedback = false;
  String? _lastIncorrectInput;
  bool _isFluentRunning = false;
  bool _showManualInput = false;
  final TextEditingController _manualController = TextEditingController();

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
    _stopGuardian();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint("STT Status: $status"),
      onError: (error) {
        debugPrint("STT Error: $error");
        if (_isListening) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isListening) _startSttSession(initial: false);
          });
        }
      },
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

    if (_isListening) {
      _listenTimer?.cancel();
      _stopGuardian();
      _speech.stop();
      setState(() => _isListening = false);
    }

    if (!mounted) return;
    final locs = AppLocalizations.of(context);

    if (!_isTestStarted) {
      _startTest();
    }

    setState(() {
      _isPlaying = true;
      _showFeedback = false;
      _spokenText = "";
      _accumulatedDigits = "";
    });

    String lang = locs.locale.languageCode;
    await _flutterTts.setLanguage(lang == 'ar' ? 'ar' : 'fr-FR');

    if (_currentIndex == 0) {
      String introSentence = locs.empanDirectIntro;
      await _flutterTts.speak(introSentence);
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (!mounted) return;
    String sequence = _sequences[_currentIndex];
    List<String> numbers = sequence.split(' ');

    for (String number in numbers) {
      if (!mounted) break;
      String word = _getLocalizedWord(number, locs);
      await _flutterTts.speak(word);
      await Future.delayed(const Duration(milliseconds: 900));
    }

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _runFluentSequence() async {
    if (!mounted) return;
    final locs = AppLocalizations.of(context);
    if (_attemptCount >= 2 || _scoredIndices.contains(_currentIndex)) return;

    setState(() {
      _isFluentRunning = true;
      _attemptCount++;
      _spokenText = "";
      _accumulatedDigits = "";
    });

    await _speakSequence();

    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    String cue = locs.onCommenceCue;
    await _flutterTts.speak(cue);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    _listen();

    if (mounted) {
      setState(() => _isFluentRunning = false);
    }
  }

  void _listenOnly() async {
    if (_isPlaying || _isFluentRunning) return;
    if (_scoredIndices.contains(_currentIndex)) return;

    setState(() {
      _spokenText = "";
      _accumulatedDigits = "";
      _showFeedback = false;
      _lastIncorrectInput = null;
    });

    if (_isListening) {
      _stopGuardian();
      _listenTimer?.cancel();
      await _speech.stop();
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _listen();
  }

  String _getLocalizedWord(String digit, AppLocalizations locs) {
    String lang = locs.locale.languageCode;
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
        case '0': return locs.zero;
        case '1': return locs.one;
        case '2': return locs.two;
        case '3': return locs.three;
        case '4': return locs.four;
        case '5': return locs.five;
        case '6': return locs.six;
        case '7': return locs.seven;
        case '8': return locs.eight;
        case '9': return locs.nine;
        default: return digit;
      }
    }
  }

  String _extractDigits(String input) {
    if (input.isEmpty) return "";
    String result = input.toLowerCase();

    const Map<String, String> arabicToLatin = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    arabicToLatin.forEach((k, v) => result = result.replaceAll(k, v));

    final Map<String, String> wordToDigit = {
      'واحد': '1', 'واحده': '1', 'احد': '1', 'وحد': '1',
      'جوج': '2', 'زوز': '2', 'اثنين': '2', 'اثنان': '2', 'إثنين': '2', 'اتنين': '2',
      'ثلاثة': '3', 'ثلاثه': '3', 'ثلاثا': '3', 'تلاتة': '3', 'تلاته': '3', 'تلاتا': '3',
      'أربعة': '4', 'أربعه': '4', 'أربعا': '4', 'اربعة': '4', 'اربعه': '4', 'اربعا': '4', 'ربة': '4', 'ربعه': '4', 'ربعا': '4',
      'خمسة': '5', 'خمسه': '5', 'خمسا': '5', 'حمسة': '5', 'حمسه': '5', 'حمسا': '5',
      'ستة': '6', 'سته': '6', 'ستا': '6', 'ست': '6',
      'سبعة': '7', 'سبعه': '7', 'سبعا': '7', 'سبع': '7',
      'ثمانية': '8', 'ثمانيه': '8', 'ثمانيا': '8', 'ثمنية': '8', 'ثمنيه': '8', 'ثمنيا': '8', 'تمنية': '8', 'تمنيه': '8', 'تمنيا': '8',
      'تسعة': '9', 'تسعه': '9', 'تسعا': '9', 'تسع': '9',
      'عشرة': '10', 'عشره': '10', 'عشرا': '10', 'صفر': '0',
      'un': '1', 'une': '1', 'deux': '2', 'trois': '3', 'quatre': '4', 'cinq': '5', 'six': '6', 'sept': '7', 'huit': '8', 'neuf': '9', 'zéro': '0', 'zero': '0',
    };

    final sortedKeys = wordToDigit.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (var key in sortedKeys) {
      result = result.replaceAll(key, ' ${wordToDigit[key]} ');
    }

    result = result.replaceAll(RegExp(r'[^0-9]'), '');

    if (result.isEmpty) return "";
    StringBuffer sb = StringBuffer();
    sb.write(result[0]);
    for (int i = 1; i < result.length; i++) {
      if (result[i] != result[i - 1]) {
        sb.write(result[i]);
      }
    }
    return sb.toString();
  }

  String _mergeDigits(String existing, String incoming) {
    if (incoming.isEmpty) return existing;
    if (existing.isEmpty) return incoming;
    if (incoming.startsWith(existing)) return incoming;
    return existing + incoming;
  }

  void _listen() async {
    if (_showManualInput) return;
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint("STT Status: $status"),
        onError: (error) {
          if (_isListening) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isListening) _startSttSession(initial: false);
            });
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _spokenText = "";
          _accumulatedDigits = "";
        });
        _startSttSession(initial: true);

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
            _startSttSession(initial: false);
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

  void _startSttSession({required bool initial}) {
    if (!mounted) return;
    String lang = AppLocalizations.of(context).locale.languageCode;
    _speech.listen(
      localeId: lang == 'ar' ? 'ar-TN' : null,
      partialResults: true,
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = level;
        });
      },
      pauseFor: initial ? const Duration(seconds: 5) : const Duration(seconds: 10),
      listenFor: const Duration(seconds: 60),
      onResult: (val) {
        if (!mounted) return;
        setState(() {
          _spokenText = val.recognizedWords;
          _accumulatedDigits = _mergeDigits(_accumulatedDigits, _extractDigits(val.recognizedWords));
        });
      },
    );
  }

  void _stopGuardian() {
    _guardianTimer?.cancel();
    _guardianTimer = null;
  }

  bool _isValidated = false;

  void _validate() {
    if (_isListening) {
      _stopGuardian();
      _listenTimer?.cancel();
      _speech.stop();
      setState(() => _isListening = false);
    }

    if (_scoredIndices.contains(_currentIndex)) return;

    String targetDigits = _sequences[_currentIndex].replaceAll(' ', '');
    bool isCorrect = (_accumulatedDigits == targetDigits);

    if (!isCorrect && _accumulatedDigits.contains(targetDigits) && _accumulatedDigits.length <= targetDigits.length + 1) {
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
        _lastIncorrectInput = _accumulatedDigits.isNotEmpty ? _accumulatedDigits : _spokenText;
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
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isListening) {
      _stopGuardian();
      _listenTimer?.cancel();
      _speech.stop();
      setState(() => _isListening = false);
    }

    if (_currentIndex < _sequences.length - 1) {
      setState(() {
        _currentIndex++;
        _attemptCount = 0;
        _spokenText = "";
        _accumulatedDigits = "";
        _isListening = false;
        _showFeedback = false;
        _lastIncorrectInput = null;
        _isValidated = false;
      });
      _stopGuardian();
      _listenTimer?.cancel();
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
        patientDocId: widget.patientDocId,
        patientIdentifier: widget.patientIdentifier,
        score: _score,
        totalDuration: _formattedTime,
        testType: 'Empan Direct',
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
              Navigator.of(context).pop();
              Navigator.of(context).pop();
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

  void _showManualInputDialog() {
    if (_isListening) {
      _stopGuardian();
      _listenTimer?.cancel();
      _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _showManualInput = true;
      _manualController.clear();
    });

    final locs = AppLocalizations.of(context);
    final targetLength = _sequences[_currentIndex].replaceAll(' ', '').length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                locs.manualInputTitle,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(locs.manualInputInstr, style: GoogleFonts.cairo()),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _manualController,
                      keyboardType: TextInputType.number,
                      maxLength: targetLength,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      decoration: const InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 20),
                    // Digit Grid (Phone style 3x3 + Backspace centered)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDigitButton('1', setDialogState),
                            const SizedBox(width: 12),
                            _buildDigitButton('2', setDialogState),
                            const SizedBox(width: 12),
                            _buildDigitButton('3', setDialogState),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDigitButton('4', setDialogState),
                            const SizedBox(width: 12),
                            _buildDigitButton('5', setDialogState),
                            const SizedBox(width: 12),
                            _buildDigitButton('6', setDialogState),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDigitButton('7', setDialogState),
                            const SizedBox(width: 12),
                            _buildDigitButton('8', setDialogState),
                            const SizedBox(width: 12),
                            _buildDigitButton('9', setDialogState),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Backspace row
                        InkWell(
                          onTap: () {
                            if (_manualController.text.isNotEmpty) {
                              setDialogState(() {
                                _manualController.text = _manualController.text
                                    .substring(0, _manualController.text.length - 1);
                              });
                            }
                          },
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red.shade300, width: 2),
                            ),
                            child: Icon(Icons.backspace_outlined, color: Colors.red.shade400, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _showManualInput = false);
                    Navigator.pop(context);
                  },
                  child: Text(locs.cancel, style: GoogleFonts.cairo(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _manualController.text.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _accumulatedDigits = _manualController.text;
                            _spokenText = "manual: ${_manualController.text}";
                            _isValidated = false;
                            _showManualInput = false;
                          });
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(locs.validateBtn, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDigitButton(String digit, StateSetter setDialogState) {
    final targetLength = _sequences[_currentIndex].replaceAll(' ', '').length;
    return InkWell(
      onTap: _manualController.text.length >= targetLength
          ? null
          : () {
              setDialogState(() {
                _manualController.text += digit;
              });
            },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _manualController.text.length >= targetLength ? Colors.grey.shade300 : Colors.teal,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _manualController.text.length >= targetLength ? Colors.grey : Colors.teal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _manualController.dispose();
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
          AppLocalizations.of(context).testTitle,
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: _showFinalScore, // MODIFIED: same behavior as bottom button
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

            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: (_attemptCount >= 2 || _scoredIndices.contains(_currentIndex) || _isFluentRunning || _isPlaying || _isListening)
                        ? null
                        : _runFluentSequence,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isPlaying || _isListening || _isFluentRunning)
                          AnimatedBuilder(
                            animation: _micAnimation,
                            builder: (context, child) {
                              double pulseSize = 120 + (_soundLevel.clamp(0, 10) * 2);
                              return Container(
                                width: pulseSize,
                                height: pulseSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (_isPlaying || _isFluentRunning)
                                      ? const Color(0x33009688)
                                      : const Color(0x33FF9800),
                                ),
                              );
                            },
                          ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_attemptCount >= 2 || _scoredIndices.contains(_currentIndex))
                                ? Colors.grey
                                : (_isListening ? Colors.orange : Colors.teal),
                            boxShadow: [
                              BoxShadow(
                                color: (_attemptCount >= 2 || _scoredIndices.contains(_currentIndex))
                                    ? const Color(0x669E9E9E)
                                    : (_isListening ? const Color(0x66FF9800) : const Color(0x66009688)),
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
                  const SizedBox(height: 15),
                  Text(
                    AppLocalizations.of(context)
                        .attemptsLabel
                        .replaceFirst('{}', '$_attemptCount')
                        .replaceFirst('/3', '/2'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _attemptCount >= 2 ? Colors.red : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 25),
                  IconButton(
                    onPressed: (_scoredIndices.contains(_currentIndex) || _isFluentRunning || _isPlaying)
                        ? null
                        : _listenOnly,
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.teal, width: 2),
                      ),
                      child: const Icon(Icons.replay, color: Colors.teal, size: 30),
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
                  const SizedBox(height: 10),
                  if (_isListening || (_spokenText.isEmpty && !_isPlaying && !_isFluentRunning))
                    IconButton(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.teal, size: 28),
                      tooltip: AppLocalizations.of(context).manualInputHint,
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
                    onPressed: () {
                      _stopGuardian();
                      _listenTimer?.cancel();
                      _speech.stop();
                      setState(() => _isListening = false);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      AppLocalizations.of(context).doneListening,
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

            if (_spokenText.isNotEmpty || _accumulatedDigits.isNotEmpty)
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
                      Text('⌨️ Tapped: $_accumulatedDigits', // MODIFIED: relabel for manual mode
                          style: GoogleFonts.cairo(fontSize: 12))
                    else
                      Text('🎤 STT: $_spokenText',
                          style: GoogleFonts.cairo(fontSize: 12)),
                    Text('🔢 Mapped: $_accumulatedDigits',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.blue[800],
                        )),
                    // MODIFIED: deleted '✅ Expected' row to prevent patient from seeing answers
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
                          _lastIncorrectInput!,
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
      ),
    );
  }
}
