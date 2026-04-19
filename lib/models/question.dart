import 'package:html_unescape/html_unescape.dart';

// Shared instance — HtmlUnescape has no state so one is fine.
final _unescape = HtmlUnescape();

class Question {
  final String id;
  final String question;
  final List<String> answers;
  final String correctAnswer;
  final String difficulty;
  final String category;

  Question({
    required this.id,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawAnswers = (json['answers'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((answer) => (answer['text'] ?? '').toString().isNotEmpty)
        .toList();

    final correct = rawAnswers.firstWhere(
      (answer) => answer['isCorrect'] == true,
      orElse: () => {'text': ''},
    );

    return Question(
      id: (json['id'] ?? '').toString(),
      question: _unescape.convert((json['text'] ?? '').toString()),
      answers: rawAnswers
          .map((a) => _unescape.convert(a['text'].toString()))
          .toList(),
      correctAnswer: _unescape.convert((correct['text'] ?? '').toString()),
      difficulty: (json['difficulty'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
    );
  }

  List<String> get shuffledAnswers {
    final items = [...answers];
    items.shuffle();
    return items;
  }
}