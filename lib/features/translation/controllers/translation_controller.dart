import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TranslationController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  var isListeningEnglish = false.obs;
  var isListeningSpanish = false.obs;
  var englishMessages = <String>[].obs;
  var spanishMessages = <String>[].obs;
  var currentEnglishText = ''.obs;
  var currentSpanishText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    requestMicrophonePermission();
    _initializeSpeech();
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

  Future<void> startListeningEnglish() async {
    if (isListeningSpanish.value) {
      await stopListeningSpanish();
    }
    if (!isListeningEnglish.value) {
      bool available = await _speechToText.initialize();
      if (available) {
        isListeningEnglish.value = true;
        currentEnglishText.value = '';
        await _speechToText.listen(
          onResult: (result) {
            currentEnglishText.value = result.recognizedWords;
            if (result.finalResult) {
              englishMessages.add(result.recognizedWords);
              currentEnglishText.value = '';
              stopListeningEnglish();
            }
          },
          localeId: 'en_US',
        );
      } else {
        Get.snackbar('Error', 'Speech recognition not available');
      }
    }
  }

  Future<void> stopListeningEnglish() async {
    if (isListeningEnglish.value) {
      await _speechToText.stop();
      isListeningEnglish.value = false;
    }
  }

  Future<void> startListeningSpanish() async {
    if (isListeningEnglish.value) {
      await stopListeningEnglish();
    }
    if (!isListeningSpanish.value) {
      bool available = await _speechToText.initialize();
      if (available) {
        isListeningSpanish.value = true;
        currentSpanishText.value = '';
        await _speechToText.listen(
          onResult: (result) {
            currentSpanishText.value = result.recognizedWords;
            if (result.finalResult) {
              spanishMessages.add(result.recognizedWords);
              currentSpanishText.value = '';
              stopListeningSpanish();
            }
          },
          localeId: 'es_ES',
        );
      } else {
        Get.snackbar('Error', 'Speech recognition not available');
      }
    }
  }

  Future<void> stopListeningSpanish() async {
    if (isListeningSpanish.value) {
      await _speechToText.stop();
      isListeningSpanish.value = false;
    }
  }
}
