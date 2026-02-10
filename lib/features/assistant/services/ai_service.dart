import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';

class AIService {
  // Cloudflare Workers AI
  static const String _defaultModel = '@cf/meta/llama-3.1-8b-instruct';
  http.Client? _activeClient;

  void cancelActive() {
    _activeClient?.close();
    _activeClient = null;
  }

  Future<String> getAIResponse(List<ChatMessage> messages,
      {required String responseLanguage}) async {
    final accountId = dotenv.env['CLOUDFLARE_ACCOUNT_ID'] ?? '';
    final apiToken = dotenv.env['CLOUDFLARE_API_TOKEN'] ?? '';
    final model = dotenv.env['CLOUDFLARE_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['CLOUDFLARE_MODEL']!.trim()
        : _defaultModel;
    if (accountId.isEmpty || apiToken.isEmpty) {
      return 'AI is not configured. Please set CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN in .env.';
    }

    // Take last 10 messages for context
    final recentMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;

    // Build conversation history
    final prompt = _buildPrompt(recentMessages, responseLanguage);
    final requestBody = {
      'prompt': prompt,
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://api.cloudflare.com/client/v4/accounts/$accountId/ai/run/$model'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['result']?['response'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
        return 'Sorry, I couldn\'t generate a response.';
      } else {
        print('AI API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I\'m having trouble responding right now.';
      }
    } catch (e) {
      print('AI Service Error: $e');
      return 'Sorry, there was an error processing your request.';
    }
  }

  Stream<String> getAIResponseStream(List<ChatMessage> messages,
      {required String responseLanguage}) async* {
    final accountId = dotenv.env['CLOUDFLARE_ACCOUNT_ID'] ?? '';
    final apiToken = dotenv.env['CLOUDFLARE_API_TOKEN'] ?? '';
    final model = dotenv.env['CLOUDFLARE_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['CLOUDFLARE_MODEL']!.trim()
        : _defaultModel;
    if (accountId.isEmpty || apiToken.isEmpty) {
      yield 'AI is not configured. Please set CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN in .env.';
      return;
    }

    // Take last 10 messages for context
    final recentMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;

    final prompt = _buildPrompt(recentMessages, responseLanguage);
    final requestBody = jsonEncode({
      'prompt': prompt,
      'stream': true,
    });

    final client = http.Client();
    _activeClient?.close();
    _activeClient = client;
    try {
      final request = http.Request(
        'POST',
        Uri.parse(
            'https://api.cloudflare.com/client/v4/accounts/$accountId/ai/run/$model'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiToken',
      });
      request.body = requestBody;

      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        yield 'Sorry, I\'m having trouble responding right now.';
        return;
      }

      var buffer = '';
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (true) {
          final newlineIndex = buffer.indexOf('\n');
          if (newlineIndex == -1) break;
          final line = buffer.substring(0, newlineIndex).trimRight();
          buffer = buffer.substring(newlineIndex + 1);
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data.isEmpty || data == '[DONE]') continue;
          try {
            final jsonData = jsonDecode(data);
            final response =
                jsonData['result']?['response'] ?? jsonData['response'];
            if (response is String && response.isNotEmpty) {
              yield response;
            }
          } catch (_) {
            // ignore malformed chunks
          }
        }
      }
    } finally {
      client.close();
      if (_activeClient == client) {
        _activeClient = null;
      }
    }
  }

  String _buildPrompt(List<ChatMessage> messages, String responseLanguage) {
    final buffer = StringBuffer();
    buffer.writeln(
        'System: You are a helpful assistant. Respond in $responseLanguage.');
    for (final msg in messages) {
      buffer
          .writeln(msg.isUser ? 'User: ${msg.text}' : 'Assistant: ${msg.text}');
    }
    buffer.writeln('Assistant:');
    return buffer.toString();
  }
}
