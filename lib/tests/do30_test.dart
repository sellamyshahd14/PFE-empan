import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isFinished = false;
  bool _isSpeaking = false;
  bool _isInitializing = false;
  String _spokenText = "";
  String? _currentResultDocId;
  Timer? _guardianTimer;
  Timer? _nextPageTimer;
  final TextEditingController _textController = TextEditingController();

  int _currentIndex = 0;
  bool _showNextButton = false;
  final List<String> _transcriptions = List.filled(30, "");
  final List<bool> _results = List.filled(30, false);

  final List<Do30Item> _items = [
    Do30Item(
      "01 Robinet.jpg",
      ["robinet"],
      ["سبالة", "سبيله", "سبله", "صبالة", "شيش ما", "حنفية", "صنبور", "شيشما", "شيشمة"],
    ),
    Do30Item(
      "02 Parachute.jpg",
      ["parachute"],
      ["بارشيت", "باراشوت", "مظلة", "منطاد", "براشوت", "برشيد", "رشيد"],
    ),
    Do30Item(
      "03 Ancre.jpg",
      ["ancre"],
      [
        "مخطاف",
        "مخطوف",
        "مخطف",
        "شنڨال",
        "شنقال",
        "مقلع",
        "مقلاع",
        "علاق",
        "مختاف",
        "مختطف",
        "مختار",
        "خطاف",
        "خطّاف",
      ],
    ),
    Do30Item(
      "04 Domino.jpg",
      ["domino"],
      ["دومينو", "نيمينو", "ديمينو", "دمينو", "ديميلو"],
    ),
    Do30Item(
      "05 Champignon.jpg",
      ["champignon", "fongus"],
      ["شامبينيون", "شامبنيو", "خطر", "مظلة", "باراسول", "براسول", "باريسول", "فطر", "شومبينيو"],
    ),
    Do30Item("06 Eléphant.jpg", ["elephant"], ["فيل"]),
    Do30Item("07 Ciseau.jpg", ["ciseau"], ["مقص"]),
    Do30Item("08 Maison.jpg", ["maison"], ["منزل", "دار", "الدار", "بنڨالو", "مزرعة"]),
    Do30Item(
      "09 Escargot.jpg",
      ["escargot"],
      ["حلزون", "قرز", "كرز", "ببوش", "لبوش", "ببوشة", "حلزونة"],
    ),
    Do30Item("10 Tortue.jpg", ["tortue"], ["سلحفاة", "فكرون"]),
    Do30Item(
      "11 Kangourou.jpg",
      ["kangourou"],
      ["كنغر", "كنغرو", "كونغرو", "تنكر", "كنجر", "كونغو", "كونكرو", "تنظر"],
    ),
    Do30Item("12 Girafe.jpg", ["girafe"], ["زرافة", "غزالة", "غزيله"]),
    Do30Item("13 Chat.jpg", ["chat"], ["قط", "قطوس", "قطوس"]),
    Do30Item(
      "14 Rhinocéros.jpg",
      ["rhinoceros"],
      [
        "وحيد القرن",
        "كركدم",
        "كركدن",
        "كركدا",
        "بو قرن",
        "القرن",
        "ذو القرم",
        "خنزير",
        "فرس النهر",
      ],
    ),
    Do30Item("15 Papillon.jpg", ["papillon"], ["فراشة"]),
    Do30Item(
      "16 Ecureuil.jpg",
      ["ecureuil"],
      ["سنجاب", "قط وحشي", "قطوس", "قطوس وحشي", "فار", "ارنب", "ارنوبة"],
    ),
    Do30Item("17 Echelle.jpg", ["echelle"], ["سلم", "سلوم"]),
    Do30Item(
      "18 Cloche.jpg",
      ["cloche"],
      [
        "جرس",
        "ناقوس",
        "ناقوز",
        "نيكوز",
        "نيقوز",
        "نقود",
        "نيقود",
        "نيقوس",
        "ناكوز",
      ],
    ),
    Do30Item(
      "19 Hélicoptère.jpg",
      ["helicoptere"],
      [
        "مروحية",
        "هيليكوبتر",
        "طيارة",
        "طائرة",
        "هليكوبتر",
        "هليكوبتير",
        "مروحيه",
      ],
    ),
    Do30Item("20 Crocodile.jpg", ["crocodile"], ["تمساح"]),
    Do30Item(
      "21 Penser.jpg",
      ["penser", "reflechir", "triste"],
      ["يفكر", "وليدي فكر", "حزين", "يخمم", "يخم", "خمم"],
    ),
    Do30Item(
      "22 Tomber.jpg",
      ["tomber"],
      [
        "يسقط",
        "سقط يسقط من الدرج",
        "طايح",
        "شاب يسقط",
        "هابط الدروج",
        "دروج",
        "تكربص",
        "يطيح",
        "طايه",
        "ولد",
        "راجل",
        "رجل",
        "واحد",
      ],
    ),
    Do30Item("23 Pleurer.jpg", ["pleurer"], ["يبكي", "حزين", "ولد", "راجل", "رجل"]),
    Do30Item(
      "24 Escalader.jpg",
      ["escalader", "grimper"],
      [
        "يتسلق",
        "يكعبش",
        "الكعبش",
        "الكعبس",
        "جبل",
        "طالع",
        "بيكابش",
        "ايكابش",
        "اكابش",
        "الكابش",
        "يطلع",
        "بكعبش",
        "في كعبش",
        "ولد",
        "راجل",
        "رجل",
        "وليّد",
      ],
    ),
    Do30Item(
      "25 Dormir.jpg",
      ["dormir"],
      [
        "ينام",
        "رجل ينام",
        "راقد",
        "نائم",
        "ولد نائم",
        "رقد",
        "ريقد",
        "يرقد",
        "راجل",
        "وليّد",
        "رجل nائم",
      ],
    ),
    Do30Item(
      "26 Nager.jpg",
      ["nager"],
      ["يسبح", "يعوم", "يصبح", "راجل", "وليّد", "يوم", "واحد يوم"],
    ),
    Do30Item(
      "27 Courir.jpg",
      ["courir"],
      [
        "تجري",
        "يجري",
        "تركض",
        "مرا تهرب",
        "مرا هاربة",
        "هاربة",
        "طفله",
        "تفله",
        "امراه",
        "بنية",
        "تقفز",
        "تنقز",
        "نكز",
      ],
    ),
    Do30Item(
      "29 Ecrir.jpg",
      ["ecrire"],
      ["تكتب", "تقرا", "يقرا", "طفله", "تفله", "امراه", "بنية"],
    ),
    Do30Item(
      "29 Manger.jpg",
      ["manger"],
      [
        "تأكل",
        "تتناول الفطور",
        "تاكل",
        "طفله",
        "تفله",
        "امراه",
        "تيكل",
        "بنية",
      ],
    ),
    Do30Item(
      "30 Boire.jpg",
      ["boire"],
      ["تشرب", "طفله", "تفله", "امراه", "بنية", "يشرب"],
    ),
  ];

  late AnimationController _micController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    // Enable immersive mode (hide navigation bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _stopwatch.stop();
    _micController.dispose();
    _flutterTts.stop();
    _speech.stop();
    _nextPageTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    await Permission.microphone.request();
  }

  void _initTts() async {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _startListening();
      }
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

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _startListening() async {
    if (_isInitializing) return;
    _nextPageTimer?.cancel();
    
    _isInitializing = true;
    
    // Ensure we stop before starting
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);

    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint("STT Status: $status");
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() {
              _isListening = false;
              _micController.stop();
              _micController.value = 1.0; // Reset scale
            });
          }
          // Restart after a small delay if test is not finished and not speaking instruction
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isFinished && !_isSpeaking && !_isListening) {
              _startListening();
            }
          });
        }
      },
      onError: (error) {
        debugPrint("STT Error: ${error.errorMsg}");
        _isInitializing = false;
        bool isSilenceError =
            error.errorMsg == "error_no_match" ||
            error.errorMsg == "error_speech_timeout";
        
        if (mounted && !isSilenceError) {
          // For persistent errors, try a fresh restart after a delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && !_isFinished) _startListening();
          });
        }
      },
    );

    _isInitializing = false;

    if (available) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _micController.repeat(reverse: true);
        });
      }
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _spokenText = result.recognizedWords;
              _textController.text = _spokenText;
              if (result.finalResult && _spokenText.isNotEmpty) {
                _evaluateCurrentAnswer(isManual: false);
              }
            });
          }
        },
        localeId: AppLocalizations.of(context).locale.languageCode == 'ar'
            ? 'ar-TN'
            : null,
        onSoundLevelChange: (level) {},
        pauseFor: const Duration(seconds: 30),
        listenFor: const Duration(seconds: 60),
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );

      _guardianTimer?.cancel();
      _guardianTimer = Timer.periodic(const Duration(seconds: 2), (t) {
        if (_isListening && !_speech.isListening) {
          _startSttSession();
        }
      });
    }
  }

  void _startSttSession() {
    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _spokenText = result.recognizedWords;
            _textController.text = _spokenText;
            if (result.finalResult && _spokenText.isNotEmpty) {
              _evaluateCurrentAnswer(isManual: false);
            }
          });
        }
      },
      localeId: AppLocalizations.of(context).locale.languageCode == 'ar'
          ? 'ar-SA'
          : null,
      onSoundLevelChange: (level) {
        // Level change ignored
      },
      pauseFor: const Duration(seconds: 30),
      cancelOnError: false,
    );
  }

  void _evaluateCurrentAnswer({required bool isManual}) {
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

    if (mounted) {
      setState(() {
        _transcriptions[_currentIndex] = _spokenText;
        _results[_currentIndex] = isCorrect;
        _isListening = false;
        _guardianTimer?.cancel();
        
        // Logic for auto-advance or next button
        if (isCorrect || isManual) {
          _showNextButton = false;
          _nextPageTimer?.cancel();
          _nextPageTimer = Timer(const Duration(milliseconds: 600), () {
            if (mounted) {
              if (_currentIndex < _items.length - 1) {
                _nextPage();
              } else {
                _finishTest();
              }
            }
          });
        } else {
          // Wrong vocal response -> Show the Next button manually
          _showNextButton = true;
        }
      });
    }

    _speech.stop();
    _saveProgress();
  }

  bool _checkMatching(String input, String solution) {
    String cleanInput = _sanitize(input);
    String cleanSolution = _sanitize(solution);

    if (cleanInput == cleanSolution) return true;

    // Fuzzy matching using Levenshtein distance
    int distance = _levenshtein(cleanInput, cleanSolution);
    
    // Tolerance: 1 char for short words (<= 5 chars), 2 chars for longer words
    int tolerance = cleanSolution.length <= 5 ? 1 : 2;
    
    return distance <= tolerance;
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  String _sanitize(String text) {
    if (text.trim().isEmpty) return "EMPTY_INPUT";
    String s = text.toLowerCase().trim();
    // Remove Arabic diacritics
    s = s.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    // Normalize Arabic
    s = s.replaceAll(RegExp(r'[أإآا]'), 'ا');
    s = s.replaceAll(RegExp(r'[ةه]'), 'ه');
    s = s.replaceAll(RegExp(r'[ىي]'), 'ي');
    s = s.replaceAll(RegExp(r'[ڨقك]'), 'ق'); 
    // Remove non-word characters but keep spaces and Arabic blocks
    s = s.replaceAll(RegExp(r'[^\w\s\u0621-\u064A\u0671-\u06D3]'), '');
    String finalResult = s.trim();
    return finalResult.isEmpty ? "EMPTY_INPUT" : finalResult;
  }

  void _nextPage() {
    if (mounted) {
      setState(() {
        _currentIndex++;
        _spokenText = "";
        _textController.clear();
        _isListening = false;
        _showNextButton = false;
      });
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _startListening();
  }

  Future<void> _saveProgress() async {
    final int totalItems = _items.length;
    final int correctAnswers = _results.where((r) => r).length;

    // Calculate duration in MM:SS
    final duration = _stopwatch.elapsed;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    _currentResultDocId = await _firestoreService.saveTestResult(
      docId: _currentResultDocId,
      patientDocId: widget.patientDocId,
      patientIdentifier: widget.patientIdentifier,
      testType: "DO-30",
      score: correctAnswers.toDouble(),
      totalDuration: durationStr,
      metadata: {
        'currentIndex': _currentIndex,
        'totalItems': totalItems,
        'isPartial': true,
        'tableFormat': _buildTableFormat(),
      },
    );
  }

  Future<void> _finishTest() async {
    if (_isFinished) return;
    if (mounted) {
      setState(() {
        _isFinished = true;
        _isListening = false;
      });
    }
    _speech.stop();
    _guardianTimer?.cancel();

    final int correctAnswers = _results.where((r) => r).length;

    // Calculate final duration
    final duration = _stopwatch.elapsed;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    await _firestoreService.saveTestResult(
      docId: _currentResultDocId,
      patientDocId: widget.patientDocId,
      patientIdentifier: widget.patientIdentifier,
      testType: "DO-30",
      score: correctAnswers.toDouble(),
      totalDuration: durationStr,
      metadata: {
        'totalItems': _items.length,
        'tableFormat': _buildTableFormat(),
        'isPartial': false,
      },
    );

    if (mounted) {
      setState(() {}); // Refresh for finish view
    }
  }

  List<Map<String, dynamic>> _buildTableFormat() {
    return List.generate(_items.length, (i) {
      return {
        'numero': i + 1,
        'reponseAttendueFr': _items[i].solutionsFr.first,
        'reponseAttendueAr': _items[i].solutionsAr.first,
        'reponsePatientFr': _transcriptions[i],
        'reponsePatientAr': _transcriptions[i],
        'correct': _results[i],
      };
    });
  }

  void _handleManualSubmit(String val) {
    if (mounted) {
      setState(() {
        _spokenText = val;
        _textController.text = val;
      });
    }
    _evaluateCurrentAnswer(isManual: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildFinishView(context);

    final loc = AppLocalizations.of(context);
    final bool isArabic = loc.locale.languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.do30Title, style: GoogleFonts.cairo()),
        backgroundColor: Colors.teal,
        actions: [
          if (_showNextButton)
            TextButton.icon(
              onPressed: _nextPage,
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              label: Text(
                isArabic ? "التالي" : "Suivant",
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _items.length,
            backgroundColor: Colors.teal.shade50,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "assets/images/do30/${_items[index].fileName}",
                            fit: BoxFit.contain,
                            errorBuilder: (context, obj, stack) => const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Fix for RTL display of X / Y counter
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          "${index + 1} / ${_items.length}",
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          onChanged: (v) => setState(() => _spokenText = v),
                          decoration: InputDecoration(
                            hintText: isArabic ? "اكتب إجابتك هنا" : loc.translate('type_response_hint'),
                            hintStyle: GoogleFonts.cairo(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _evaluateCurrentAnswer(isManual: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          isArabic ? "تأكيد" : loc.translate('validate'),
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (mounted) {
                            setState(() {
                              _spokenText = "";
                              _textController.clear();
                            });
                          }
                          _stopListening();
                          _startListening();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.refresh, color: Colors.teal, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSpeaking ? null : _startListening,
                        child: ScaleTransition(
                          scale: _isListening ? _micAnimation : const AlwaysStoppedAnimation(1.0),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                _isListening ? Colors.red.shade600 : Colors.teal.shade400,
                            child: Icon(
                               _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: isArabic ? "لا أعرف" : loc.translate('do30_dont_know'),
                          color: Colors.grey.shade600,
                          onTap: () => _handleManualSubmit("[NE CONNAIT PAS]"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          label: isArabic ? "أعرفه و نسيت اسمه" : loc.translate('do30_forgot'),
                          color: Colors.orange.shade800,
                          onTap: () => _handleManualSubmit("[OUBLI DU NOM]"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishView(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            Text(
              loc.locale.languageCode == 'ar' ? "أحسنت ! لقد انتهى الاختبار" : "Bravo ! Test terminé",
              style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                loc.locale.languageCode == 'ar' ? "إنهاء" : "Terminer",
                style: GoogleFonts.cairo(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
