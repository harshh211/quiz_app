import 'package:flutter/material.dart';
import '../app_config.dart';
import '../models/question.dart';
import '../services/trivia_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ---- State variables ----
  List<Question> _questions = [];
  List<String> _shuffledAnswers = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _loading = true;
  bool _answered = false;
  String? _selectedAnswer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ---- Data loading ----
  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final questions = await TriviaService.fetchQuestions(
        apiKey: AppConfig.quizApiKey,
        limit: 10,
      );
      setState(() {
        _questions = questions;
        _currentIndex = 0;
        _score = 0;
        _prepareQuestion();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Caches the shuffled answers for the current question.
  /// Called ONCE per question — never inside build().
  void _prepareQuestion() {
    if (_questions.isEmpty) return;
    _shuffledAnswers = _questions[_currentIndex].shuffledAnswers;
    _answered = false;
    _selectedAnswer = null;
  }

  // ---- Answer handling ----
  void _onAnswerTap(String answer) {
    if (_answered) return;

    final correct = _questions[_currentIndex].correctAnswer;
    final isCorrect = answer == correct;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) _score++;
    });

    // Show a floating SnackBar with feedback.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isCorrect ? 'Correct!' : 'Wrong. Correct answer: $correct',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              isCorrect ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

    // Auto-advance after 1.5 seconds.
    Future.delayed(const Duration(milliseconds: 1500), _nextQuestion);
  }

  void _nextQuestion() {
    if (!mounted) return; // widget gone? bail out safely.

    if (_currentIndex + 1 >= _questions.length) {
      // Quiz complete — push to results.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: _score,
            total: _questions.length,
          ),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex++;
      _prepareQuestion();
    });
  }

  // ---- Button color based on answered state ----
  Color _buttonColor(String option) {
    if (!_answered) return Colors.white;
    final correct = _questions[_currentIndex].correctAnswer;
    if (option == correct) return Colors.green.shade100;
    if (option == _selectedAnswer) return Colors.red.shade100;
    return Colors.grey.shade100;
  }

  /// Border color mirrors the fill color for a cleaner answered state.
  Color _buttonBorderColor(String option) {
    if (!_answered) return Colors.grey.shade300;
    final correct = _questions[_currentIndex].correctAnswer;
    if (option == correct) return Colors.green.shade400;
    if (option == _selectedAnswer) return Colors.red.shade400;
    return Colors.grey.shade300;
  }

  // ---- Build method ----
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Could not load questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadQuestions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} / ${_questions.length}'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.teal.shade50,
            color: Colors.teal,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category and difficulty chips
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          question.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.teal.shade50,
                      ),
                      Chip(
                        label: Text(
                          question.difficulty.toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.orange.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Question text
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Answer buttons
                  ..._shuffledAnswers.map((option) {
                    final correct =
                        _questions[_currentIndex].correctAnswer;
                    final showCheck = _answered && option == correct;
                    final showCross = _answered &&
                        option == _selectedAnswer &&
                        option != correct;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: () => _onAnswerTap(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonColor(option),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _buttonBorderColor(option),
                              width: 1.5,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            if (showCheck)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            if (showCross)
                              const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}