import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../../../core/constants/languages.dart';
import '../../../core/services/permission_service.dart';

class AssistantController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();

  RxBool isListening = false.obs;
  RxString livePartialText = ''.obs;
  RxList<ChatMessage> chatMessages = <ChatMessage>[].obs;
  RxBool isLoading = false.obs;
  RxInt speakingIndex = (-1).obs;
  RxString errorMessage = ''.obs;

  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastUserMessage;
  final int _maxMessageLength = 500;
  final Duration _cooldown = const Duration(seconds: 2);

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
    update();
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
    update();
  }

  void _initializeSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          isListening.value = false;
          if (livePartialText.value.isNotEmpty) {
            _addUserMessage(livePartialText.value);
            livePartialText.value = '';
          }
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
  }

  void startListening() async {
    if (isLoading.value) return;
    final micGranted = await PermissionService.requestMicrophone();
    if (!micGranted) {
      Get.snackbar('Permission', 'Microphone permission is required');
      return;
    }
    if (!isListening.value && _speechToText.isAvailable) {
      livePartialText.value = '';
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
    _speechToText.stop();
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
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final context = List<ChatMessage>.from(chatMessages);
      final placeholderIndex = chatMessages.length;
      chatMessages.add(ChatMessage.ai(''));

      String accumulated = '';
      await for (final chunk in _aiService.getAIResponseStream(context)) {
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
    chatMessages.add(ChatMessage.user(_lastUserMessage!));
    _getAIResponse();
  }

  bool _canSend(String text) {
    if (text.length > _maxMessageLength) {
      Get.snackbar('Too long', 'Please keep messages under $_maxMessageLength characters.');
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

  @override
  void onClose() {
    _speechToText.cancel();
    _flutterTts.stop();
    super.onClose();
  }
}
