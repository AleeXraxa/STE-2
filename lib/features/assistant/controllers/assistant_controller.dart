import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../../../core/constants/languages.dart';
import '../../../core/services/permission_service.dart';

class AssistantController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();
  final GoogleTranslator _translator = GoogleTranslator();

  RxBool isListening = false.obs;
  RxString livePartialText = ''.obs;
  RxList<ChatMessage> chatMessages = <ChatMessage>[].obs;
  RxBool isLoading = false.obs;
  RxInt speakingIndex = (-1).obs;
  RxString errorMessage = ''.obs;
  RxBool speechAvailable = false.obs;

  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastUserMessage;
  final int _maxMessageLength = 500;
  final Duration _cooldown = const Duration(seconds: 2);
  bool _speechMessageSent = false;
  int _activeRequestId = 0;

  // Language selection
  var selectedLanguage = 'en'.obs;
  var selectedLanguageName = 'English'.obs;

  // Search functionality
  var searchQuery = ''.obs;
  var filteredLanguages = <Map<String, String>>[].obs;

  // Supported languages (same as translation)
  final List<Map<String, String>> supportedLanguages = SupportedLanguages.list;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
    _configureTts();
    // Initialize filtered languages
    filteredLanguages.value = supportedLanguages;
  }

  void selectLanguage(String code, String name) {
    selectedLanguage.value = code;
    selectedLanguageName.value = name;
    _configureTts();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredLanguages.value = supportedLanguages;
    } else {
      filteredLanguages.value = supportedLanguages
          .where((lang) =>
              lang['name']!.toLowerCase().contains(query.toLowerCase()) ||
              lang['code']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  void _initializeSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          isListening.value = false;
        }
      },
      onError: (error) {
        print('Speech error: $error');
        if (error.errorMsg == 'error_no_match') {
          Get.snackbar(
              'Speech Recognition', 'No speech detected. Please try again.');
        } else {
          Get.snackbar('Speech Recognition', 'Error: ${error.errorMsg}');
        }
      },
    );
    speechAvailable.value = available;
  }

  void startListening() async {
    if (isLoading.value) return;
    if (!speechAvailable.value) {
      Get.snackbar(
          'Speech Recognition', 'Speech recognition is not available.');
      return;
    }
    final micGranted = await PermissionService.requestMicrophone();
    if (!micGranted) {
      Get.snackbar('Permission', 'Microphone permission is required');
      return;
    }
    if (!isListening.value && _speechToText.isAvailable) {
      livePartialText.value = '';
      _speechMessageSent = false;
      isListening.value = true;
      final locale = supportedLanguages.firstWhere(
          (lang) => lang['code'] == selectedLanguage.value,
          orElse: () => {'locale': 'en_US'})['locale']!;
      await _speechToText.listen(
        partialResults: true,
        listenMode: ListenMode.confirmation,
        localeId: locale,
        onResult: (result) {
          livePartialText.value = result.recognizedWords;
          if (result.finalResult && livePartialText.value.isNotEmpty) {
            if (_speechMessageSent) return;
            _speechMessageSent = true;
            isListening.value = false;
            _speechToText.stop();
            _addUserMessage(livePartialText.value);
            livePartialText.value = '';
          }
        },
      );
    }
  }

  void stopListening() {
    isListening.value = false;
    _speechToText.stop();
    if (livePartialText.value.isNotEmpty) {
      if (!_speechMessageSent) {
        _speechMessageSent = true;
        _addUserMessage(livePartialText.value);
        livePartialText.value = '';
      }
    } else {
      Get.snackbar('Speech', 'No speech detected');
    }
  }

  void speakText(String text, int index) async {
    if (speakingIndex.value == index) {
      await _flutterTts.stop();
      speakingIndex.value = -1;
    } else {
      speakingIndex.value = index;
      await _configureTts();
      await _flutterTts.speak(text);
      _flutterTts.setCompletionHandler(() {
        speakingIndex.value = -1;
      });
    }
  }

  void _addUserMessage(String text) {
    if (!_canSend(text)) return;
    chatMessages.add(ChatMessage.user(text));
    _lastUserMessage = text;
    _getAIResponse();
  }

  void sendTypedMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!_canSend(trimmed)) return;
    chatMessages.add(ChatMessage.user(trimmed));
    _lastUserMessage = trimmed;
    _getAIResponse();
  }

  void _getAIResponse() async {
    if (isLoading.value) return;
    _aiService.cancelActive();
    isLoading.value = true;
    errorMessage.value = '';
    _activeRequestId += 1;
    final requestId = _activeRequestId;
    try {
      final context = List<ChatMessage>.from(chatMessages);
      final placeholderIndex = chatMessages.length;
      chatMessages.add(ChatMessage.ai(''));

      String accumulated = '';
      final responseLanguage =
          await _responseLanguageForMessage(_lastUserMessage ?? '');
      await for (final chunk in _aiService.getAIResponseStream(
        context,
        responseLanguage: responseLanguage,
      )) {
        if (requestId != _activeRequestId) {
          break;
        }
        accumulated += chunk;
        chatMessages[placeholderIndex] = ChatMessage.ai(accumulated);
        update();
      }

      if (accumulated.trim().isEmpty) {
        chatMessages[placeholderIndex] =
            ChatMessage.ai('Sorry, I couldn\'t generate a response.');
      }
    } catch (e) {
      print('Error getting AI response: $e');
      errorMessage.value = 'AI failed to respond. Please try again.';
    } finally {
      _lastRequestAt = DateTime.now();
      isLoading.value = false;
    }
  }

  void retryLast() {
    if (_lastUserMessage == null) return;
    if (!_canSend(_lastUserMessage!)) return;
    _getAIResponse();
  }

  bool _canSend(String text) {
    if (text.length > _maxMessageLength) {
      Get.snackbar('Too long',
          'Please keep messages under $_maxMessageLength characters.');
      return false;
    }
    final now = DateTime.now();
    if (now.difference(_lastRequestAt) < _cooldown) {
      Get.snackbar('Slow down', 'Please wait a moment before sending again.');
      return false;
    }
    return true;
  }

  Future<void> _configureTts() async {
    final locale = supportedLanguages.firstWhere(
        (lang) => lang['code'] == selectedLanguage.value,
        orElse: () => {'locale': 'en_US'})['locale']!;
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  Future<String> _responseLanguageForMessage(String text) async {
    final selectedCode = selectedLanguage.value;
    if (selectedCode == 'en' || selectedCode.startsWith('en')) {
      return 'English';
    }
    final detected = await _detectLanguageCode(text);
    if (!_matchesLanguageCode(detected, selectedCode)) {
      return 'English';
    }
    return _languageNameForCode(selectedCode) ?? 'English';
  }

  Future<String?> _detectLanguageCode(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final sample =
        trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
    try {
      final result = await _translator.translate(sample, to: 'en', from: 'auto');
      return result.sourceLanguage.code.toLowerCase();
    } catch (_) {
      return null;
    }
  }

  bool _matchesLanguageCode(String? detected, String selected) {
    if (detected == null) return false;
    final d = detected.toLowerCase();
    final s = selected.toLowerCase();
    if (d == s) return true;
    if (s.contains('-')) {
      return d == s.split('-').first;
    }
    if (d.contains('-')) {
      return d.split('-').first == s;
    }
    return d.startsWith(s) || s.startsWith(d);
  }

  String? _languageNameForCode(String code) {
    for (final lang in supportedLanguages) {
      if (lang['code'] == code) return lang['name'];
    }
    return null;
  }

  @override
  void onClose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _aiService.cancelActive();
    super.onClose();
  }
}
