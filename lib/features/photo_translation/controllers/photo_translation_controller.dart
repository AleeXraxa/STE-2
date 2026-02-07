import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/constants/languages.dart';
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

  final List<Map<String, String>> supportedLanguages =
      SupportedLanguages.listNoLocale;

  Future<void> scanImage() async {
    try {
      errorMessage.value = '';
      recognizedText.value = '';
      translatedText.value = '';
      translationError.value = '';

      final granted = await PermissionService.requestCamera();
      if (!granted) {
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
      translationError.value = '';

      final granted = await PermissionService.requestPhotos();
      if (!granted) {
        errorMessage.value = 'Gallery permission is required';
        return;
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
