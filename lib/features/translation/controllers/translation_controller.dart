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

  // Supported languages (comprehensive list)
  final List<Map<String, String>> supportedLanguages = [
    {'code': 'af', 'name': 'Afrikaans', 'locale': 'af_ZA'},
    {'code': 'sq', 'name': 'Albanian', 'locale': 'sq_AL'},
    {'code': 'am', 'name': 'Amharic', 'locale': 'am_ET'},
    {'code': 'ar', 'name': 'Arabic', 'locale': 'ar_SA'},
    {'code': 'hy', 'name': 'Armenian', 'locale': 'hy_AM'},
    {'code': 'az', 'name': 'Azerbaijani', 'locale': 'az_AZ'},
    {'code': 'eu', 'name': 'Basque', 'locale': 'eu_ES'},
    {'code': 'be', 'name': 'Belarusian', 'locale': 'be_BY'},
    {'code': 'bn', 'name': 'Bengali', 'locale': 'bn_BD'},
    {'code': 'bs', 'name': 'Bosnian', 'locale': 'bs_BA'},
    {'code': 'bg', 'name': 'Bulgarian', 'locale': 'bg_BG'},
    {'code': 'ca', 'name': 'Catalan', 'locale': 'ca_ES'},
    {'code': 'ceb', 'name': 'Cebuano', 'locale': 'ceb_PH'},
    {'code': 'ny', 'name': 'Chichewa', 'locale': 'ny_MW'},
    {'code': 'zh', 'name': 'Chinese (Simplified)', 'locale': 'zh_CN'},
    {'code': 'zh-TW', 'name': 'Chinese (Traditional)', 'locale': 'zh_TW'},
    {'code': 'co', 'name': 'Corsican', 'locale': 'co_FR'},
    {'code': 'hr', 'name': 'Croatian', 'locale': 'hr_HR'},
    {'code': 'cs', 'name': 'Czech', 'locale': 'cs_CZ'},
    {'code': 'da', 'name': 'Danish', 'locale': 'da_DK'},
    {'code': 'nl', 'name': 'Dutch', 'locale': 'nl_NL'},
    {'code': 'en', 'name': 'English', 'locale': 'en_US'},
    {'code': 'eo', 'name': 'Esperanto', 'locale': 'eo'},
    {'code': 'et', 'name': 'Estonian', 'locale': 'et_EE'},
    {'code': 'tl', 'name': 'Filipino', 'locale': 'tl_PH'},
    {'code': 'fi', 'name': 'Finnish', 'locale': 'fi_FI'},
    {'code': 'fr', 'name': 'French', 'locale': 'fr_FR'},
    {'code': 'fy', 'name': 'Frisian', 'locale': 'fy_NL'},
    {'code': 'gl', 'name': 'Galician', 'locale': 'gl_ES'},
    {'code': 'ka', 'name': 'Georgian', 'locale': 'ka_GE'},
    {'code': 'de', 'name': 'German', 'locale': 'de_DE'},
    {'code': 'el', 'name': 'Greek', 'locale': 'el_GR'},
    {'code': 'gu', 'name': 'Gujarati', 'locale': 'gu_IN'},
    {'code': 'ht', 'name': 'Haitian Creole', 'locale': 'ht_HT'},
    {'code': 'ha', 'name': 'Hausa', 'locale': 'ha_NG'},
    {'code': 'haw', 'name': 'Hawaiian', 'locale': 'haw_US'},
    {'code': 'he', 'name': 'Hebrew', 'locale': 'he_IL'},
    {'code': 'hi', 'name': 'Hindi', 'locale': 'hi_IN'},
    {'code': 'hmn', 'name': 'Hmong', 'locale': 'hmn_CN'},
    {'code': 'hu', 'name': 'Hungarian', 'locale': 'hu_HU'},
    {'code': 'is', 'name': 'Icelandic', 'locale': 'is_IS'},
    {'code': 'ig', 'name': 'Igbo', 'locale': 'ig_NG'},
    {'code': 'id', 'name': 'Indonesian', 'locale': 'id_ID'},
    {'code': 'ga', 'name': 'Irish', 'locale': 'ga_IE'},
    {'code': 'it', 'name': 'Italian', 'locale': 'it_IT'},
    {'code': 'ja', 'name': 'Japanese', 'locale': 'ja_JP'},
    {'code': 'jw', 'name': 'Javanese', 'locale': 'jw_ID'},
    {'code': 'kn', 'name': 'Kannada', 'locale': 'kn_IN'},
    {'code': 'kk', 'name': 'Kazakh', 'locale': 'kk_KZ'},
    {'code': 'km', 'name': 'Khmer', 'locale': 'km_KH'},
    {'code': 'ko', 'name': 'Korean', 'locale': 'ko_KR'},
    {'code': 'ku', 'name': 'Kurdish (Kurmanji)', 'locale': 'ku_IQ'},
    {'code': 'ky', 'name': 'Kyrgyz', 'locale': 'ky_KG'},
    {'code': 'lo', 'name': 'Lao', 'locale': 'lo_LA'},
    {'code': 'la', 'name': 'Latin', 'locale': 'la_VA'},
    {'code': 'lv', 'name': 'Latvian', 'locale': 'lv_LV'},
    {'code': 'lt', 'name': 'Lithuanian', 'locale': 'lt_LT'},
    {'code': 'lb', 'name': 'Luxembourgish', 'locale': 'lb_LU'},
    {'code': 'mk', 'name': 'Macedonian', 'locale': 'mk_MK'},
    {'code': 'mg', 'name': 'Malagasy', 'locale': 'mg_MG'},
    {'code': 'ms', 'name': 'Malay', 'locale': 'ms_MY'},
    {'code': 'ml', 'name': 'Malayalam', 'locale': 'ml_IN'},
    {'code': 'mt', 'name': 'Maltese', 'locale': 'mt_MT'},
    {'code': 'mi', 'name': 'Maori', 'locale': 'mi_NZ'},
    {'code': 'mr', 'name': 'Marathi', 'locale': 'mr_IN'},
    {'code': 'mn', 'name': 'Mongolian', 'locale': 'mn_MN'},
    {'code': 'my', 'name': 'Myanmar (Burmese)', 'locale': 'my_MM'},
    {'code': 'ne', 'name': 'Nepali', 'locale': 'ne_NP'},
    {'code': 'no', 'name': 'Norwegian', 'locale': 'no_NO'},
    {'code': 'or', 'name': 'Odia (Oriya)', 'locale': 'or_IN'},
    {'code': 'ps', 'name': 'Pashto', 'locale': 'ps_AF'},
    {'code': 'fa', 'name': 'Persian', 'locale': 'fa_IR'},
    {'code': 'pl', 'name': 'Polish', 'locale': 'pl_PL'},
    {'code': 'pt', 'name': 'Portuguese', 'locale': 'pt_PT'},
    {'code': 'pa', 'name': 'Punjabi', 'locale': 'pa_IN'},
    {'code': 'ro', 'name': 'Romanian', 'locale': 'ro_RO'},
    {'code': 'ru', 'name': 'Russian', 'locale': 'ru_RU'},
    {'code': 'sm', 'name': 'Samoan', 'locale': 'sm_WS'},
    {'code': 'gd', 'name': 'Scots Gaelic', 'locale': 'gd_GB'},
    {'code': 'sr', 'name': 'Serbian', 'locale': 'sr_RS'},
    {'code': 'st', 'name': 'Sesotho', 'locale': 'st_ZA'},
    {'code': 'sn', 'name': 'Shona', 'locale': 'sn_ZW'},
    {'code': 'sd', 'name': 'Sindhi', 'locale': 'sd_PK'},
    {'code': 'si', 'name': 'Sinhala', 'locale': 'si_LK'},
    {'code': 'sk', 'name': 'Slovak', 'locale': 'sk_SK'},
    {'code': 'sl', 'name': 'Slovenian', 'locale': 'sl_SI'},
    {'code': 'so', 'name': 'Somali', 'locale': 'so_SO'},
    {'code': 'es', 'name': 'Spanish', 'locale': 'es_ES'},
    {'code': 'su', 'name': 'Sundanese', 'locale': 'su_ID'},
    {'code': 'sw', 'name': 'Swahili', 'locale': 'sw_TZ'},
    {'code': 'sv', 'name': 'Swedish', 'locale': 'sv_SE'},
    {'code': 'tg', 'name': 'Tajik', 'locale': 'tg_TJ'},
    {'code': 'ta', 'name': 'Tamil', 'locale': 'ta_IN'},
    {'code': 'te', 'name': 'Telugu', 'locale': 'te_IN'},
    {'code': 'th', 'name': 'Thai', 'locale': 'th_TH'},
    {'code': 'tr', 'name': 'Turkish', 'locale': 'tr_TR'},
    {'code': 'uk', 'name': 'Ukrainian', 'locale': 'uk_UA'},
    {'code': 'ur', 'name': 'Urdu', 'locale': 'ur_PK'},
    {'code': 'ug', 'name': 'Uyghur', 'locale': 'ug_CN'},
    {'code': 'uz', 'name': 'Uzbek', 'locale': 'uz_UZ'},
    {'code': 'vi', 'name': 'Vietnamese', 'locale': 'vi_VN'},
    {'code': 'cy', 'name': 'Welsh', 'locale': 'cy_GB'},
    {'code': 'xh', 'name': 'Xhosa', 'locale': 'xh_ZA'},
    {'code': 'yi', 'name': 'Yiddish', 'locale': 'yi_IL'},
    {'code': 'yo', 'name': 'Yoruba', 'locale': 'yo_NG'},
    {'code': 'zu', 'name': 'Zulu', 'locale': 'zu_ZA'},
  ];

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
