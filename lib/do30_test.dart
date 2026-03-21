import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'services/firestore_service.dart';
import 'localization.dart';

class TestDO30 extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  final String? patientIdentifier;

  const TestDO30({
    super.key,
    this.patientId,
    this.patientName,
    this.patientIdentifier,
  });

  @override
  State<TestDO30> createState() => _TestDO30State();
}

class _TestDO30State extends State<TestDO30> {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final Stopwatch _stopwatch = Stopwatch();
  final FirestoreService _firestoreService = FirestoreService();
  
  double _soundLevel = 0.0;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isSaving = false;
  String _lastWords = "";
  String _sttStatus = "";
  int _currentPage = 0;
  int _score = 0;
  final Set<int> _scoredPages = {}; 

  final List<String> _images = [
    'assets/images/faucet.png',
    'assets/images/parachute.png',
    'assets/images/anchor.png',
    'assets/images/domino.png',
    'assets/images/mushroom.png',
    'assets/images/elephant.png',
    'assets/images/scissors.png',
    'assets/images/house.png',
    'assets/images/snail.png',
    'assets/images/turtle.png',
    'assets/images/kangourou.png',
    'assets/images/girafe.png',
    'assets/images/cat.png',
    'assets/images/rhinoceros.png',
    'assets/images/butterfly.png',
    'assets/images/squirrel.png',
    'assets/images/scale.png',
    'assets/images/bell.png',
    'assets/images/helicopter.png',
    'assets/images/crocodile.png',
    'assets/images/think.png',
    'assets/images/fall.png',
    'assets/images/cry.png',
    'assets/images/climb.png',
    'assets/images/sleep.png',
    'assets/images/swim.png',
    'assets/images/run.png',
    'assets/images/write.png',
    'assets/images/eat.png',
    'assets/images/drink.png',
  ];

