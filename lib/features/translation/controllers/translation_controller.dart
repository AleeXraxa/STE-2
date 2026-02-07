import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/languages.dart';
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
  var selectedMessages = <int>{}.obs;

  // Search functionality
  var searchQuery = ''.obs;
  var filteredLanguages = <Map<String, String>>[].obs;

  final List<Map<String, String>> supportedLanguages = SupportedLanguages.list;

  @override
  void onInit() {
    super.onInit();
    requestMicrophonePermission();
    _initializeSpeech();
    tts.setCompletionHandler(() {
      playingIndex.value = -1;
    });
    // Initialize filtered languages
    filteredLanguages.value = supportedLanguages;
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (status.isGranted) {
        print("Mic permission granted");
      } else if (status.isDenied) {
        print("Mic permission denied");
        Get.snackbar('Permission Denied',
            'Microphone permission is required for voice input');
      } else if (status.isPermanentlyDenied) {
        print("Mic permission permanently denied");
        openAppSettings();
      }
    } else {
      print("Mic permission already granted");
    }
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
      bool available = await _speechToText.initialize();
      if (available) {
        isListeningSource.value = true;
        final locale = supportedLanguages.firstWhere(
            (lang) => lang['code'] == selectedSourceLanguage.value)['locale']!;
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
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
      bool available = await _speechToText.initialize();
      if (available) {
        isListeningTarget.value = true;
        final locale = supportedLanguages.firstWhere(
            (lang) => lang['code'] == selectedTargetLanguage.value)['locale']!;
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
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
    final indices = selectedMessages.toList()..sort((a, b) => b.compareTo(a));
    for (final index in indices) {
      if (index < chatMessages.length) {
        chatMessages.removeAt(index);
      }
    }
    selectedMessages.clear();
    update();
  }
}
