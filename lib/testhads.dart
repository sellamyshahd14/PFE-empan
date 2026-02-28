import 'package:flutter/material.dart';

class TestHADS extends StatefulWidget {
  const TestHADS({super.key});

  @override
  State<TestHADS> createState() => _TestHADSState();
}

class _TestHADSState extends State<TestHADS> {
  int _currentIndex = 0;
  final Map<int, int> _answers = {};

  // A = Anxiety, D = Depression
  final List<Map<String, dynamic>> _questions = [
    {
      'type': 'A',
      'question': 'Je me sens tendu ou énervé',
      'answers': [
        {'text': 'La plupart du temps', 'score': 3},
        {'text': 'Souvent', 'score': 2},
        {'text': 'De temps en temps', 'score': 1},
        {'text': 'Jamais', 'score': 0},
      ],
    },
    {
      'type': 'D',
      'question': 'Je prends plaisir aux mêmes choses qu\'autrefois',
      'answers': [
        {'text': 'Oui, tout autant', 'score': 0},
        {'text': 'Pas autant', 'score': 1},
        {'text': 'Un peu seulement', 'score': 2},
        {'text': 'Presque plus', 'score': 3},
      ],
    },
    {
      'type': 'A',
      'question':
          'J\'ai une sensation de peur comme si quelque chose d\'horrible allait m\'arriver',
      'answers': [
        {'text': 'Oui, très nettement', 'score': 3},
        {'text': 'Oui, mais ce n\'est pas trop grave', 'score': 2},
        {'text': 'Un peu, mais cela ne m\'inquiète pas', 'score': 1},
        {'text': 'Pas du tout', 'score': 0},
      ],
    },
    {
      'type': 'D',
      'question': 'Je ris facilement et vois le bon côté des choses',
      'answers': [
        {'text': 'Autant que par le passé', 'score': 0},
        {'text': 'Plus autant qu\'avant', 'score': 1},
        {'text': 'Vraiment moins qu\'avant', 'score': 2},
        {'text': 'Plus du tout', 'score': 3},
      ],
    },
    {
      'type': 'A',
      'question': 'Je me fais du souci',
      'answers': [
        {'text': 'Très souvent', 'score': 3},
        {'text': 'Assez souvent', 'score': 2},
        {'text': 'Occasionnellement', 'score': 1},
        {'text': 'Très occasionnellement', 'score': 0},
      ],
    },
    {
      'type': 'D',
      'question': 'Je suis de bonne humeur',
      'answers': [
        {'text': 'Jamais', 'score': 3},
        {'text': 'Rarement', 'score': 2},
        {'text': 'Assez souvent', 'score': 1},
        {'text': 'La plupart du temps', 'score': 0},
      ],
    },
    {
      'type': 'A',
      'question':
          'Je peux rester tranquillement assis à ne rien faire et me sentir décontracté',
      'answers': [
        {'text': 'Oui, quoi qu\'il arrive', 'score': 0},
        {'text': 'Oui, en général', 'score': 1},
        {'text': 'Rarement', 'score': 2},
        {'text': 'Parfois', 'score': 3},
      ],
    },
    {
      'type': 'D',
      'question': 'J\'ai l\'impression de fonctionner au ralenti',
      'answers': [
        {'text': 'Presque toujours', 'score': 3},
        {'text': 'Très souvent', 'score': 2},
        {'text': 'Parfois', 'score': 1},
        {'text': 'Jamais', 'score': 0},
      ],
    },
    {
      'type': 'A',
      'question': 'J\'éprouve des sensations de peur et j\'ai l\'estomac noué',
      'answers': [
        {'text': 'Jamais', 'score': 0},
        {'text': 'Parfois', 'score': 1},
        {'text': 'Assez souvent', 'score': 2},
        {'text': 'Très souvent', 'score': 3},
      ],
    },
    {
      'type': 'D',
      'question': 'Je ne m\'intéresse plus à mon apparence',
      'answers': [
        {'text': 'Plus du tout', 'score': 3},
        {
          'text': 'Je n\'y accorde pas autant d\'attention que je le devrais',
          'score': 2,
        },
        {
          'text': 'Il se peut que je n\'y fasse plus autant attention',
          'score': 1,
        },
        {'text': 'J\'y prête autant d\'attention que par le passé', 'score': 0},
      ],
    },
    {
      'type': 'A',
      'question': 'J\'ai la bougeotte et n\'arrive pas à tenir en place',
      'answers': [
        {'text': 'Oui, c\'est tout à fait le cas', 'score': 3},
        {'text': 'Un peu', 'score': 2},
        {'text': 'Pas tellement', 'score': 1},
        {'text': 'Pas du tout', 'score': 0},
      ],
    },
    {
      'type': 'D',
      'question': 'Je me réjouis d\'avance à l\'idée de faire certaines choses',
      'answers': [
        {'text': 'Autant qu\'avant', 'score': 0},
        {'text': 'Un peu moins qu\'avant', 'score': 1},
        {'text': 'Bien moins qu\'avant', 'score': 2},
        {'text': 'Presque jamais', 'score': 3},
      ],
    },
    {
      'type': 'A',
      'question': 'J\'éprouve des sensations soudaines de panique',
      'answers': [
        {'text': 'Vraiment très souvent', 'score': 3},
        {'text': 'Assez souvent', 'score': 2},
        {'text': 'Pas très souvent', 'score': 1},
        {'text': 'Jamais', 'score': 0},
      ],
    },
    {
      'type': 'D',
      'question':
          'Je peux prendre plaisir à un bon livre ou à une bonne émission radio ou de télévision',
      'answers': [
        {'text': 'Souvent', 'score': 0},
        {'text': 'Parfois', 'score': 1},
        {'text': 'Rarement', 'score': 2},
        {'text': 'Très rarement', 'score': 3},
      ],
    },
  ];

  String _getInterpretation(int score) {
    if (score <= 7) return 'Symptomatologie normale';
    if (score <= 10) return 'Symptomatologie douteuse';
    return 'Symptomatologie certaine'; // 11+
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Calculate split scores
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

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Résultats HADS'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Anxiété (A): $scoreA / 21'),
                Text(
                  _getInterpretation(scoreA),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Dépression (D): $scoreD / 21'),
                Text(
                  _getInterpretation(scoreD),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally reset or navigate away
                setState(() {
                  _currentIndex = 0;
                  _answers.clear();
                });
              },
              child: const Text('Recommencer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // If you wanted to exit the screen, you'd use Navigator.of(context).pop() again here
                // But since it's the home screen in main.dart, we just close the dialog.
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final isLastQuestion = _currentIndex == _questions.length - 1;
    final selectedAnswerScore = _answers[_currentIndex];

    // Optional: Determine category title
    // final category = currentQuestion['type'] == 'A' ? 'Anxiété' : 'Dépression';

    return Scaffold(
      appBar: AppBar(title: const Text('Echelle HADS'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1}/${_questions.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                // Uncomment if you want to show the user which category it is (usually hidden in blind tests though)
                // Text(category, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              currentQuestion['question'],
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: (currentQuestion['answers'] as List).map((answer) {
                  return RadioListTile<int>(
                    title: Text(answer['text']),
                    value: answer['score'],
                    groupValue: selectedAnswerScore,
                    onChanged: (value) {
                      setState(() {
                        _answers[_currentIndex] = value!;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: selectedAnswerScore != null ? _nextQuestion : null,
              child: Text(isLastQuestion ? 'Terminer' : 'Suivant'),
            ),
          ],
        ),
      ),
    );
  }
}
