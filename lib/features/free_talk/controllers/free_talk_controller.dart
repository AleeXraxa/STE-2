import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/services/bluetooth_service.dart';
import '../models/free_talk_message.dart';

class FreeTalkController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final GoogleTranslator translator = GoogleTranslator();
  final FlutterTts tts = FlutterTts();

  // Language selection (fixed to English and Hindi)
  var languageA = 'en'.obs;
  var languageAName = 'English'.obs;
  var languageB = 'hi'.obs;
  var languageBName = 'Hindi'.obs;

  var isListening = false.obs;
  var lastDetectedLanguage = ''.obs;
  var currentStatus = 'Ready to start'.obs;
  var messages = <FreeTalkMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) => print('FreeTalk Speech status: $status'),
      onError: (error) => print('FreeTalk Speech error: $error'),
    );
  }

  Future<void> startFreeTalk() async {
    if (!isListening.value) {
      // Check Bluetooth connection
      final bluetoothService = Get.find<BluetoothService>();
      if (bluetoothService.connectedDeviceName.value.isEmpty) {
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

    // Use English locale for consistent transcription
    final defaultLocale = 'en_US';

    await _speechToText.listen(
      onResult: (result) async {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          await _processSpeech(result.recognizedWords);
        }
      },
      localeId: defaultLocale,
      listenMode: ListenMode.dictation,
      partialResults: false,
    );
  }

  Future<void> _processSpeech(String speech) async {
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
        await _startListening();
      }
    } catch (e) {
      print('Translation error: $e');
      // Resume listening
      if (isListening.value) {
        await _startListening();
      }
    }
  }

  Future<String> _detectLanguage(String text) async {
    try {
      // Try to detect by translating to English and getting source
      var detection = await translator.translate(text, to: 'en');
      String detected = detection.sourceLanguage.code;

      print('Detected language: $detected for text: $text');

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
      print(
          'Detected language $detected not in selected languages, using last: ${lastDetectedLanguage.value}');
      return lastDetectedLanguage.value;
    } catch (e) {
      print('Language detection error: $e');
      // Keep last detected on error
      return lastDetectedLanguage.value;
    }
  }
}
