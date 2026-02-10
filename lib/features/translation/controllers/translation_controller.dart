import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/languages.dart';
import '../../../core/services/permission_service.dart';
import '../models/message.dart';

class TranslationController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final GoogleTranslator translator = GoogleTranslator();
  final FlutterTts tts = FlutterTts();

  // Language selection
  var selectedSourceLanguage = 'en'.obs;
  var selectedTargetLanguage = 'es'.obs;
  var selectedSourceLanguageName = 'English'.obs;
  var selectedTargetLanguageName = 'Spanish'.obs;

  var isListeningSource = false.obs;
  var isListeningTarget = false.obs;
  var chatMessages = <Message>[].obs;
  var playingIndex = (-1).obs;
  var isSelectionMode = false.obs;
  var selectedMessages = <Message>{}.obs;
  var speechAvailable = false.obs;

  // Search functionality
  var searchQuery = ''.obs;
  var filteredLanguages = <Map<String, String>>[].obs;

  final List<Map<String, String>> supportedLanguages = SupportedLanguages.list;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
    tts.setCompletionHandler(() {
      playingIndex.value = -1;
    });
    // Initialize filtered languages
    filteredLanguages.value = supportedLanguages;
  }

  Future<void> _initializeSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (isListeningSource.value || isListeningTarget.value) {
            isListeningSource.value = false;
            isListeningTarget.value = false;
          }
        }
      },
      onError: (error) {
        if (error.errorMsg == 'error_speech_timeout') {
          isListeningSource.value = false;
          isListeningTarget.value = false;
          Get.snackbar('Speech Recognition', 'Voice not detected');
          return;
        }
        if (error.errorMsg == 'error_no_match') {
          isListeningSource.value = false;
          isListeningTarget.value = false;
          Get.snackbar('Speech Recognition', 'No speech detected');
          return;
        }
        isListeningSource.value = false;
        isListeningTarget.value = false;
        Get.snackbar('Speech Recognition', 'Error: ${error.errorMsg}');
      },
    );
    speechAvailable.value = available;
  }

  Future<void> _addMessage(
      String original, String fromLang, String toLang) async {
    try {
      var translation =
          await translator.translate(original, from: fromLang, to: toLang);
      chatMessages.add(Message(
          original: original,
          translated: translation.text,
          sourceLang: fromLang));
      update();
    } catch (e) {
      chatMessages.add(Message(
          original: original,
          translated: "Translation failed",
          sourceLang: fromLang));
      update();
    }
  }

  void selectSourceLanguage(String code, String name) {
    selectedSourceLanguage.value = code;
    selectedSourceLanguageName.value = name;
    update();
  }

  void selectTargetLanguage(String code, String name) {
    selectedTargetLanguage.value = code;
    selectedTargetLanguageName.value = name;
    update();
  }

  void swapLanguages() {
    final tempCode = selectedSourceLanguage.value;
    final tempName = selectedSourceLanguageName.value;

    selectedSourceLanguage.value = selectedTargetLanguage.value;
    selectedSourceLanguageName.value = selectedTargetLanguageName.value;

    selectedTargetLanguage.value = tempCode;
    selectedTargetLanguageName.value = tempName;

    chatMessages.clear();
    selectedMessages.clear();
    isSelectionMode.value = false;
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

  Future<void> startListeningSource() async {
    if (isListeningTarget.value) {
      await stopListeningTarget();
    }
    if (!isListeningSource.value) {
      final micGranted = await PermissionService.requestMicrophone();
      if (!micGranted) {
        Get.snackbar('Permission', 'Microphone permission is required');
        return;
      }
      if (speechAvailable.value) {
        isListeningSource.value = true;
        final locale = supportedLanguages.firstWhere(
            (lang) => lang['code'] == selectedSourceLanguage.value)['locale']!;
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              if (result.recognizedWords.trim().isEmpty) {
                Get.snackbar('Speech Recognition', 'Voice not detected');
                stopListeningSource();
                return;
              }
              _addMessage(result.recognizedWords, selectedSourceLanguage.value,
                  selectedTargetLanguage.value);
              stopListeningSource();
            }
          },
          localeId: locale,
        );
      } else {
        Get.snackbar('Error', 'Speech recognition not available');
      }
    }
  }

  Future<void> stopListeningSource() async {
    if (isListeningSource.value) {
      await _speechToText.stop();
      isListeningSource.value = false;
    }
  }

  Future<void> startListeningTarget() async {
    if (isListeningSource.value) {
      await stopListeningSource();
    }
    if (!isListeningTarget.value) {
      final micGranted = await PermissionService.requestMicrophone();
      if (!micGranted) {
        Get.snackbar('Permission', 'Microphone permission is required');
        return;
      }
      if (speechAvailable.value) {
        isListeningTarget.value = true;
        final locale = supportedLanguages.firstWhere(
            (lang) => lang['code'] == selectedTargetLanguage.value)['locale']!;
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              if (result.recognizedWords.trim().isEmpty) {
                Get.snackbar('Speech Recognition', 'Voice not detected');
                stopListeningTarget();
                return;
              }
              _addMessage(result.recognizedWords, selectedTargetLanguage.value,
                  selectedSourceLanguage.value);
              stopListeningTarget();
            }
          },
          localeId: locale,
        );
      } else {
        Get.snackbar('Error', 'Speech recognition not available');
      }
    }
  }

  Future<void> stopListeningTarget() async {
    if (isListeningTarget.value) {
      await _speechToText.stop();
      isListeningTarget.value = false;
    }
  }

  Future<void> play(int index) async {
    if (playingIndex.value != -1 && playingIndex.value != index) {
      await stopPlaying();
    }
    if (playingIndex.value == index) {
      await stopPlaying();
    } else {
      // stop listening
      if (isListeningSource.value) await stopListeningSource();
      if (isListeningTarget.value) await stopListeningTarget();
      // play
      await tts.speak(chatMessages[index].translated);
      playingIndex.value = index;
    }
  }

  Future<void> stopPlaying() async {
    await tts.stop();
    playingIndex.value = -1;
  }

  void deleteSelectedMessages() {
    // Sort indices in descending order to remove from end
    final toRemove = selectedMessages.toSet();
    chatMessages.removeWhere((message) => toRemove.contains(message));
    selectedMessages.clear();
    update();
  }
}
