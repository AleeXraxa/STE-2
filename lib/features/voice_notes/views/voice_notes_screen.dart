import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/text_styles.dart';
import '../../assistant/services/ai_service.dart';
import '../controllers/voice_notes_controller.dart';
import '../models/voice_note.dart';

class VoiceNotesScreen extends StatefulWidget {
  @override
  _VoiceNotesScreenState createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen>
    with TickerProviderStateMixin {
  late VoiceNotesController controller;

  late AnimationController _animationController;
  late Animation<double> _bottomFadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.find<VoiceNotesController>();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bottomFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 0.6, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatItemIndex(int value) {
    return value.toString().padLeft(2, '0');
  }

  Future<void> _selectRecordingLanguageAndStart() async {
    final languages = [
      'English',
      'Urdu',
      'Hindi',
      'Arabic',
      'Spanish',
      'French',
      'German',
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Recording Language',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...languages.map(
                  (lang) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      lang,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    trailing: lang == controller.selectedLanguage.value
                        ? const Icon(Icons.check, color: Color(0xFF0F172A))
                        : null,
                    onTap: () => Navigator.of(context).pop(lang),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    controller.selectedLanguage.value = selected;
    await controller.startRecording();
  }

  void _showTranscriptSheet(VoiceNote note) {
    final transcript = note.transcript.trim();
    final aiService = AIService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedLanguage = 'English';
        String translatedText = '';
        bool isTranslating = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> translateTranscript() async {
              if (transcript.isEmpty) return;
              setSheetState(() {
                isTranslating = true;
              });
              String result = '';
              try {
                result = await aiService
                    .translateText(
                      transcript,
                      targetLanguage: selectedLanguage,
                    )
                    .timeout(const Duration(seconds: 25));
              } catch (_) {
                // handled below
              }
              if (!context.mounted) return;
              setSheetState(() {
                translatedText = result;
                isTranslating = false;
              });
              if (result.trim().isEmpty) {
                Get.snackbar(
                  'Translation',
                  'Unable to translate right now. Please try again.',
                );
              }
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Transcript',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          transcript.isEmpty
                              ? 'No transcript saved.'
                              : transcript,
                          style: AppTextStyles.body.copyWith(
                            color: const Color(0xFF0F172A),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Translate',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.translate,
                              size: 18, color: Color(0xFF0F172A)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final languages = [
                                  'English',
                                  'Urdu',
                                  'Hindi',
                                  'Arabic',
                                  'Spanish',
                                  'French',
                                  'German',
                                ];
                                final selected =
                                    await showModalBottomSheet<String>(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) {
                                    return Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 16, 20, 24),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      child: SafeArea(
                                        top: false,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 44,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.black12,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Select Language',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ...languages.map(
                                              (lang) => ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(
                                                  lang,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                trailing: lang ==
                                                        selectedLanguage
                                                    ? const Icon(Icons.check,
                                                        color:
                                                            Color(0xFF0F172A))
                                                    : null,
                                                onTap: () =>
                                                    Navigator.of(context)
                                                        .pop(lang),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                                if (selected == null) return;
                                setSheetState(() {
                                  selectedLanguage = selected;
                                });
                                await translateTranscript();
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedLanguage,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: transcript.isEmpty || isTranslating
                                  ? null
                                  : () => translateTranscript(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isTranslating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text('Translate'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isTranslating) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: Color(0xFFE2E8F0),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                    if (translatedText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SelectableText(
                          translatedText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: transcript.isEmpty
                                ? null
                                : () {
                                    Clipboard.setData(
                                        ClipboardData(text: transcript));
                                    Get.snackbar('Copied',
                                        'Transcript copied to clipboard');
                                  },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFF334155)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.16),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: note.filePath.isEmpty
                                  ? null
                                  : () {
                                      final idx = controller.voiceNotes
                                          .indexWhere((n) => n.id == note.id);
                                      if (idx == -1) {
                                        Get.snackbar(
                                            'Transcription', 'Note not found');
                                        return;
                                      }
                                      controller.retryTranscription(idx);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_fix_high, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Re-Transcribe',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final value =
        unitIndex == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$value ${units[unitIndex]}';
  }

  Widget _buildLevelBars() {
    return Obx(() {
      final level = controller.audioLevel.value;
      final heights = [
        10 + (level * 30),
        14 + (level * 36),
        18 + (level * 44),
        14 + (level * 36),
        10 + (level * 30),
      ];
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: heights
            .map((h) => Container(
                  width: 6,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ))
            .toList(),
      );
    });
  }

  Widget _buildCountdownOverlay() {
    return Obx(() {
      if (!controller.isCountingDown.value) return const SizedBox.shrink();
      return Container(
        color: Colors.black.withOpacity(0.45),
        alignment: Alignment.center,
        child: Text(
          controller.countdownSeconds.value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });
  }

  Widget _buildRecordingIndicator() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Obx(() => Text(
                                  controller.formatDuration(
                                      controller.recordingDuration.value),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  'Recording audio...',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                _buildLevelBars(),
                const SizedBox(height: 16),
                Text(
                  'Speak clearly into the microphone',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Obx(() => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        controller.liveTranscript.value.isEmpty
                            ? 'Recording...'
                            : controller.liveTranscript.value,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesList() {
    return Expanded(
      child: Obx(() {
        if (controller.voiceNotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F172A).withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.12),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_none,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'No voice notes yet',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Tap the microphone button to start recording',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 10),
          itemCount: controller.voiceNotes.length,
          itemBuilder: (context, index) {
            final note = controller.voiceNotes[index];
            final isBusy =
                controller.isRecording.value || controller.isCountingDown.value;
            final isTranscribing = controller.transcribingIds.contains(note.id);
            final isFailed =
                controller.transcriptionFailedIds.contains(note.id);
            final fileSize = controller.fileSizes[note.id];
            final fileMissing =
                note.filePath.isNotEmpty && !File(note.filePath).existsSync();
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0F172A),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF0F172A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Obx(() => IconButton(
                          icon: Icon(
                            controller.currentPlayingIndex.value == index
                                ? Icons.stop
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: isBusy
                              ? null
                              : () => controller.playVoiceNote(index),
                        )),
                  ),
                ),
                title: Text(
                  'Audio ${_formatItemIndex(index + 1)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      controller.formatDuration(note.duration),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (fileSize != null)
                      Text(
                        _formatFileSize(fileSize),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    Text(
                      '${note.createdAt.month}/${note.createdAt.day} ${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (fileMissing)
                      Text(
                        'Audio missing',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[400],
                        ),
                      ),
                    if (isTranscribing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Transcribing...',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    if (isFailed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFailed)
                      IconButton(
                        icon:
                            const Icon(Icons.refresh, color: Color(0xFF0F172A)),
                        onPressed: isBusy
                            ? null
                            : () => controller.retryTranscription(index),
                      ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFEE2E2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFDC2626),
                        ),
                        onPressed: isBusy
                            ? null
                            : () => controller.deleteVoiceNote(index),
                      ),
                    ),
                  ],
                ),
                onTap: isBusy ? null : () => _showTranscriptSheet(note),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgTop = Color(0xFF0F172A);
    const Color bgBottom = Color(0xFF1E293B);
    const Color accent = Color(0xFFFB7185);
    const Color accentDark = Color(0xFFE11D48);
    const Color textPrimary = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgTop,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Voice Notes',
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
        child: Stack(
          children: [
            Column(
              children: [
                Obx(() {
                  if (controller.isRecording.value) {
                    return _buildRecordingIndicator();
                  }
                  return _buildVoiceNotesList();
                }),
                Obx(() {
                  if (!controller.isTranscribing.value) {
                    return const SizedBox.shrink();
                  }
                  return const LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(0xFFFB7185),
                    backgroundColor: Colors.white24,
                  );
                }),
                FadeTransition(
                  opacity: _bottomFadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Obx(() {
                      if (controller.isRecording.value) {
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: controller.stopRecording,
                                icon: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                label: Text(
                                  'Stop',
                                  style: AppTextStyles.button.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shadowColor: accent.withOpacity(0.35),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                    vertical: 16.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: controller.cancelRecording,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white54,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                    vertical: 16.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: AppTextStyles.button.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return ElevatedButton.icon(
                        onPressed: controller.isCountingDown.value
                            ? null
                            : _selectRecordingLanguageAndStart,
                        icon: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: Text(
                          controller.isCountingDown.value
                              ? 'Get Ready...'
                              : 'Start Recording',
                          style: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentDark,
                          shadowColor: accent.withOpacity(0.35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40.0,
                            vertical: 18.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            _buildCountdownOverlay(),
          ],
        ),
      ),
    );
  }
}
