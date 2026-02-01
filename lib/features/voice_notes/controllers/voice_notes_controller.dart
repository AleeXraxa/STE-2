import 'dart:io';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';
import '../../../core/services/database_service.dart';
import '../models/voice_note.dart';

class VoiceNotesController extends GetxController {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final DatabaseService _databaseService = DatabaseService();

  RxBool isRecording = false.obs;
  RxBool isPlaying = false.obs;
  RxInt recordingDuration = 0.obs;
  RxInt currentPlayingIndex = (-1).obs;
  RxList<VoiceNote> voiceNotes = <VoiceNote>[].obs;

  // Current recording state
  String? _currentFilePath;
  late int _recordingStartTime;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
    _loadVoiceNotes();
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) {
        print('Speech status: $status');
      },
      onError: (error) {
        print('Speech error: $error');
        Get.snackbar('Error', 'Speech recognition error: ${error.errorMsg}');
      },
    );
  }

  Future<void> _loadVoiceNotes() async {
    try {
      final notes = await _databaseService.getVoiceNotes();
      voiceNotes.addAll(notes);
    } catch (e) {
      print('Error loading voice notes: $e');
      Get.snackbar('Error', 'Failed to load voice notes');
    }
  }

  Future<void> requestPermissions() async {
    // Check and request microphone permission (only required for speech recognition)
    var microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      microphoneStatus = await Permission.microphone.request();
      if (!microphoneStatus.isGranted) {
        Get.snackbar('Permission Denied', 'Microphone permission is required');
        return;
      }
    }

    // Note: Storage permission is not required for database operations
    // The database is stored in the app's private documents directory
  }

  Future<void> startRecording() async {
    await requestPermissions();

    if (!_speechToText.isAvailable) {
      Get.snackbar('Error', 'Speech recognition not available');
      return;
    }

    isRecording.value = true;
    recordingDuration.value = 0;
    _recordingStartTime = DateTime.now().millisecondsSinceEpoch;

    // Start recording with transcription
    await _speechToText.listen(
      listenMode: ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        // We'll handle transcription later if needed
        if (result.finalResult) {
          print('Recorded text: ${result.recognizedWords}');
        }
      },
    );

    // Start duration timer
    _startDurationTimer();
  }

  void _startDurationTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (isRecording.value) {
        recordingDuration.value++;
        _startDurationTimer();
      }
    });
  }

  Future<void> stopRecording() async {
    isRecording.value = false;
    await _speechToText.stop();

    // Create a new voice note
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final title = _formatDateTime(DateTime.now());
    final filePath = 'voice_notes/$id.wav'; // Placeholder path

    final newNote = VoiceNote(
      id: id,
      title: title,
      filePath: filePath,
      createdAt: DateTime.now(),
      duration: recordingDuration.value,
    );

    try {
      await _databaseService.insertVoiceNote(newNote);
      voiceNotes.add(newNote);
      Get.snackbar('Success', 'Voice note saved');
    } catch (e) {
      print('Error saving voice note: $e');
      Get.snackbar('Error', 'Failed to save voice note');
    }

    recordingDuration.value = 0;
  }

  Future<void> playVoiceNote(int index) async {
    if (currentPlayingIndex.value == index) {
      // Stop current playback
      await _flutterTts.stop();
      currentPlayingIndex.value = -1;
      isPlaying.value = false;
    } else {
      // Stop any ongoing playback
      if (currentPlayingIndex.value != -1) {
        await _flutterTts.stop();
      }

      currentPlayingIndex.value = index;
      isPlaying.value = true;

      // For demo purposes, we'll just speak the note title
      // In real implementation, we would play the audio file
      final note = voiceNotes[index];
      await _flutterTts.speak('Playing voice note: ${note.title}');

      // Simulate playback duration
      Future.delayed(Duration(seconds: note.duration), () {
        if (currentPlayingIndex.value == index) {
          currentPlayingIndex.value = -1;
          isPlaying.value = false;
        }
      });
    }
  }

  Future<void> deleteVoiceNote(int index) async {
    if (currentPlayingIndex.value == index) {
      await _flutterTts.stop();
      currentPlayingIndex.value = -1;
      isPlaying.value = false;
    }

    try {
      final note = voiceNotes[index];
      await _databaseService.deleteVoiceNote(note.id);
      voiceNotes.removeAt(index);
      Get.snackbar('Success', 'Voice note deleted');
    } catch (e) {
      print('Error deleting voice note: $e');
      Get.snackbar('Error', 'Failed to delete voice note');
    }
  }

  Future<void> renameVoiceNote(int index, String newTitle) async {
    try {
      final updatedNote = voiceNotes[index].copyWith(title: newTitle);
      await _databaseService.updateVoiceNote(updatedNote);
      voiceNotes[index] = updatedNote;
    } catch (e) {
      print('Error renaming voice note: $e');
      Get.snackbar('Error', 'Failed to rename voice note');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return 'Note ${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _flutterTts.stop();
    super.onClose();
  }
}
