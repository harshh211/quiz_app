import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/question.dart';

/// Handles all communication with the QuizAPI Questions endpoint.
///
/// This is the ONLY place in the app that knows about HTTP, JSON, or
/// QuizAPI's response envelope. The rest of the app just calls
/// [fetchQuestions] and gets back a clean `List<Question>`.
class TriviaService {
  static const String _baseUrl = 'https://quizapi.io/api/v1/questions';

  /// Fetches questions from QuizAPI with optional filters.
  ///
  /// Throws a descriptive Exception on any failure so the UI can
  /// show targeted error messages for timeout, no-internet, 401, 429, etc.
  static Future<List<Question>> fetchQuestions({
    required String apiKey,
    int limit = 10,
    String category = 'Programming',
    String difficulty = 'EASY',
    String type = 'MULTIPLE_CHOICE',
  }) async {
    // Build the URL with query parameters.
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'limit': '$limit',
      'category': category,
      'difficulty': difficulty,
      'type': type,
    });

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 10));

      // Handle specific HTTP status codes with targeted messages.
      if (response.statusCode == 401) {
        throw Exception('Invalid API key. Check your QUIZ_API_KEY.');
      }
      if (response.statusCode == 429) {
        throw Exception('Too many requests. Please wait and try again.');
      }
      if (response.statusCode != 200) {
        throw Exception('HTTP error: ${response.statusCode}');
      }

      // Parse the envelope and validate it.
      final body = json.decode(response.body) as Map<String, dynamic>;

      // QuizAPI may or may not include a success field; check if present.
      if (body.containsKey('success') && body['success'] != true) {
        throw Exception('API returned success=false');
      }

      // QuizAPI returns either a bare array or {data: [...]}.
      // Handle both shapes defensively.
      final List rawList = body['data'] is List
          ? body['data'] as List
          : (response.body.trim().startsWith('[')
              ? json.decode(response.body) as List
              : []);

      if (rawList.isEmpty) {
        throw Exception('No questions returned for these filters.');
      }

      return rawList
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('Connection timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection. Check WiFi or data.');
    } on FormatException {
      throw Exception('Received malformed data from the server.');
    }
  }
}