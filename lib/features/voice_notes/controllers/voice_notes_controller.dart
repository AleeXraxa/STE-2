import 'dart:io';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/services/database_service.dart';
import '../models/voice_note.dart';
import '../../../core/services/permission_service.dart';

class VoiceNotesController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseService _databaseService = DatabaseService();
  final SpeechToText _speechToText = SpeechToText();

  RxBool isRecording = false.obs;
  RxBool isPlaying = false.obs;
  RxBool isTranscribing = false.obs;
  RxInt recordingDuration = 0.obs;
  RxInt currentPlayingIndex = (-1).obs;
  RxList<VoiceNote> voiceNotes = <VoiceNote>[].obs;
  RxString liveTranscript = ''.obs;

  // Current recording state
  String? _currentFilePath;
  String? _currentRecordingId;
  double _lastSoundLevel = 0.0;

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

  Future<bool> requestPermissions() async {
    final granted = await PermissionService.requestMicrophone();
    if (!granted) {
      Get.snackbar('Permission Denied', 'Microphone permission is required');
      return false;
    }

    // Note: Storage permission is not required for database operations
    // The database is stored in the app's private documents directory
    return true;
  }

  Future<void> startRecording() async {
    final granted = await requestPermissions();
    if (!granted) {
      return;
    }

    // Initialize speech-to-text for live transcript
    liveTranscript.value = '';
    isTranscribing.value = false;
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      await _speechToText.cancel();

      final available = await _speechToText.initialize(
        onStatus: (status) {
          print('VoiceNotes STT status: $status');
          if (status == 'notListening' || status == 'done') {
            isTranscribing.value = false;
          }
        },
        onError: (error) {
          print('VoiceNotes STT error: $error');
          isTranscribing.value = false;
        },
      );
      if (available) {
        final systemLocale = await _speechToText.systemLocale();
        final localeId = systemLocale?.localeId;
        print('VoiceNotes STT locale: $localeId');
        isTranscribing.value = true;
        await _speechToText.listen(
          partialResults: true,
          listenMode: ListenMode.dictation,
          localeId: localeId,
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: false,
          onSoundLevelChange: (level) {
            _lastSoundLevel = level;
            if (level > -1.0) {
              print('VoiceNotes STT sound: $level');
            }
          },
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              liveTranscript.value = result.recognizedWords;
            }
          },
        );
      } else {
        Get.snackbar('Speech Recognition', 'Speech engine not available');
        return;
      }
    } catch (_) {
      isTranscribing.value = false;
      Get.snackbar('Speech Recognition', 'Failed to start listening');
      return;
    }

    isRecording.value = true;
    recordingDuration.value = 0;

    _currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentFilePath = '';

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
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    await _speechToText.cancel();
    isTranscribing.value = false;

    // Create a new voice note
    final id = _currentRecordingId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final transcript = liveTranscript.value.trim();
    final title = transcript.isNotEmpty
        ? (transcript.length > 40
            ? '${transcript.substring(0, 40)}...'
            : transcript)
        : _formatDateTime(DateTime.now());
    final filePath = _currentFilePath ?? '';

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
      Get.snackbar('Success', 'Transcript saved');
    } catch (e) {
      print('Error saving voice note: $e');
      Get.snackbar('Error', 'Failed to save voice note');
    }

    recordingDuration.value = 0;
    _currentFilePath = null;
    _currentRecordingId = null;
    liveTranscript.value = '';
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
      if (note.filePath.isEmpty) {
        Get.snackbar('Playback', 'No audio saved in live transcript mode');
        currentPlayingIndex.value = -1;
        isPlaying.value = false;
        return;
      }
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
    _speechToText.cancel();
    super.onClose();
  }
}
