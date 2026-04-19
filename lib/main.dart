import 'package:flutter/material.dart';
import 'app_config.dart';
import 'services/trivia_service.dart';

void main() async {
  // Required when using async code before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.validate();

  // TEMPORARY: fetch and print questions to verify the API works.
  try {
    final questions = await TriviaService.fetchQuestions(
      apiKey: AppConfig.quizApiKey,
      limit: 3,
    );
    for (final q in questions) {
      print('Q: ${q.question}');
      print('   Correct: ${q.correctAnswer}');
      print('   Options: ${q.answers}');
      print('');
    }
  } catch (e) {
    print('ERROR: $e');
  }

  runApp(const MaterialApp(
    home: Scaffold(body: Center(child: Text('Check console'))),
  ));
}