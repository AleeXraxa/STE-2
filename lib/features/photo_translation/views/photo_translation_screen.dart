import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/text_styles.dart';
import '../controllers/photo_translation_controller.dart';
import 'photo_scan_screen.dart';
import 'language_picker_sheet.dart';

class PhotoTranslationScreen extends StatelessWidget {
  PhotoTranslationScreen({super.key});

  final PhotoTranslationController controller =
      Get.put(PhotoTranslationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003049)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Photo Translation',
          style: AppTextStyles.heading.copyWith(
            fontSize: 20,
            color: const Color(0xFF003049),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFEDF2F4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Obx(() {
          final imageFile = controller.imageFile.value;
          final isProcessing = controller.isProcessing.value;
          final text = controller.recognizedText.value;
          final error = controller.errorMessage.value;

          if (imageFile == null) {
            return _buildPrompt(isProcessing: isProcessing);
          }

          return Column(
            children: [
              _buildLanguageBar(context),
              const SizedBox(height: 12),
              if (isProcessing) ...[
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF003049)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reading text...',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                if (error.isNotEmpty)
                  Text(
                    error,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        _buildResultCard(
                          title: 'Detected Text',
                          body: text.isNotEmpty ? text : 'No text detected.',
                        ),
                        const SizedBox(height: 12),
                        _buildResultCard(
                          title: 'Translated Text',
                          body: controller.isTranslating.value
                              ? 'Translating...'
                              : (controller.translatedText.value.isNotEmpty
                                  ? controller.translatedText.value
                                  : 'No translation.'),
                          showCopy: true,
                        ),
                        if (controller.translationError.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              controller.translationError.value,
                              style: AppTextStyles.body.copyWith(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              _buildActions(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPrompt({required bool isProcessing}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF003049).withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003049).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 60,
              color: Color(0xFF003049),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Scan an Image',
            style: AppTextStyles.heading.copyWith(
              fontSize: 24,
              color: const Color(0xFF003049),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Capture a photo to extract text',
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Get.to(() => const PhotoScanScreen()),
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: Text(
              'Scan Image',
              style: AppTextStyles.button.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003049),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageBar(BuildContext context) {
    return Obx(() {
      final detected = controller.detectedLanguageName.value;
      final target = controller.selectedTargetLanguageName.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Detected: $detected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildTargetSelector(context, target),
          ],
        ),
      );
    });
  }

  Widget _buildTargetSelector(BuildContext context, String currentName) {
    return InkWell(
      onTap: () => showLanguagePickerSheet(
        context: context,
        languages: controller.supportedLanguages,
        selectedCode: controller.selectedTargetLanguage.value,
        onSelected: controller.selectTargetLanguage,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentName,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF003049),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF003049)),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String body,
    bool showCopy = false,
  }) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF003049),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (showCopy)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFF003049)),
                  onPressed: body.trim().isEmpty || body == 'No translation.'
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: body));
                          Get.snackbar('Copied', 'Translated text copied');
                        },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
