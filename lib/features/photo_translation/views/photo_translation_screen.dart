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
    const Color bgTop = Color(0xFF0F172A);
    const Color bgBottom = Color(0xFF1E293B);
    const Color accent = Color(0xFF34D399);
    const Color accentDark = Color(0xFF059669);
    const Color panel = Color(0xFFF8FAFC);
    const Color textPrimary = Color(0xFFF8FAFC);
    const Color textMuted = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgTop,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Photo Translation',
          style: AppTextStyles.heading.copyWith(
            fontSize: 20,
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Obx(() {
            final imageFile = controller.imageFile.value;
            final isProcessing = controller.isProcessing.value;
            final text = controller.recognizedText.value;
            final error = controller.errorMessage.value;

            if (imageFile == null) {
              return _buildPrompt(
                isProcessing: isProcessing,
                accent: accent,
                accentDark: accentDark,
                textMuted: textMuted,
              );
            }

            return Column(
              children: [
                _buildLanguageBar(context, panel),
                const SizedBox(height: 12),
                if (isProcessing) ...[
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
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
                            panel: panel,
                            accentDark: accentDark,
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
                            panel: panel,
                            accentDark: accentDark,
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
                _buildActions(accentDark),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPrompt({
    required bool isProcessing,
    required Color accent,
    required Color accentDark,
    required Color textMuted,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 60,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Scan an Image',
            style: AppTextStyles.heading.copyWith(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Capture a photo to extract text',
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildActions(accentDark),
        ],
      ),
    );
  }

  Widget _buildActions(Color accentDark) {
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
              backgroundColor: accentDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageBar(BuildContext context, Color panel) {
    return Obx(() {
      final detected = controller.detectedLanguageName.value;
      final target = controller.selectedTargetLanguageName.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: panel,
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
              color: const Color(0xFF059669),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String body,
    required Color panel,
    required Color accentDark,
    bool showCopy = false,
  }) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
                      color: accentDark,
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
                  icon: Icon(Icons.copy, color: accentDark),
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