  final Map<int, List<String>> _correctAnswers = {
    0: ['robinet', 'صنبور', 'robinets', 'faucet'],
    1: ['parachute', 'مظلة', 'parachutes', 'باراشوت'],
    2: ['ancre', 'مرساة', 'anchors', 'anchor'],
    3: ['domino', 'دومينو', 'dominos'],
    4: ['champignon', 'فطر', 'champignons', 'mushroom'],
    5: ['éléphant', 'elephant', 'فيل', 'élépant', 'الفيل'],
    6: ['ciseaux', 'مقص', 'ciseau', 'scissors', 'المقص'],
    7: ['maison', 'منزل', 'maisons', 'house', 'دار'],
    8: ['escargot', 'حلزون', 'escargots', 'snail'],
    9: ['tortue', 'سلحفاة', 'tortues', 'turtle', 'السلحفاة'],
    10: ['kangourou', 'كنغر', 'kangaroo', 'kangourous'],
    11: ['girafe', 'زرافة', 'giraffe', 'girafes'],
    12: ['chat', 'قط', 'chats', 'cat', 'قطة'],
    13: ['rhinocéros', 'وحيد القرن', 'rhinoceros', 'rhino'],
    14: ['papillon', 'فراشة', 'papillons', 'butterfly'],
    15: ['écureuil', 'سنجاب', 'squirrel', 'ecureuil'],
    16: ['échelle', 'سلم', 'scale', 'échele', 'سلم'],
    17: ['cloche', 'جرس', 'bell', 'cloches'],
    18: ['hélicoptère', 'مروحية', 'helicopter', 'hélicoptéres', 'هيليكوبتر'],
    19: ['crocodile', 'تمساح', 'crocodiles'],
    20: ['penser', 'تفكير', 'think', 'pensée'],
    21: ['tomber', 'سقوط', 'fall', 'tombé'],
    22: ['pleurer', 'بكاء', 'cry', 'pleure'],
    23: ['escalader', 'تسلق', 'climb', 'monté', 'climbing'],
    24: ['dormir', 'نوم', 'sleep', 'dodo'],
    25: ['nager', 'سباحة', 'swim', 'nage'],
    26: ['courir', 'ركض', 'run', 'course'],
    27: ['écrire', 'كتابة', 'write', 'ecrire'],
    28: ['manger', 'أكل', 'eat', 'mange'],
    29: ['boire', 'شرب', 'drink', 'bois'],
  };

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _initTts();
    _initSpeech();
  }

  void _initTts() async {
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _speakPrompt();
      });
    } catch (e) {
      print("TTS Init Error: $e");
    }
  }

  void _initSpeech() async {
    try {
      _sttStatus = "Initialisation...";
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('STT Status: $status');
          if (mounted) {
            setState(() {
              _sttStatus = status;
              if (status == 'notListening' || status == 'done') {
                _isListening = false;
              }
            });
          }
        },
        onError: (errorNotification) {
          print('STT Error: ${errorNotification.errorMsg}');
          if (mounted) {
            setState(() {
              _sttStatus = "Error: ${errorNotification.errorMsg}";
              _isListening = false;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechEnabled = available;
          _sttStatus = available ? "Prêt" : "Non disponible";
        });
      }
    } catch (e) {
      print('STT Exception during init: $e');
      if (mounted) {
        setState(() {
          _sttStatus = "Exception: $e";
        });
      }
    }
  }

  Future<void> _speakPrompt() async {
    final loc = AppLocalizations.of(context);
    String languageCode = loc.locale.languageCode;
    
    if (languageCode == 'ar') {
      await _flutterTts.setLanguage("ar");
    } else {
      await _flutterTts.setLanguage("fr-FR");
    }
    
    String text = loc.translate('describe_prompt');
    await _flutterTts.speak(text);
  }

  void _listen() async {
    await _flutterTts.stop();
    
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    if (!_isListening) {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      
      if (!status.isGranted) {
        if (mounted) setState(() => _sttStatus = "Permission micro refusée");
        return;
      }

      final loc = AppLocalizations.of(context);
      String languageCode = loc.locale.languageCode;
      String localeId = (languageCode == 'ar') ? 'ar-SA' : 'fr-FR';

      try {
        setState(() {
          _isListening = true;
          _lastWords = "";
          _sttStatus = "Écoute...";
        });

        await Future.delayed(const Duration(milliseconds: 200));

        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _lastWords = result.recognizedWords;
                _checkAnswer(_lastWords);
              });
            }
          },
          onSoundLevelChange: (level) {
            if (mounted) {
              setState(() {
                _soundLevel = level;
              });
            }
          },
          localeId: localeId,
          onDevice: false, 
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 10), 
          cancelOnError: false, 
          partialResults: true,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _sttStatus = "Erreur: $e";
          });
        }
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  void _checkAnswer(String words) {
    if (_scoredPages.contains(_currentPage)) return;

    List<String>? answers = _correctAnswers[_currentPage];
    if (answers == null) return;

    String normalize(String text) {
      return text.toLowerCase()
          .replaceAll(RegExp(r'[.,!?؟]'), ' ')
          .replaceAll(RegExp(r'[أإآ]'), 'ا')
          .replaceAll(RegExp(r'ة'), 'ه')
          .replaceAll(RegExp(r'[ى]'), 'ي')
          .trim();
    }

    String normalizedWords = normalize(words);

    for (var answer in answers) {
      String normalizedAnswer = normalize(answer);
      if (normalizedAnswer.isNotEmpty && normalizedWords.contains(normalizedAnswer)) {
        setState(() {
          _score++;
          _scoredPages.add(_currentPage);
        });
        _stopAndNavigate();
        break;
      }
    }
  }

  void _simulateCorrectAnswer() {
    // Hidden feature to test navigation/scoring on emulators
    List<String>? answers = _correctAnswers[_currentPage];
    if (answers != null && answers.isNotEmpty) {
      String firstAnswer = answers[0];
      print('Simulating correct answer: $firstAnswer');
      setState(() {
        _lastWords = firstAnswer;
        if (!_scoredPages.contains(_currentPage)) {
          _score++;
          _scoredPages.add(_currentPage);
        }
      });
      _stopAndNavigate();
    }
  }

  void _stopAndNavigate() async {
    if (_isListening) {
      setState(() => _isListening = false);
      await _speech.stop();
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentPage < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndFinish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    _stopwatch.stop();
    final duration = _stopwatch.elapsed;
    final timeSpent = "${duration.inMinutes}m ${duration.inSeconds % 60}s";

    try {
      if (widget.patientId != null) {
        await _firestoreService.saveTestResult(
          patientId: widget.patientId!,
          patientIdentifier: widget.patientIdentifier ?? "Unknown",
          score: _score,
          timeSpent: timeSpent,
          testName: "DO30",
        );
      }
      if (mounted) _showFinishDialog();
    } catch (e) {
      print("ERROR SAVING RESULT: $e");
      if (mounted) _showFinishDialog();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop();
    _speech.stop();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = loc.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            loc.translate('test_title'), 
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmation(),
            )
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _images.length,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_currentPage + 1} / ${_images.length}",
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _lastWords = ""; 
                  });
                  _speakPrompt();
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        spreadRadius: 5,
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      _images[index],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported, size: 80, color: Colors.grey);
                                      },
                                    ),
                                  ),
                                ),
                                if (_scoredPages.contains(index))
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Icon(Icons.check_circle, color: Colors.green, size: 40),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                            height: 80,
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Text(
                                  _lastWords.isEmpty ? "" : '"$_lastWords"',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: _scoredPages.contains(index) ? Colors.green : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_isListening && _lastWords.isEmpty)
                                  const SizedBox(
                                    height: 2,
                                    width: 100,
                                    child: LinearProgressIndicator(minHeight: 1),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isListening)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 70 + (_soundLevel * 2), // Pulse effect
                          height: 70 + (_soundLevel * 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.1 + (_soundLevel / 30).clamp(0.0, 0.4)),
                          ),
                        ),
                      GestureDetector(
                        onTap: _listen,
                        onLongPress: _simulateCorrectAnswer,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red : Colors.teal,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? Colors.red : Colors.teal).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isListening 
                      ? (isRtl ? "جاري الاستماع..." : "Écoute en cours...")
                      : (isRtl ? "اضغط للتحدث" : "Appuyez pour parler"),
                    style: GoogleFonts.cairo(color: _isListening ? Colors.red : Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    "Status: $_sttStatus",
                    style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 10),
                  ),
                ],
              ),
            ),
            if (_currentPage == _images.length - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.teal)
                  : ElevatedButton.icon(
                    onPressed: () => _saveAndFinish(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(loc.translate('finish_test'), style: GoogleFonts.cairo(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 15.0),
                child: Icon(Icons.swipe, color: Colors.teal, size: 25),
              ),
            const SizedBox(height: 10),
            if (!_isSaving)
              TextButton.icon(
                onPressed: () => _showQuitConfirmation(),
                icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                label: Text(
                  isRtl ? "خروج من الاختبار" : "Quitter le test",
                  style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showQuitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRtl ? "تنبيه" : "Attention", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          isRtl 
            ? "هل تريد حقًا الخروج؟ لن يتم حفظ تقدمك في الاختبار." 
            : "Voulez-vous vraiment quitter ? Votre progression ne sera pas enregistrée.", 
          style: GoogleFonts.cairo()
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isRtl ? "لا" : "Non", style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit test page
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(isRtl ? "خروج" : "Quitter", style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    _showQuitConfirmation();
  }

  void _showFinishDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          loc.testFinishedTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.testFinishedMsg, style: GoogleFonts.cairo()),
            const SizedBox(height: 20),
            // SCORE HIDDEN FROM PATIENT PER USER REQUEST
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(loc.mainMenu, style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  bool get isRtl => AppLocalizations.of(context).locale.languageCode == 'ar';
}
