import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GoogleSpeechService {
  static const String _baseUrl =
      'https://speech.googleapis.com/v1/speech:recognize';

  Future<String?> transcribeWav({
    required String filePath,
    String languageCode = 'en-US',
    int sampleRateHertz = 16000,
  }) async {
    final apiKey = dotenv.env['GOOGLE_SPEECH_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final file = File(filePath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final audioContent = base64Encode(bytes);

    final body = {
      'config': {
        'encoding': 'LINEAR16',
        'sampleRateHertz': sampleRateHertz,
        'languageCode': languageCode,
        'enableAutomaticPunctuation': true,
      },
      'audio': {
        'content': audioContent,
      },
    };

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return '';

    final transcripts = results
        .map((r) =>
            r['alternatives']?[0]?['transcript']?.toString().trim() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    return transcripts.join(' ');
  }
}
