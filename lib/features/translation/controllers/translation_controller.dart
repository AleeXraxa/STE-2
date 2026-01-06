import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/message.dart';

class TranslationController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final GoogleTranslator translator = GoogleTranslator();
  final FlutterTts tts = FlutterTts();
  var isListeningEnglish = false.obs;
  var isListeningSpanish = false.obs;
  var chatMessages = <Message>[].obs;
  var playingIndex = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    requestMicrophonePermission();
    _initializeSpeech();
    tts.setCompletionHandler(() {
      playingIndex.value = -1;
    });
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

  Future<void> startListeningEnglish() async {
    if (isListeningSpanish.value) {
      await stopListeningSpanish();
    }
    if (!isListeningEnglish.value) {
      bool available = await _speechToText.initialize();
      if (available) {
        isListeningEnglish.value = true;
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              _addMessage(result.recognizedWords, 'en', 'es');
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
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              _addMessage(result.recognizedWords, 'es', 'en');
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

  Future<void> play(int index) async {
    if (playingIndex.value != -1 && playingIndex.value != index) {
      await stopPlaying();
    }
    if (playingIndex.value == index) {
      await stopPlaying();
    } else {
      // stop listening
      if (isListeningEnglish.value) await stopListeningEnglish();
      if (isListeningSpanish.value) await stopListeningSpanish();
      // play
      await tts.speak(chatMessages[index].translated);
      playingIndex.value = index;
    }
  }

  Future<void> stopPlaying() async {
    await tts.stop();
    playingIndex.value = -1;
  }
}
