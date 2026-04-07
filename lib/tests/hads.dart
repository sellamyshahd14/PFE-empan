import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../localization.dart';

class TestHADS extends StatefulWidget {
  final String patientDocId;
  final String patientIdentifier;

  const TestHADS({
    super.key,
    required this.patientDocId,
    required this.patientIdentifier,
  });

  @override
  State<TestHADS> createState() => _TestHADSState();
}

class _TestHADSState extends State<TestHADS> {
  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'type': 'A',
      'key': 'hads_q1',
      'answers': [
        {'score': 3, 'aKey': 'hads_q1_a3'},
        {'score': 2, 'aKey': 'hads_q1_a2'},
        {'score': 1, 'aKey': 'hads_q1_a1'},
        {'score': 0, 'aKey': 'hads_q1_a0'},
      ],
    },
    {
      'type': 'D',
      'key': 'hads_q2',
      'answers': [
        {'score': 0, 'aKey': 'hads_q2_a0'},
        {'score': 1, 'aKey': 'hads_q2_a1'},
        {'score': 2, 'aKey': 'hads_q2_a2'},
        {'score': 3, 'aKey': 'hads_q2_a3'},
      ],
    },
    {
      'type': 'A',
      'key': 'hads_q3',
      'answers': [
        {'score': 3, 'aKey': 'hads_q3_a3'},
        {'score': 2, 'aKey': 'hads_q3_a2'},
        {'score': 1, 'aKey': 'hads_q3_a1'},
        {'score': 0, 'aKey': 'hads_q3_a0'},
      ],
    },
    {
      'type': 'D',
      'key': 'hads_q4',
      'answers': [
        {'score': 0, 'aKey': 'hads_q4_a0'},
        {'score': 1, 'aKey': 'hads_q4_a1'},
        {'score': 2, 'aKey': 'hads_q4_a2'},
        {'score': 3, 'aKey': 'hads_q4_a3'},
      ],
    },
    {
      'type': 'A',
      'key': 'hads_q5',
      'answers': [
        {'score': 3, 'aKey': 'hads_q5_a3'},
        {'score': 2, 'aKey': 'hads_q5_a2'},
        {'score': 1, 'aKey': 'hads_q5_a1'},
        {'score': 0, 'aKey': 'hads_q5_a0'},
      ],
    },
    {
      'type': 'D',
      'key': 'hads_q6',
      'answers': [
        {'score': 3, 'aKey': 'hads_q6_a3'},
        {'score': 2, 'aKey': 'hads_q6_a2'},
        {'score': 1, 'aKey': 'hads_q6_a1'},
        {'score': 0, 'aKey': 'hads_q6_a0'},
      ],
    },
    {
      'type': 'A',
      'key': 'hads_q7',
      'answers': [
        {'score': 0, 'aKey': 'hads_q7_a0'},
        {'score': 1, 'aKey': 'hads_q7_a1'},
        {'score': 2, 'aKey': 'hads_q7_a2'},
        {'score': 3, 'aKey': 'hads_q7_a3'},
      ],
    },
    {
      'type': 'D',
      'key': 'hads_q8',
      'answers': [
        {'score': 3, 'aKey': 'hads_q8_a3'},
        {'score': 2, 'aKey': 'hads_q8_a2'},
        {'score': 1, 'aKey': 'hads_q8_a1'},
        {'score': 0, 'aKey': 'hads_q8_a0'},
      ],
    },
    {
      'type': 'A',
      'key': 'hads_q9',
      'answers': [
        {'score': 0, 'aKey': 'hads_q9_a0'},
        {'score': 1, 'aKey': 'hads_q9_a1'},
        {'score': 2, 'aKey': 'hads_q9_a2'},
        {'score': 3, 'aKey': 'hads_q9_a3'},
      ],
    },
    {
      'type': 'D',
      'key': 'hads_q10',
      'answers': [
        {'score': 3, 'aKey': 'hads_q10_a3'},
        {'score': 2, 'aKey': 'hads_q10_a2'},
        {'score': 1, 'aKey': 'hads_q10_a1'},
        {'score': 0, 'aKey': 'hads_q10_a0'},
      ],
    },
    {
      'type': 'A',
      'key': 'hads_q11',
      'answers': [
        {'score': 3, 'aKey': 'hads_q11_a3'},
        {'score': 2, 'aKey': 'hads_q11_a2'},
        {'score': 1, 'aKey': 'hads_q11_a1'},
        {'score': 0, 'aKey': 'hads_q11_a0'},
      ],
    },
    {
      'type': 'D',
      'key': 'hads_q12',
      'answers': [
        {'score': 0, 'aKey': 'hads_q12_a0'},
        {'score': 1, 'aKey': 'hads_q12_a1'},
        {'score': 2, 'aKey': 'hads_q12_a2'},
        {'score': 3, 'aKey': 'hads_q12_a3'},
      ],
    },
    {
      'type': 'A',
      'key': 'hads_q13',
      'answers': [
        {'score': 3, 'aKey': 'hads_q13_a3'},
        {'score': 2, 'aKey': 'hads_q13_a2'},
        {'score': 1, 'aKey': 'hads_q13_a1'},
        {'score': 0, 'aKey': 'hads_q13_a0'},
      ],
    },
    {
      'type': 'D',
      'key': 'hads_q14',
      'answers': [
        {'score': 0, 'aKey': 'hads_q14_a0'},
        {'score': 1, 'aKey': 'hads_q14_a1'},
        {'score': 2, 'aKey': 'hads_q14_a2'},
        {'score': 3, 'aKey': 'hads_q14_a3'},
      ],
    },
  ];

  void _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() => _isSaving = true);

      int scoreA = 0;
      int scoreD = 0;

      for (int i = 0; i < _questions.length; i++) {
        final score = _answers[i] ?? 0;
        if (_questions[i]['type'] == 'A') {
          scoreA += score;
        } else {
          scoreD += score;
        }
      }

      try {
        await _firestoreService.saveTestResult(
          patientDocId: widget.patientDocId,
          patientIdentifier: widget.patientIdentifier,
          scoreA: scoreA.toDouble(),
          scoreD: scoreD.toDouble(),
          testType: "HADS",
        );
      } catch (e) {
        debugPrint("Error saving result: $e");
      }

      setState(() => _isSaving = false);
      if (mounted) {
        final loc = AppLocalizations.of(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              loc.testFinishedTitle,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: Text(loc.testFinishedMsg, style: GoogleFonts.cairo()),
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
    }
  }

  bool _showIntro = true;

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final loc = AppLocalizations.of(context);

    if (_showIntro) {
      return _buildIntroPage(loc);
    }

    final currentQuestion = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _questions.length - 1;
    final selectedAnswerScore = _answers[_currentIndex];

    // Determine directionality based on locale
    final isRtl = loc.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            loc.hadsTestTitle,
            style: GoogleFonts.cairo(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1}/${_questions.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _questions.length,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  loc.hadsInstruction,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  loc.translate(currentQuestion['key']),
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    itemCount: (currentQuestion['answers'] as List).length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final answer =
                          (currentQuestion['answers'] as List)[index];
                      final isSelected = selectedAnswerScore == answer['score'];

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _answers[_currentIndex] = answer['score'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.teal.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.teal
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: answer['score'],
                                groupValue: selectedAnswerScore,
                                onChanged: (value) {
                                  setState(() {
                                    _answers[_currentIndex] = value!;
                                  });
                                },
                                activeColor: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loc.translate(answer['aKey']),
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
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
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: selectedAnswerScore != null
                        ? _nextQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[500],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      isLastQuestion ? loc.finishTest : loc.nextBtn,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroPage(AppLocalizations loc) {
    final isRtl = loc.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            loc.hadsTestTitle,
            style: GoogleFonts.cairo(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loc.hadsIntroText,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[900],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showIntro = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      loc.translate('start_test'),
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
