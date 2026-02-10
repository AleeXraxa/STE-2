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
  var isProcessing = false.obs;
  var speechAvailable = false.obs;
  var lastDetectedLanguage = ''.obs;
  var currentStatus = 'Ready to start'.obs;
  var messages = <FreeTalkMessage>[].obs;

  // Search functionality
  var searchQuery = ''.obs;
  var filteredLanguages = <Map<String, String>>[].obs;

  final List<Map<String, String>> supportedLanguages = SupportedLanguages.list;

  bool _isProcessing = false;
  bool _localeRetry = false;
  String _currentListenLanguage = 'en';
  String? _nextListenLanguage;
  String? _lastTextScript;
  String? _lastTranscript;
  bool _speechError = false;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
    // Initialize filtered languages
    filteredLanguages.value = supportedLanguages;
  }

  Future<void> _initializeSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (isListening.value) {
            isListening.value = false;
            currentStatus.value = 'Stopped';
          }
        }
      },
      onError: (error) {
        if (error.errorMsg == 'error_speech_timeout') {
          isListening.value = false;
          currentStatus.value = 'Voice not detected';
          Get.snackbar('Speech Recognition', 'Voice not detected');
          return;
        }
        if (error.errorMsg == 'error_no_match') {
          isListening.value = false;
          currentStatus.value = 'Please speak in selected languages only';
          Get.snackbar(
              'Speech Recognition', 'Please speak in selected languages only');
          return;
        }
        _speechError = true;
        isListening.value = false;
        currentStatus.value = 'Speech recognition unavailable';
        _speechToText.cancel();
        Get.snackbar('Speech Recognition',
            'Error: ${error.errorMsg}. Please enable a speech service.');
      },
    );
    speechAvailable.value = available;
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
      if (!speechAvailable.value) {
        currentStatus.value = 'Speech recognition not available';
        Get.snackbar(
            'Speech Recognition', 'Speech recognition is not available.');
        return;
      }
      if (_speechError) {
        Get.snackbar('Speech Recognition',
            'Speech service not available on device. Please enable Google Speech Services.');
        return;
      }
      final micGranted = await PermissionService.requestMicrophone();
      if (!micGranted) {
        currentStatus.value = 'Microphone permission required';
        Get.snackbar('Permission', 'Microphone permission is required');
        return;
      }
      // Check Bluetooth connection
      final bluetoothService = Get.find<BluetoothService>();
      if (bluetoothService.connectedDeviceName.value.isEmpty &&
          !bluetoothService.isClassicConnected.value) {
        currentStatus.value = 'Connect earbuds to continue';
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
    if (_isProcessing || isProcessing.value) return;
    if (_speechToText.isListening) return;
    _localeRetry = false;

    final listenLang = _nextListenLanguage ?? lastDetectedLanguage.value;
    final locale = supportedLanguages.firstWhere(
        (lang) => lang['code'] == listenLang,
        orElse: () => {'locale': 'en_US'})['locale']!;
    _currentListenLanguage = listenLang;
    _nextListenLanguage = null;
    print(
        '[FreeTalk] START listen locale=$locale lang=$_currentListenLanguage');

    await _speechToText.listen(
      onResult: (result) async {
        print(
            '[FreeTalk] RESULT final=${result.finalResult} confidence=${result.hasConfidenceRating ? result.confidence : 'n/a'} words="${result.recognizedWords}"');
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          if (!_localeRetry &&
              _shouldRetryWithOtherLocale(result.recognizedWords)) {
            print('[FreeTalk] Retry with other locale (script mismatch)');
            _localeRetry = true;
            lastDetectedLanguage.value =
                lastDetectedLanguage.value == languageA.value
                    ? languageB.value
                    : languageA.value;
            await _speechToText.stop();
            await _startListening();
            return;
          }
          if (!_localeRetry &&
              result.hasConfidenceRating &&
              result.confidence < 0.6 &&
              (lastDetectedLanguage.value == languageA.value ||
                  lastDetectedLanguage.value == languageB.value)) {
            print('[FreeTalk] Retry with other locale (low confidence)');
            _localeRetry = true;
            lastDetectedLanguage.value =
                lastDetectedLanguage.value == languageA.value
                    ? languageB.value
                    : languageA.value;
            await _speechToText.stop();
            await _startListening();
            return;
          }
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
    isProcessing.value = true;
    print('[FreeTalk] TRANSCRIPT="$speech"');
    _lastTranscript = speech;
    _lastTextScript = _detectScript(speech);
    if (_lastTextScript != null) {
      print('[FreeTalk] SCRIPT=$_lastTextScript');
    }
    // Detect language
    print(
        '[FreeTalk] DETECT start (A=${languageA.value}, B=${languageB.value}, last=${lastDetectedLanguage.value})');
    String detectedLang = await _detectLanguage(speech);
    print('[FreeTalk] DETECT result=$detectedLang');

    // If not one of the two languages, use inference or last detected
    if (!_matchesLanguageCode(detectedLang, languageA.value) &&
        !_matchesLanguageCode(detectedLang, languageB.value)) {
      final inferred = _inferLanguageFromScript(
          speech, languageA.value, languageB.value);
      if (inferred != null) {
        detectedLang = inferred;
      } else {
        currentStatus.value =
            'Detected outside selected languages. Using last detected.';
        detectedLang = lastDetectedLanguage.value;
      }
    }
    detectedLang = _normalizeToSelected(detectedLang, languageA.value,
        languageB.value, lastDetectedLanguage.value);
    print('[FreeTalk] DETECT normalized=$detectedLang');

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
    print('[FreeTalk] TRANSLATE from=$detectedLang to=$targetLang');

    // Translate
    try {
      currentStatus.value = 'Translating...';
      var translation = await translator.translate(speech,
          from: detectedLang, to: targetLang);

      // Add message to chat
      messages.add(FreeTalkMessage.create(
          normalizedOriginal, translation.text, detectedLang));
      update();

      // Translation completed
      currentStatus.value = 'Translation completed';

      if (_languagesUseDifferentScripts(languageA.value, languageB.value)) {
        _nextListenLanguage = targetLang;
      } else {
        _nextListenLanguage = detectedLang;
      }

      // Resume listening immediately
      if (isListening.value) {
        await Future.delayed(const Duration(seconds: 1));
        await _startListening();
      }
    } catch (e) {
      currentStatus.value = 'Translation failed';
      Get.snackbar('Translation', 'Translation failed. Please try again.');
      // Resume listening
      if (isListening.value) {
        await Future.delayed(const Duration(seconds: 1));
        await _startListening();
      }
    } finally {
      _isProcessing = false;
      isProcessing.value = false;
      if (_nextListenLanguage == null) {
        _nextListenLanguage = lastDetectedLanguage.value;
      }
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

      // If auto/unknown, fall back to last detected
      if (detected == 'auto') {
        return lastDetectedLanguage.value;
      }

      // If detected language matches one of our selected languages, use it
      if (_matchesLanguageCode(detected, languageA.value) ||
          _matchesLanguageCode(detected, languageB.value)) {
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

  bool _matchesLanguageCode(String detected, String selected) {
    final d = detected.toLowerCase();
    final s = selected.toLowerCase();
    if (d == s) return true;
    if (d.contains('-') && d.split('-').first == s) return true;
    if (s.contains('-') && s.split('-').first == d) return true;
    return d.startsWith(s) || s.startsWith(d);
  }

  String _normalizeToSelected(
    String detected,
    String langA,
    String langB,
    String fallback,
  ) {
    final textScript = _lastTextScript;
    final matchesA = _matchesLanguageCode(detected, langA);
    final matchesB = _matchesLanguageCode(detected, langB);
    if (textScript == 'latin') {
      final hasEnglish = _matchesLanguageCode('en', langA) ||
          _matchesLanguageCode('en', langB);
      final hasRomanPair = _isRomanPair(langA, langB);
      if (hasEnglish && hasRomanPair) {
        final englishScore = _englishKeywordScore(_lastTranscript ?? '');
        final romanScore = _romanUrduHindiScore(_lastTranscript ?? '');
        if (englishScore >= 2 && romanScore == 0) {
          return _matchesLanguageCode('en', langA) ? langA : langB;
        }
        if (romanScore >= 2 && englishScore == 0) {
          return _matchesLanguageCode('en', langA) ? langB : langA;
        }
        if (englishScore >= 3 && englishScore >= romanScore + 2) {
          return _matchesLanguageCode('en', langA) ? langA : langB;
        }
        if (romanScore >= 3 && romanScore >= englishScore + 2) {
          return _matchesLanguageCode('en', langA) ? langB : langA;
        }
      }
    }
    if (matchesA) return langA;
    if (matchesB) return langB;
    if (textScript != null && _languagesUseDifferentScripts(langA, langB)) {
      final aScript = _primaryScriptForLanguage(langA);
      final bScript = _primaryScriptForLanguage(langB);
      if (textScript == 'latin') {
        if (aScript == 'latin' && bScript != 'latin') return langA;
        if (bScript == 'latin' && aScript != 'latin') return langB;
      }
    }
    return fallback;
  }

  String? _inferLanguageFromScript(
      String text, String langA, String langB) {
    final script = _detectScript(text);
    if (script == null) return null;
    if (_languageUsesScript(langA, script)) return langA;
    if (_languageUsesScript(langB, script)) return langB;
    return null;
  }

  String? _detectScript(String text) {
    var hasLatin = false;
    for (final rune in text.runes) {
      if (_inRange(rune, 0x0900, 0x097F)) return 'devanagari';
      if (_inRange(rune, 0x0600, 0x06FF) ||
          _inRange(rune, 0x0750, 0x077F)) return 'arabic';
      if (_inRange(rune, 0x0400, 0x04FF)) return 'cyrillic';
      if (_inRange(rune, 0x3040, 0x309F) ||
          _inRange(rune, 0x30A0, 0x30FF)) return 'japanese';
      if (_inRange(rune, 0xAC00, 0xD7AF)) return 'korean';
      if (_inRange(rune, 0x4E00, 0x9FFF)) return 'chinese';
      if (_inRange(rune, 0x0041, 0x007A)) hasLatin = true;
    }
    if (hasLatin) return 'latin';
    return null;
  }

  bool _shouldRetryWithOtherLocale(String text) {
    final other = _currentListenLanguage == languageA.value
        ? languageB.value
        : languageA.value;
    if (other.isEmpty) return false;
    final script = _detectScript(text);
    if (script == null) return false;
    final currentScript = _primaryScriptForLanguage(_currentListenLanguage);
    final otherScript = _primaryScriptForLanguage(other);
    if (otherScript == null || currentScript == null) return false;
    return script == otherScript && script != currentScript;
  }

  String? _primaryScriptForLanguage(String code) {
    final normalized = code.toLowerCase();
    if (_scriptLanguagesDevanagari.contains(normalized)) return 'devanagari';
    if (_scriptLanguagesArabic.contains(normalized)) return 'arabic';
    if (_scriptLanguagesCyrillic.contains(normalized)) return 'cyrillic';
    if (_scriptLanguagesJapanese.contains(normalized)) return 'japanese';
    if (_scriptLanguagesKorean.contains(normalized)) return 'korean';
    if (_scriptLanguagesChinese.contains(normalized)) return 'chinese';
    return 'latin';
  }

  int _englishKeywordScore(String text) {
    final lower = text.toLowerCase();
    const words = [
      'the',
      'and',
      'what',
      'about',
      'are',
      'you',
      'doing',
      'do',
      'does',
      'did',
      'is',
      'i',
      'am',
      'we',
      'they',
      'absolutely',
      'fine',
      'ok',
      'okay',
      'yes',
      'no',
      'good',
      'great',
      'right',
      'now',
      'bro',
      'hello',
      'thanks',
      'please',
    ];
    var score = 0;
    for (final w in words) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(lower)) {
        score++;
      }
    }
    return score;
  }

  int _romanUrduHindiScore(String text) {
    final lower = text.toLowerCase();
    const words = [
      'aap',
      'tum',
      'kya',
      'kaise',
      'hai',
      'hain',
      'ho',
      'nahin',
      'nahi',
      'haan',
      'han',
      'bhai',
      'yaar',
      'mera',
      'meri',
      'kar',
      'raha',
      'rahe',
      'rahi',
    ];
    var score = 0;
    for (final w in words) {
      if (RegExp(r'\b' + w + r'\b').hasMatch(lower)) {
        score++;
      }
    }
    return score;
  }

  bool _isRomanPair(String a, String b) {
    final hasUr = _matchesLanguageCode('ur', a) || _matchesLanguageCode('ur', b);
    final hasHi = _matchesLanguageCode('hi', a) || _matchesLanguageCode('hi', b);
    return hasUr || hasHi;
  }

  bool _languagesUseDifferentScripts(String a, String b) {
    final sa = _primaryScriptForLanguage(a);
    final sb = _primaryScriptForLanguage(b);
    return sa != null && sb != null && sa != sb;
  }

  bool _languageUsesScript(String code, String script) {
    final normalized = code.toLowerCase();
    switch (script) {
      case 'devanagari':
        return _scriptLanguagesDevanagari.contains(normalized);
      case 'arabic':
        return _scriptLanguagesArabic.contains(normalized);
      case 'cyrillic':
        return _scriptLanguagesCyrillic.contains(normalized);
      case 'japanese':
        return _scriptLanguagesJapanese.contains(normalized);
      case 'korean':
        return _scriptLanguagesKorean.contains(normalized);
      case 'chinese':
        return _scriptLanguagesChinese.contains(normalized);
      default:
        return false;
    }
  }

  bool _inRange(int rune, int start, int end) =>
      rune >= start && rune <= end;

  static const Set<String> _scriptLanguagesDevanagari = {
    'hi',
    'mr',
    'ne',
  };
  static const Set<String> _scriptLanguagesArabic = {
    'ar',
    'ur',
    'fa',
  };
  static const Set<String> _scriptLanguagesCyrillic = {
    'ru',
    'uk',
    'bg',
    'kk',
    'sr',
  };
  static const Set<String> _scriptLanguagesJapanese = {'ja'};
  static const Set<String> _scriptLanguagesKorean = {'ko'};
  static const Set<String> _scriptLanguagesChinese = {
    'zh',
    'zh-cn',
    'zh-hans',
    'zh-sg',
    'zh-tw',
    'zh-hant',
    'zh-hk',
  };
}
