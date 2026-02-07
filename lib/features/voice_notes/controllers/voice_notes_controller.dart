import 'dart:io';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/services/database_service.dart';
import '../models/voice_note.dart';

class VoiceNotesController extends GetxController {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseService _databaseService = DatabaseService();

  RxBool isRecording = false.obs;
  RxBool isPlaying = false.obs;
  RxInt recordingDuration = 0.obs;
  RxInt currentPlayingIndex = (-1).obs;
  RxList<VoiceNote> voiceNotes = <VoiceNote>[].obs;

  // Current recording state
  String? _currentFilePath;
  String? _currentRecordingId;

  @override
  void onInit() {
    super.onInit();
    _loadVoiceNotes();
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        currentPlayingIndex.value = -1;
        isPlaying.value = false;
      }
    });
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

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Get.snackbar('Permission Denied', 'Microphone permission is required');
      return;
    }

    isRecording.value = true;
    recordingDuration.value = 0;

    _currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
    final documentsDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(p.join(documentsDir.path, 'voice_notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    _currentFilePath = p.join(notesDir.path, '${_currentRecordingId!}.wav');

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 16000,
      ),
      path: _currentFilePath!,
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
    final recordedPath = await _recorder.stop();

    // Create a new voice note
    final id = _currentRecordingId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final title = _formatDateTime(DateTime.now());
    final filePath = recordedPath ?? _currentFilePath;
    if (filePath == null) {
      Get.snackbar('Error', 'Failed to save recording');
      return;
    }

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
    _currentFilePath = null;
    _currentRecordingId = null;
  }

  Future<void> playVoiceNote(int index) async {
    if (currentPlayingIndex.value == index) {
      // Stop current playback
      await _audioPlayer.stop();
      currentPlayingIndex.value = -1;
      isPlaying.value = false;
    } else {
      // Stop any ongoing playback
      if (currentPlayingIndex.value != -1) {
        await _audioPlayer.stop();
      }

      currentPlayingIndex.value = index;
      isPlaying.value = true;

      final note = voiceNotes[index];
      final file = File(note.filePath);
      if (!await file.exists()) {
        Get.snackbar('Error', 'Audio file not found');
        currentPlayingIndex.value = -1;
        isPlaying.value = false;
        return;
      }

      await _audioPlayer.setFilePath(note.filePath);
      await _audioPlayer.play();
    }
  }

  Future<void> deleteVoiceNote(int index) async {
    if (currentPlayingIndex.value == index) {
      await _audioPlayer.stop();
      currentPlayingIndex.value = -1;
      isPlaying.value = false;
    }

    try {
      final note = voiceNotes[index];
      await _databaseService.deleteVoiceNote(note.id);
      final file = File(note.filePath);
      if (await file.exists()) {
        await file.delete();
      }
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
    _audioPlayer.dispose();
    _recorder.dispose();
    super.onClose();
  }
}
