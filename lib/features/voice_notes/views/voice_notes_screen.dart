import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/text_styles.dart';
import '../controllers/voice_notes_controller.dart';

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
    controller = Get.put(VoiceNotesController());
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

  void _showRenameDialog(int index) {
    final TextEditingController textController = TextEditingController(
      text: controller.voiceNotes[index].title,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Voice Note'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter new title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.renameVoiceNote(index, textController.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: Center(
                      child: Obx(() => Text(
                            controller.formatDuration(
                                controller.recordingDuration.value),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Recording...',
            style: AppTextStyles.heading.copyWith(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Speak clearly into the microphone',
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
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
                Icon(
                  Icons.mic_none,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 20),
                Text(
                  'No voice notes yet',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Tap the microphone button to start recording',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: Colors.grey[500],
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
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF003049),
                  ),
                  child: Center(
                    child: Obx(() => IconButton(
                          icon: Icon(
                            controller.currentPlayingIndex.value == index
                                ? Icons.stop
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () => controller.playVoiceNote(index),
                        )),
                  ),
                ),
                title: Text(
                  note.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      controller.formatDuration(note.duration),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      '${note.createdAt.month}/${note.createdAt.day} ${note.createdAt.hour}:${note.createdAt.minute}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFF003049)),
                      onPressed: () => _showRenameDialog(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => controller.deleteVoiceNote(index),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF2F4),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF003049)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Voice Notes',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18,
            color: Color(0xFF003049),
          ),
        ),
        backgroundColor: Color(0xFFEDF2F4),
      ),
      body: Column(
        children: [
          Obx(() {
            if (controller.isRecording.value) {
              return _buildRecordingIndicator();
            }
            return _buildVoiceNotesList();
          }),
          FadeTransition(
            opacity: _bottomFadeAnimation,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Obx(() => ElevatedButton.icon(
                    onPressed: controller.isRecording.value
                        ? controller.stopRecording
                        : controller.startRecording,
                    icon: Icon(
                      controller.isRecording.value ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                    label: Text(
                      controller.isRecording.value ? 'Stop' : 'Start Recording',
                      style: AppTextStyles.button.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isRecording.value
                          ? Colors.red
                          : Color(0xFF003049),
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 16.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
