import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:translator/translator.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoTranslationController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final GoogleTranslator _translator = GoogleTranslator();

  Rx<File?> imageFile = Rx<File?>(null);
  RxString recognizedText = ''.obs;
  RxString translatedText = ''.obs;
  RxBool isProcessing = false.obs;
  RxString errorMessage = ''.obs;
  RxString translationError = ''.obs;
  RxString detectedLanguageCode = 'unknown'.obs;
  RxString detectedLanguageName = 'Unknown'.obs;
  RxString selectedTargetLanguage = 'en'.obs;
  RxString selectedTargetLanguageName = 'English'.obs;
  RxBool isTranslating = false.obs;
  RxList<OcrBlock> ocrBlocks = <OcrBlock>[].obs;
  Rx<ui.Size?> imageSize = Rx<ui.Size?>(null);

  final List<Map<String, String>> supportedLanguages = [
    {'code': 'af', 'name': 'Afrikaans'},
    {'code': 'sq', 'name': 'Albanian'},
    {'code': 'am', 'name': 'Amharic'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'hy', 'name': 'Armenian'},
    {'code': 'az', 'name': 'Azerbaijani'},
    {'code': 'eu', 'name': 'Basque'},
    {'code': 'be', 'name': 'Belarusian'},
    {'code': 'bn', 'name': 'Bengali'},
    {'code': 'bs', 'name': 'Bosnian'},
    {'code': 'bg', 'name': 'Bulgarian'},
    {'code': 'ca', 'name': 'Catalan'},
    {'code': 'ceb', 'name': 'Cebuano'},
    {'code': 'ny', 'name': 'Chichewa'},
    {'code': 'zh', 'name': 'Chinese (Simplified)'},
    {'code': 'zh-TW', 'name': 'Chinese (Traditional)'},
    {'code': 'co', 'name': 'Corsican'},
    {'code': 'hr', 'name': 'Croatian'},
    {'code': 'cs', 'name': 'Czech'},
    {'code': 'da', 'name': 'Danish'},
    {'code': 'nl', 'name': 'Dutch'},
    {'code': 'en', 'name': 'English'},
    {'code': 'eo', 'name': 'Esperanto'},
    {'code': 'et', 'name': 'Estonian'},
    {'code': 'tl', 'name': 'Filipino'},
    {'code': 'fi', 'name': 'Finnish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'fy', 'name': 'Frisian'},
    {'code': 'gl', 'name': 'Galician'},
    {'code': 'ka', 'name': 'Georgian'},
    {'code': 'de', 'name': 'German'},
    {'code': 'el', 'name': 'Greek'},
    {'code': 'gu', 'name': 'Gujarati'},
    {'code': 'ht', 'name': 'Haitian Creole'},
    {'code': 'ha', 'name': 'Hausa'},
    {'code': 'haw', 'name': 'Hawaiian'},
    {'code': 'he', 'name': 'Hebrew'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'hmn', 'name': 'Hmong'},
    {'code': 'hu', 'name': 'Hungarian'},
    {'code': 'is', 'name': 'Icelandic'},
    {'code': 'ig', 'name': 'Igbo'},
    {'code': 'id', 'name': 'Indonesian'},
    {'code': 'ga', 'name': 'Irish'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'jw', 'name': 'Javanese'},
    {'code': 'kn', 'name': 'Kannada'},
    {'code': 'kk', 'name': 'Kazakh'},
    {'code': 'km', 'name': 'Khmer'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'ku', 'name': 'Kurdish (Kurmanji)'},
    {'code': 'ky', 'name': 'Kyrgyz'},
    {'code': 'lo', 'name': 'Lao'},
    {'code': 'la', 'name': 'Latin'},
    {'code': 'lv', 'name': 'Latvian'},
    {'code': 'lt', 'name': 'Lithuanian'},
    {'code': 'lb', 'name': 'Luxembourgish'},
    {'code': 'mk', 'name': 'Macedonian'},
    {'code': 'mg', 'name': 'Malagasy'},
    {'code': 'ms', 'name': 'Malay'},
    {'code': 'ml', 'name': 'Malayalam'},
    {'code': 'mt', 'name': 'Maltese'},
    {'code': 'mi', 'name': 'Maori'},
    {'code': 'mr', 'name': 'Marathi'},
    {'code': 'mn', 'name': 'Mongolian'},
    {'code': 'my', 'name': 'Myanmar (Burmese)'},
    {'code': 'ne', 'name': 'Nepali'},
    {'code': 'no', 'name': 'Norwegian'},
    {'code': 'or', 'name': 'Odia (Oriya)'},
    {'code': 'ps', 'name': 'Pashto'},
    {'code': 'fa', 'name': 'Persian'},
    {'code': 'pl', 'name': 'Polish'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'pa', 'name': 'Punjabi'},
    {'code': 'ro', 'name': 'Romanian'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'sm', 'name': 'Samoan'},
    {'code': 'gd', 'name': 'Scots Gaelic'},
    {'code': 'sr', 'name': 'Serbian'},
    {'code': 'st', 'name': 'Sesotho'},
    {'code': 'sn', 'name': 'Shona'},
    {'code': 'sd', 'name': 'Sindhi'},
    {'code': 'si', 'name': 'Sinhala'},
    {'code': 'sk', 'name': 'Slovak'},
    {'code': 'sl', 'name': 'Slovenian'},
    {'code': 'so', 'name': 'Somali'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'su', 'name': 'Sundanese'},
    {'code': 'sw', 'name': 'Swahili'},
    {'code': 'sv', 'name': 'Swedish'},
    {'code': 'tg', 'name': 'Tajik'},
    {'code': 'ta', 'name': 'Tamil'},
    {'code': 'te', 'name': 'Telugu'},
    {'code': 'th', 'name': 'Thai'},
    {'code': 'tr', 'name': 'Turkish'},
    {'code': 'uk', 'name': 'Ukrainian'},
    {'code': 'ur', 'name': 'Urdu'},
    {'code': 'ug', 'name': 'Uyghur'},
    {'code': 'uz', 'name': 'Uzbek'},
    {'code': 'vi', 'name': 'Vietnamese'},
    {'code': 'cy', 'name': 'Welsh'},
    {'code': 'xh', 'name': 'Xhosa'},
    {'code': 'yi', 'name': 'Yiddish'},
    {'code': 'yo', 'name': 'Yoruba'},
    {'code': 'zu', 'name': 'Zulu'},
  ];

  Future<void> scanImage() async {
    try {
      errorMessage.value = '';
      recognizedText.value = '';
      translatedText.value = '';
      translationError.value = '';

      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        errorMessage.value = 'Camera permission is required';
        return;
      }

      final picked =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (picked == null) return;

      imageFile.value = File(picked.path);
      await _runOcr(imageFile.value!);
    } catch (e) {
      errorMessage.value = 'Failed to scan image';
    }
  }

  Future<void> processCapturedImage(File file) async {
    try {
      errorMessage.value = '';
      recognizedText.value = '';
      translatedText.value = '';
      translationError.value = '';
      ocrBlocks.clear();
      imageFile.value = file;
      imageSize.value = await _decodeImageSize(file);
      await _runOcr(file);
    } catch (e) {
      errorMessage.value = 'Failed to process image';
    }
  }

  Future<void> pickFromGallery() async {
    try {
      errorMessage.value = '';
      recognizedText.value = '';
      translatedText.value = '';

      final photoStatus = await Permission.photos.request();
      if (!photoStatus.isGranted) {
        // Android 13+ uses READ_MEDIA_IMAGES; older uses storage.
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          errorMessage.value = 'Gallery permission is required';
          return;
        }
      }

      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;

      imageFile.value = File(picked.path);
      await _runOcr(imageFile.value!);
    } catch (e) {
      errorMessage.value = 'Failed to pick image';
    }
  }

  Future<void> _runOcr(File file, {bool allowRecrop = true}) async {
    try {
      isProcessing.value = true;
      final inputImage = InputImage.fromFile(file);
      final result = await _textRecognizer.processImage(inputImage);
      recognizedText.value = result.text.trim();
      ocrBlocks.clear();
      for (final block in result.blocks) {
        ocrBlocks.add(
          OcrBlock(
            rect: block.boundingBox,
            text: block.text.trim(),
          ),
        );
      }
      if (recognizedText.value.isEmpty) {
        recognizedText.value = 'No text detected.';
        translatedText.value = '';
        translationError.value = '';
        detectedLanguageCode.value = 'unknown';
        detectedLanguageName.value = 'Unknown';
        return;
      }
      if (allowRecrop) {
        final croppedFile = await _autoCropToTextBlocks(file, result);
        if (croppedFile != null) {
          imageFile.value = croppedFile;
          imageSize.value = await _decodeImageSize(croppedFile);
          await _runOcr(croppedFile, allowRecrop: false);
          return;
        }
      }
      await _detectAndTranslate(recognizedText.value);
      await _translateBlocks();
    } catch (e) {
      errorMessage.value = 'Text recognition failed';
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _detectAndTranslate(String text) async {
    try {
      isTranslating.value = true;
      translationError.value = '';
      final translated = await _translator.translate(
        text,
        from: 'auto',
        to: selectedTargetLanguage.value,
      );
      translatedText.value = translated.text.trim();

      final detectedCode = translated.sourceLanguage.code;
      detectedLanguageCode.value = detectedCode;
      detectedLanguageName.value =
          _languageNameForCode(detectedCode) ?? detectedCode;
    } catch (e) {
      translatedText.value = '';
      translationError.value = 'Translation requires an internet connection.';
    } finally {
      isTranslating.value = false;
    }
  }

  Future<void> _translateBlocks() async {
    if (ocrBlocks.isEmpty) return;
    final fromLang = detectedLanguageCode.value == 'unknown'
        ? 'auto'
        : detectedLanguageCode.value;
    for (final block in ocrBlocks) {
      if (block.text.isEmpty) continue;
      try {
        final translated = await _translator.translate(
          block.text,
          from: fromLang,
          to: selectedTargetLanguage.value,
        );
        block.translated = translated.text.trim();
      } catch (_) {
        block.translated = block.text;
      }
    }
    ocrBlocks.refresh();
  }

  void selectTargetLanguage(String code, String name) {
    selectedTargetLanguage.value = code;
    selectedTargetLanguageName.value = name;
    if (recognizedText.value.isNotEmpty &&
        recognizedText.value != 'No text detected.') {
      _detectAndTranslate(recognizedText.value);
      _translateBlocks();
    }
  }

  String? _languageNameForCode(String code) {
    for (final lang in supportedLanguages) {
      if (lang['code'] == code) return lang['name'];
    }
    return null;
  }

  Future<ui.Size> _decodeImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  Future<File?> _autoCropToTextBlocks(File file, RecognizedText result) async {
    if (result.blocks.isEmpty) return null;

    double left = result.blocks.first.boundingBox.left;
    double top = result.blocks.first.boundingBox.top;
    double right = result.blocks.first.boundingBox.right;
    double bottom = result.blocks.first.boundingBox.bottom;

    for (final block in result.blocks) {
      left = left < block.boundingBox.left ? left : block.boundingBox.left;
      top = top < block.boundingBox.top ? top : block.boundingBox.top;
      right = right > block.boundingBox.right ? right : block.boundingBox.right;
      bottom =
          bottom > block.boundingBox.bottom ? bottom : block.boundingBox.bottom;
    }

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final paddingX = (decoded.width * 0.05).round();
    final paddingY = (decoded.height * 0.05).round();

    int cropLeft = (left.round() - paddingX).clamp(0, decoded.width - 1);
    int cropTop = (top.round() - paddingY).clamp(0, decoded.height - 1);
    int cropRight =
        (right.round() + paddingX).clamp(cropLeft + 1, decoded.width);
    int cropBottom =
        (bottom.round() + paddingY).clamp(cropTop + 1, decoded.height);

    if (cropRight - cropLeft < 10 || cropBottom - cropTop < 10) {
      return null;
    }

    final cropped = img.copyCrop(
      decoded,
      x: cropLeft,
      y: cropTop,
      width: cropRight - cropLeft,
      height: cropBottom - cropTop,
    );

    final dir = await getTemporaryDirectory();
    final outPath = p.join(
        dir.path, 'photo_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final outFile = File(outPath);
    await outFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));
    return outFile;
  }

  @override
  void onClose() {
    _textRecognizer.close();
    super.onClose();
  }
}

class OcrBlock {
  OcrBlock({required this.rect, required this.text, this.translated = ''});
  final Rect rect;
  final String text;
  String translated;
}
