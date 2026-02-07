import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/services/bluetooth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/constants/languages.dart';
import '../models/free_talk_message.dart';

class FreeTalkController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final GoogleTranslator translator = GoogleTranslator();
  final FlutterTts tts = FlutterTts();

  // Language selection
  var languageA = 'en'.obs;
  var languageAName = 'English'.obs;
  var languageB = 'hi'.obs;
  var languageBName = 'Hindi'.obs;

  var isListening = false.obs;
  var lastDetectedLanguage = ''.obs;
  var currentStatus = 'Ready to start'.obs;
  var messages = <FreeTalkMessage>[].obs;

  // Search functionality
  var searchQuery = ''.obs;
  var filteredLanguages = <Map<String, String>>[].obs;

  final List<Map<String, String>> supportedLanguages = SupportedLanguages.list;

  bool _isProcessing = false;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
    // Initialize filtered languages
    filteredLanguages.value = supportedLanguages;
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) {},
      onError: (error) {
        Get.snackbar('Speech Recognition', 'Error: ${error.errorMsg}');
      },
    );
  }

  void selectLanguageA(String code, String name) {
    languageA.value = code;
    languageAName.value = name;
  }

  void selectLanguageB(String code, String name) {
    languageB.value = code;
    languageBName.value = name;
  }

  void swapLanguages() {
    final tempCode = languageA.value;
    final tempName = languageAName.value;

    languageA.value = languageB.value;
    languageAName.value = languageBName.value;

    languageB.value = tempCode;
    languageBName.value = tempName;

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

  Future<void> startFreeTalk() async {
    if (!isListening.value) {
      final micGranted = await PermissionService.requestMicrophone();
      if (!micGranted) {
        Get.snackbar('Permission', 'Microphone permission is required');
        return;
      }
      // Check Bluetooth connection
      final bluetoothService = Get.find<BluetoothService>();
      if (bluetoothService.connectedDeviceName.value.isEmpty &&
          !bluetoothService.isClassicConnected.value) {
        Get.snackbar('No Earbud Connected', 'Please connect an earbud first');
        return;
      }

      isListening.value = true;
      currentStatus.value = 'Listening...';
      lastDetectedLanguage.value = languageA.value; // Default to A
      await _startListening();
    }
  }

  Future<void> stopFreeTalk() async {
    if (isListening.value) {
      isListening.value = false;
      currentStatus.value = 'Stopped';
      await _speechToText.stop();
      await tts.stop();
    }
  }

  Future<void> _startListening() async {
    if (!isListening.value) return;
    if (_isProcessing) return;

    final locale = supportedLanguages.firstWhere(
        (lang) => lang['code'] == lastDetectedLanguage.value,
        orElse: () => {'locale': 'en_US'})['locale']!;

    await _speechToText.listen(
      onResult: (result) async {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          await _processSpeech(result.recognizedWords);
        }
      },
      localeId: locale,
      listenMode: ListenMode.dictation,
      partialResults: false,
    );
  }

  Future<void> _processSpeech(String speech) async {
    if (_isProcessing) return;
    _isProcessing = true;
    // Detect language
    String detectedLang = await _detectLanguage(speech);

    // If not one of the two languages, use last detected
    if (detectedLang != languageA.value && detectedLang != languageB.value) {
      detectedLang = lastDetectedLanguage.value;
    }

    lastDetectedLanguage.value = detectedLang;

    // Normalize original text to proper script
    String normalizedOriginal = speech;
    if (detectedLang == 'hi') {
      try {
        // Convert Romanized Hindi to Devanagari by translating from English to Hindi
        var normalized =
            await translator.translate(speech, from: 'en', to: 'hi');
        normalizedOriginal = normalized.text;
      } catch (e) {
        print('Normalization error: $e');
        // Keep original
      }
    }

    // Determine target language
    String targetLang =
        (detectedLang == languageA.value) ? languageB.value : languageA.value;

    // Translate
    try {
      var translation = await translator.translate(speech,
          from: detectedLang, to: targetLang);
      currentStatus.value = 'Translating...';

      // Add message to chat
      messages.add(FreeTalkMessage.create(
          normalizedOriginal, translation.text, detectedLang));
      update();

      // Translation completed
      currentStatus.value = 'Translation completed';

      // Resume listening immediately
      if (isListening.value) {
        await Future.delayed(const Duration(seconds: 1));
        await _startListening();
      }
    } catch (e) {
      Get.snackbar('Translation', 'Translation failed. Please try again.');
      // Resume listening
      if (isListening.value) {
        await Future.delayed(const Duration(seconds: 1));
        await _startListening();
      }
    } finally {
      _isProcessing = false;
      if (isListening.value && !_speechToText.isListening) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _startListening();
      }
    }
  }

  Future<String> _detectLanguage(String text) async {
    try {
      // Try to detect by translating to English and getting source
      var detection = await translator.translate(text, to: 'en');
      String detected = detection.sourceLanguage.code;

      // Handle 'auto' as English (since STT transcribes to English)
      if (detected == 'auto') {
        detected = 'en';
      }

      // If detected language is one of our selected languages, use it
      if (detected == languageA.value || detected == languageB.value) {
        return detected;
      }

      // If not detected as one of our languages, keep the last detected
      // This prevents simulation-like alternating
      return lastDetectedLanguage.value;
    } catch (e) {
      Get.snackbar('Language Detection', 'Failed to detect language.');
      // Keep last detected on error
      return lastDetectedLanguage.value;
    }
  }
}
