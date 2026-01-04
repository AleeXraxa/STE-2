import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class AssistantController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();

  RxBool isListening = false.obs;
  RxString livePartialText = ''.obs;
  RxList<ChatMessage> chatMessages = <ChatMessage>[].obs;
  RxBool isLoading = false.obs;
  RxInt speakingIndex = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
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
    if (!isListening.value && _speechToText.isAvailable) {
      livePartialText.value = '';
      isListening.value = true;
      await _speechToText.listen(
        partialResults: true,
        listenMode: ListenMode.confirmation,
        onResult: (result) {
          livePartialText.value = result.recognizedWords;
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
      await _flutterTts.speak(text);
      _flutterTts.setCompletionHandler(() {
        speakingIndex.value = -1;
      });
    }
  }

  void _addUserMessage(String text) {
    chatMessages.add(ChatMessage.user(text));
    _getAIResponse();
  }

  void sendTypedMessage(String text) {
    if (text.trim().isNotEmpty) {
      chatMessages.add(ChatMessage.user(text.trim()));
      _getAIResponse();
    }
  }

  void _getAIResponse() async {
    isLoading.value = true;
    try {
      final aiResponse = await _aiService.getAIResponse(chatMessages);
      chatMessages.add(ChatMessage.ai(aiResponse));
    } catch (e) {
      print('Error getting AI response: $e');
      chatMessages.add(
          ChatMessage.ai('Sorry, I\'m having trouble responding right now.'));
    } finally {
      isLoading.value = false;
    }
  }
}
