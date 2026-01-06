import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';

class AIService {
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static String get _apiKey =>
      dotenv.env['AIzaSyAn43ednUZnJd8ZRPOaOeMLOWHQZMSnSbk'] ?? '';

  Future<String> getAIResponse(List<ChatMessage> messages) async {
    if (_apiKey.isEmpty) {
      throw Exception(
          'GEMINI_API_KEY is not set. Please check your .env file.');
    }

    // Take last 10 messages for context
    final recentMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;

    // Build conversation history
    final contents = recentMessages.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ]
      };
    }).toList();

    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      }
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]
                ?['text'] ??
            'Sorry, I couldn\'t generate a response.';
        return text.trim();
      } else {
        print('AI API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I\'m having trouble responding right now.';
      }
    } catch (e) {
      print('AI Service Error: $e');
      return 'Sorry, there was an error processing your request.';
    }
  }
}
