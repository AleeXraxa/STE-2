import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/languages.dart';
import '../../../core/services/permission_service.dart';
import '../models/headphone_phone_message.dart';

class HeadphonePhoneController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final GoogleTranslator _translator = GoogleTranslator();
  final FlutterTts _tts = FlutterTts();
  final RxString phoneLang = 'en'.obs;
  final RxString phoneLangName = 'English'.obs;
  final RxString earbudLang = 'es'.obs;
  final RxString earbudLangName = 'Spanish'.obs;

  RxBool isListeningPhone = false.obs;
  RxBool isListeningEarbud = false.obs;
  RxBool isProcessing = false.obs;
  RxList<HeadphonePhoneMessage> messages = <HeadphonePhoneMessage>[].obs;
  RxString status = 'Ready'.obs;

  List<Map<String, String>> get supportedLanguages => SupportedLanguages.list;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize(
      onStatus: (_) {},
      onError: (error) =>
          Get.snackbar('Speech', 'Error: ${error.errorMsg}'),
    );
  }

  void selectPhoneLanguage(String code, String name) {
    phoneLang.value = code;
    phoneLangName.value = name;
  }

  void selectEarbudLanguage(String code, String name) {
    earbudLang.value = code;
    earbudLangName.value = name;
  }

  Future<void> startPhoneListening() async {
    if (isProcessing.value) return;
    final micGranted = await PermissionService.requestMicrophone();
    if (!micGranted) {
      Get.snackbar('Permission', 'Microphone permission is required');
      return;
    }
    await _startListening(fromPhone: true);
  }

  Future<void> stopPhoneListening() async {
    await _stopListening();
  }

  Future<void> _startListening({required bool fromPhone}) async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    final locale = _localeForCode(fromPhone ? phoneLang.value : earbudLang.value);
    isListeningPhone.value = fromPhone;
    isListeningEarbud.value = !fromPhone;
    status.value = 'Listening...';

    await _speechToText.listen(
      listenMode: ListenMode.confirmation,
      partialResults: false,
      localeId: locale,
      onResult: (result) async {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          await _processSpeech(
            speech: result.recognizedWords,
            fromPhone: fromPhone,
          );
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    isListeningPhone.value = false;
    isListeningEarbud.value = false;
    status.value = 'Ready';
  }

  Future<void> _processSpeech({
    required String speech,
    required bool fromPhone,
  }) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    final sourceLang = fromPhone ? phoneLang.value : earbudLang.value;
    final targetLang = fromPhone ? earbudLang.value : phoneLang.value;
    status.value = 'Translating...';

    try {
      final translation = await _translator.translate(
        speech,
        from: sourceLang,
        to: targetLang,
      );
      messages.add(HeadphonePhoneMessage.create(
        original: speech,
        translated: translation.text,
        sourceLang: sourceLang,
        fromPhone: fromPhone,
      ));
      status.value = 'Ready';
    } catch (e) {
      Get.snackbar('Translation', 'Translation failed. Please try again.');
      status.value = 'Ready';
    } finally {
      isProcessing.value = false;
      await Future.delayed(const Duration(seconds: 1));
      if (fromPhone && isListeningPhone.value) {
        await _startListening(fromPhone: true);
      } else if (!fromPhone && isListeningEarbud.value) {
        await _startListening(fromPhone: false);
      }
    }
  }

  Future<void> speakTranslation(HeadphonePhoneMessage msg) async {
    final targetLang = msg.fromPhone ? earbudLang.value : phoneLang.value;
    final locale = _localeForCode(targetLang);
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.speak(msg.translated);
  }

  String _localeForCode(String code) {
    final match = supportedLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'locale': 'en_US'},
    );
    return match['locale'] ?? 'en_US';
  }

  @override
  void onClose() {
    _speechToText.cancel();
    _tts.stop();
    super.onClose();
  }
}
