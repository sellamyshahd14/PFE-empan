import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class EmpanDirect extends StatefulWidget {
  const EmpanDirect({super.key});

  @override
  State<EmpanDirect> createState() => _EmpanDirectState();
}

class _EmpanDirectState extends State<EmpanDirect> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isPlaying = false;
  String _spokenText = "";
  double _score = 0.0;
  int _currentIndex = 0;
  bool _isTestStarted = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = "00:00";

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
    _initSpeech();
    _initTts();
  }

  void _startTest() {
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

  void _stopTest() {
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
      // Simple and standard init
      await _flutterTts.setLanguage("ar"); // Generic Arabic
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print("TTS Init Error: $e");
    }

    _flutterTts.setCompletionHandler(() {
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _speakSequence() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);

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

  void _validateAndNext() {
    String targetDigits = _sequences[_currentIndex].replaceAll(' ', '');
    String cleanSpoken = _spokenText.replaceAll(RegExp(r'[^0-9]'), '');

    bool isCorrect = false;
    if (cleanSpoken.contains(targetDigits)) {
      isCorrect = true;
    }

    if (isCorrect) {
      setState(() {
        _score += 0.5;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Correct! +0.5')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect. Entendu: $_spokenText')),
      );
    }

    if (_currentIndex < _sequences.length - 1) {
      setState(() {
        _currentIndex++;
        _spokenText = "";
        _isListening = false;
      });
      _speech.stop();
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    _stopTest();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Terminé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre score final est : $_score / 7'),
            const SizedBox(height: 10),
            Text('Temps écoulé : $_formattedTime'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _spokenText = "";
                _isTestStarted = false;
                _stopwatch.reset();
                _formattedTime = "00:00";
              });
            },
            child: const Text('Menu Principal'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empan Direct'),
        actions: [
          if (_isTestStarted)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Center(
                child: Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: !_isTestStarted
            ? Center(
                child: ElevatedButton(
                  onPressed: _startTest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('Démarrer le test'),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Séquence ${_currentIndex + 1}/${_sequences.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 50),

                  ElevatedButton.icon(
                    onPressed: _isPlaying ? null : _speakSequence,
                    icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
                    label: Text(
                      _isPlaying
                          ? 'Lecture en cours...'
                          : 'Écouter la séquence',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 50),
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 60,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isListening
                        ? 'Écoute en cours...'
                        : 'Appuyez pour répondre',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _spokenText,
                    style: const TextStyle(fontSize: 24, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        onPressed: _listen,
                        backgroundColor: _isListening
                            ? Colors.red
                            : Colors.blue,
                        child: const Icon(Icons.mic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _validateAndNext,
                        child: Text(
                          _currentIndex == _sequences.length - 1
                              ? 'Terminer'
                              : 'Suivant / Valider',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showFinalScore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Terminer le test'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Score actuel: $_score'),
                ],
              ),
      ),
    );
  }
}
