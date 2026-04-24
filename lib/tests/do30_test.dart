import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../localization.dart';

class Do30Item {
  final String fileName;
  final List<String> solutionsFr;
  final List<String> solutionsAr;

  Do30Item(this.fileName, this.solutionsFr, this.solutionsAr);
}

class Do30TestPage extends StatefulWidget {
  final String patientDocId;
  final String patientIdentifier;

  const Do30TestPage({
    super.key,
    required this.patientDocId,
    required this.patientIdentifier,
  });

  @override
  State<Do30TestPage> createState() => _Do30TestPageState();
}

class _Do30TestPageState extends State<Do30TestPage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController();
  final Stopwatch _stopwatch = Stopwatch();

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isFinished = false; // NEW: Flag to prevent multiple saves
  bool _isSpeaking = false;
  String _spokenText = "";
  double _soundLevel = 0.0;
  bool _hasHeardWord = false;
  Timer? _guardianTimer;
  Timer? _nextPageTimer;
  final TextEditingController _textController =
      TextEditingController(); // MODIFIED: For text input answer

  int _currentIndex = 0;
  List<String> _transcriptions = List.filled(30, "");
  List<bool> _results = List.filled(30, false);

  final List<Do30Item> _items = [
    Do30Item(
      "01 Robinet.jpg",
      ["robinet"],
      ["سبالة", "شيش ما", "حنفية", "صنبور", "شيشما", "شيشمة"],
    ),
    Do30Item(
      "02 Parachute.jpg",
      ["parachute"],
      ["بارشيت", "باراشوت", "منطاد", "براشوت", "برشيد", "رشيد"],
    ),
    Do30Item(
      "03 Ancre.jpg",
      ["ancre"],
      ["مخطاف", "مقلاع", "علاق", "مختاف", "مختطف", "مختار", "خطاف", "خطّاف"],
    ),
    Do30Item("04 Domino.jpg", ["domino"], ["ديمينو", "دمينو", "دومينو"]),
    Do30Item(
      "05 Champignon.jpg",
      ["champignon", "fongus"],
      ["فطر", "شامبينيون", "شومبينيو"],
    ),
    Do30Item("06 Eléphant.jpg", ["elephant"], ["فيل"]),
    Do30Item("07 Ciseau.jpg", ["ciseau"], ["مقص"]),
    Do30Item("08 Maison.jpg", ["maison"], ["دار", "منزل"]),
    Do30Item(
      "09 Escargot.jpg",
      ["escargot"],
      ["حلزون", "قرز", "كرز", "ببوش", "ببوشة"],
    ),
    Do30Item("10 Tortue.jpg", ["tortue"], ["سلحفاة", "فكرون"]),
    Do30Item(
      "11 Kangourou.jpg",
      ["kangourou"],
      ["كنغر", "كنغرو", "كونغرو", "تنكر", "كنجر", "كونغو", "كونكرو"],
    ),
    Do30Item("12 Girafe.jpg", ["girafe"], ["زرافة"]),
    Do30Item("13 Chat.jpg", ["chat"], ["قط", "قطوس", "قطوس"]),
    Do30Item(
      "14 Rhinocéros.jpg",
      ["rhinoceros"],
      ["وحيد القرن", "كركدم", "كركدن", "ذو القرن", "القرن", "ذو القرم"],
    ),
    Do30Item("15 Papillon.jpg", ["papillon"], ["فراشة"]),
    Do30Item("16 Ecureuil.jpg", ["ecureuil"], ["سنجاب", "فار"]),
    Do30Item("17 Echelle.jpg", ["echelle"], ["سلوم", "سلم"]),
    Do30Item(
      "18 Cloche.jpg",
      ["cloche"],
      ["ناقوز", "ناقوس", "نيكوز", "نيقوز", "جرس", "نقود", "نيقود", "نيقوس"],
    ),
    Do30Item(
      "19 Hélicoptère.jpg",
      ["helicoptere"],
      ["طيارة", "طائرة", "هيليكوبتر", "هليكوبتر", "هليكوبتير", "مروحية", "مروحيه"],
    ),
    Do30Item("20 Crocodile.jpg", ["crocodile"], ["تمساح"]),
    Do30Item(
      "21 Penser.jpg",
      ["penser", "reflechir", "triste"],
      ["يفكر", "حزين", "يخمم", "يخم"],
    ),
    Do30Item("22 Tomber.jpg", ["tomber"], ["طايح", "يطيح", "طايه", "ولد", "راجل", "رجل", "واحد"]),
    Do30Item("23 Pleurer.jpg", ["pleurer"], ["يبكي", "ولد", "راجل", "رجل"]),
    Do30Item(
      "24 Escalader.jpg",
      ["escalader", "grimper"],
      [
        "يكعبش",
        "يتسلق",
        "جبل",
        "طالع",
        "بيكابش",
        "اكابش",
        "الكابش",
        "يطلع",
        "يكعبش",
        "بكعبش",
        "في كعبش",
        "ولد",
        "راجل",
        "رجل",
        "وليّد",
      ],
    ),
    Do30Item("25 Dormir.jpg", ["dormir"], ["راقد", "رقد", "ريقد", "يرقد", "راجل", "وليّد", "رجل نائم"]),
    Do30Item("26 Nager.jpg", ["nager"], ["يعوم", "يسبح", "يصبح", "راجل", "وليّد", "يوم", "واحد يوم"]),
    Do30Item("27 Courir.jpg", ["courir"], ["تجري", "طفله", "تفله", "امراه", "بنية", "تقفز", "تنقز", "نكز"]),
    Do30Item("29 Ecrir.jpg", ["ecrire"], ["تكتب", "طفله", "تفله", "امراه", "بنية"]),
    Do30Item(
      "29 Manger.jpg",
      ["manger"],
      ["تاكل", "تأكل", "طفله", "تفله", "امراه", "تيكل", "بنية"],
    ),
    Do30Item("30 Boire.jpg", ["boire"], ["تشرب", "طفله", "تفله", "امراه", "بنية", "يشرب"]),
  ];

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
    _micAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _micController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTestSequence();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopwatch.stop();
    _micController.dispose();
    _flutterTts.stop();
    _speech.stop();
    _guardianTimer?.cancel();
    _nextPageTimer?.cancel();
    _textController.dispose(); // MODIFIED: Clean up controller
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

  Future<void> _startTestSequence() async {
    if (_isSpeaking) return;

    final loc = AppLocalizations.of(context);
    setState(() {
      _isSpeaking = true;
      _spokenText = "";
    });

    await _flutterTts.setLanguage(
      loc.locale.languageCode == 'ar' ? 'ar' : 'fr-FR',
    );
    await _flutterTts.speak(loc.do30Instr);
  }

  void _startListening() async {
    _nextPageTimer
        ?.cancel(); // Cancel any pending transition if user wants to re-record
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint("STT Status: $status");
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        debugPrint("STT Error: $error");
        
        // Skip visual error for silence or common timeouts to let guardian restart silently
        bool isSilenceError = error.errorMsg == "error_no_match" || 
                             error.errorMsg == "error_speech_timeout";

        if (mounted && !isSilenceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur Microphone/STT: ${error.errorMsg}"),
              backgroundColor: Colors.orange,
            ),
          );
        }

        if (!isSilenceError) {
          setState(() => _isListening = false);
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
            _textController.text = _spokenText; // Fix 7: STT result writes into field
            if (_spokenText.isNotEmpty) {
              _hasHeardWord = true;
            }
            if (result.finalResult && _spokenText.isNotEmpty) {
              _evaluateCurrentAnswer();
            }
          });
        },
        localeId: AppLocalizations.of(context).locale.languageCode == 'ar'
            ? 'ar-SA'
            : null,
        onSoundLevelChange: (level) => setState(() => _soundLevel = level),
        pauseFor: const Duration(seconds: 30),
        cancelOnError: false,
      );

      _guardianTimer?.cancel();
      _guardianTimer = Timer.periodic(const Duration(seconds: 2), (t) {
        if (_isListening && !_speech.isListening) {
          debugPrint("Guardian: Restarting STT...");
          _startSttSession();
        }
      });
    }
  }

  void _startSttSession() {
    _speech.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
          _textController.text = _spokenText; // Fix 7: STT result writes into field
          if (result.finalResult && _spokenText.isNotEmpty) {
            _evaluateCurrentAnswer();
          }
        });
      },
      localeId: AppLocalizations.of(context).locale.languageCode == 'ar'
          ? 'ar-SA'
          : null,
      onSoundLevelChange: (level) => setState(() => _soundLevel = level),
      pauseFor: const Duration(seconds: 30),
      cancelOnError: false,
    );
  }

  void _evaluateCurrentAnswer() {
    if (_transcriptions[_currentIndex].isNotEmpty)
      return; // MODIFIED: Prevent double evaluation
    if (_spokenText.isEmpty) return;

    final loc = AppLocalizations.of(context);
    List<String> correctList = loc.locale.languageCode == 'ar'
        ? _items[_currentIndex].solutionsAr
        : _items[_currentIndex].solutionsFr;

    bool isCorrect = false;
    for (var correct in correctList) {
      if (_checkMatching(_spokenText, correct)) {
        isCorrect = true;
        break;
      }
    }

    setState(() {
      _transcriptions[_currentIndex] = _spokenText;
      _results[_currentIndex] = isCorrect;
      _isListening = false;
      _guardianTimer?.cancel();
    });


    _speech.stop();

    // AUTO-MOVE: Automatically move to next image IF the answer is CORRECT
    if (isCorrect) {
      _nextPageTimer?.cancel();
      _nextPageTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          if (_currentIndex < _items.length - 1) {
            _nextPage();
          } else {
            _finishTest();
          }
        }
      });
    }
  }

  bool _checkMatching(String spoken, String correct) {
    String s = _sanitize(spoken);
    String c = _sanitize(correct);

    if (s == c) return true;
    if (s.contains(c)) return true;

    return false;
  }

  String _sanitize(String text) {
    String s = text.toLowerCase();

    // Arabic-specific sanitization: Normalize Alif, Ya, etc.
    s = s.replaceAll(RegExp(r'[أإآ]'), 'ا');
    s = s.replaceAll(RegExp(r'[ة]'), 'ه');
    s = s.replaceAll(RegExp(r'[ى]'), 'ي');
    s = s.replaceAll(
      RegExp(r'[ڨق]'),
      'ق',
    ); // Treating 'G' and 'Q' as similar in Darija

    // Remove Arabic diacritics (Harakat)
    s = s.replaceAll(RegExp(r'[\u064B-\u0652]'), '');

    final articles = [
      'le ',
      'la ',
      'l\'',
      'les ',
      'un ',
      'une ',
      'des ',
      'ce ',
      'cette ',
      'cest ',
      'c\'est ',
    ];
    for (var a in articles) {
      s = s.replaceAll(a, '');
    }
    s = s.replaceAll(
      RegExp(r'[^\w\s\u0600-\u06FF]'),
      '',
    ); // Preserve Arabic chars
    return s.trim();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finishTest() async {
    if (_isFinished) return;
    setState(() => _isFinished = true);

    _stopwatch.stop();
    final String durationStr =
        "${(_stopwatch.elapsedMilliseconds / 1000).truncate()} s";

    final int finalScore = _results.where((r) => r == true).length;
    final int finalErrors = 30 - finalScore;

    try {
      await _firestoreService.saveTestResult(
        patientDocId: widget.patientDocId,
        patientIdentifier: widget.patientIdentifier,
        score: finalScore.toDouble(),
        totalDuration: durationStr,
        testType: 'DO-30',
        metadata: {
          'errors': finalErrors,
          'transcriptions': _transcriptions,
          'results': _results,
          'tableFormat':
              _buildTableFormat(), // MODIFIED: Standard scoring table format
        },
      );
    } catch (e) {
      debugPrint("Error saving result: $e");
    }

    if (!mounted) return;
    _showSummary();
  }

  void _showSummary() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
            // Fix 8a: Remove total score display
            // Text(
            //   "${loc.resultPrefix} ${30 - _errors} / 30",
            //   style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            // ),
            // Text(
            //   "${loc.timePrefix} ${_stopwatch.elapsed.inSeconds} s",
            //   style: GoogleFonts.cairo(),
            // ),
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

  // MODIFIED: New helper for structured results
  List<Map<String, dynamic>> _buildTableFormat() {
    final loc = AppLocalizations.of(context);
    return List.generate(_items.length, (i) {
      return {
        'numero': i + 1,
        'reponseAttendueFr': _items[i].solutionsFr.first,
        'reponseAttendueAr': _items[i].solutionsAr.first,
        'reponsePatientFr': loc.locale.languageCode != 'ar'
            ? _transcriptions[i]
            : "",
        'reponsePatientAr': loc.locale.languageCode == 'ar'
            ? _transcriptions[i]
            : "",
        'correct': _results[i],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          loc.do30Title,
          style: GoogleFonts.cairo(color: Colors.black, fontSize: 18),
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
                loc.do30Instr,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const BouncingScrollPhysics(), // MODIFIED: Free swipe navigation now allowed
                onPageChanged: (index) {
                  _nextPageTimer?.cancel();
                  setState(() {
                    _currentIndex = index;
                    _spokenText = "";
                    // If we already have a transcription for this page, show the Next button
                    _hasHeardWord = _transcriptions[index].isNotEmpty;
                  });
                  _startListening();
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.teal.shade100,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/images/do30/${_items[index].fileName}',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isListening)
                        ScaleTransition(
                          scale: _micAnimation,
                          child: Container(
                            padding: EdgeInsets.all(
                              12 + (_soundLevel > 0 ? _soundLevel : 0),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.teal,
                              size: 32,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.mic_none,
                            color: Colors.grey,
                            size: 32,
                          ),
                          onPressed: _startListening,
                        ),
                      const SizedBox(
                        width: 16,
                      ), // MODIFIED: Space for text input
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: GoogleFonts.cairo(fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                "Écrire la réponse...", // MODIFIED: Text input fallback hint
                            isDense: true,
                            hintStyle: GoogleFonts.cairo(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.teal),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.teal),
                        onPressed: () {
                          // MODIFIED: Text submission logic
                          final typed = _textController.text.trim();
                          if (typed.isNotEmpty &&
                              _transcriptions[_currentIndex].isEmpty) {
                            setState(() {
                              _spokenText = typed;
                              _textController.clear();
                              _evaluateCurrentAnswer();
                              _hasHeardWord = true;
                            });
                            // Auto-advance after 500ms for text input
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (!mounted) return;
                                if (_currentIndex < _items.length - 1) {
                                  _nextPage();
                                } else {
                                  _finishTest();
                                }
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  // Fix 7: Text widget showing raw STT output below field is removed
                  // Text(
                  //   _spokenText.isEmpty
                  //       ? (_isListening ? loc.listening : "")
                  //       : "\"$_spokenText\"",
                  //   style: GoogleFonts.cairo(
                  //     fontStyle: FontStyle.italic,
                  //     color: Colors.black87,
                  //     fontSize: 12,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                ],
              ),
            ),
            // Fix 8b: Re-record/retry button
            if (_currentIndex < _items.length)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.replay_circle_filled, color: Colors.teal, size: 44),
                    tooltip: loc.clearAndRetry,
                    onPressed: () {
                      setState(() {
                        _textController.clear();
                        _spokenText = "";
                        _hasHeardWord = false;
                        _transcriptions[_currentIndex] = ""; // Allow retry if evaluated
                      });
                      _startListening();
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.do30ImageCounter.replaceAll(
                      '{}',
                      '${_currentIndex + 1}',
                    ),
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_hasHeardWord || _transcriptions[_currentIndex].isNotEmpty)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: ElevatedButton.icon(
                            onPressed: _isFinished ? null : () {
                              _guardianTimer?.cancel();
                              _speech.stop();
                              if (_currentIndex < _items.length - 1) {
                                _nextPage();
                              } else {
                                _finishTest();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              loc.nextBtn,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
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
