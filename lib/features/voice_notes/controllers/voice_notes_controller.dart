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
  bool _restartTranscription = false;
  String _transcriptBuffer = '';
  bool _speechReady = false;
  bool _speechInitializing = false;

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
    _transcriptBuffer = '';
    isTranscribing.value = false;
    await _startTranscription();

    isRecording.value = true;
    recordingDuration.value = 0;

    _currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentFilePath = null;

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
    _speechReady = false;
    _speechInitializing = false;
    isTranscribing.value = false;

    _finalizeTranscript();

    // Create a new voice note
    final id =
        _currentRecordingId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final transcript = liveTranscript.value.trim();
    final title = transcript.isNotEmpty
        ? (transcript.length > 40
            ? '${transcript.substring(0, 40)}...'
            : transcript)
        : _formatDateTime(DateTime.now());
    final filePath = _currentFilePath ?? '';

    if (transcript.isEmpty && filePath.isEmpty) {
      Get.snackbar('Recording', 'Nothing recorded');
      recordingDuration.value = 0;
      _currentFilePath = null;
      _currentRecordingId = null;
      liveTranscript.value = '';
      return;
    }

    final newNote = VoiceNote(
      id: id,
      title: title,
      filePath: filePath,
      transcript: transcript,
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
    _transcriptBuffer = '';
  }

  Future<void> _startTranscription() async {
    try {
      await _listenForTranscription();
    } catch (_) {
      isTranscribing.value = false;
      Get.snackbar('Speech Recognition', 'Failed to start listening');
    }
  }

  void _restartLiveTranscription() {
    if (_restartTranscription || !isRecording.value) return;
    _restartTranscription = true;
    Future.delayed(const Duration(milliseconds: 300), () async {
      _restartTranscription = false;
      if (isRecording.value) {
        await _listenForTranscription();
      }
    });
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechReady) return true;
    if (_speechInitializing) return false;
    _speechInitializing = true;
    final available = await _speechToText.initialize(
      onStatus: (status) {
        print('VoiceNotes STT status: $status');
        if (status == 'notListening' || status == 'done') {
          if (isRecording.value) {
            stopRecording();
            return;
          }
          isTranscribing.value = false;
        }
      },
      onError: (error) {
        print('VoiceNotes STT error: $error');
        if (isRecording.value) {
          stopRecording();
          return;
        }
        isTranscribing.value = false;
      },
    );
    _speechInitializing = false;
    _speechReady = available;
    if (!available) {
      Get.snackbar('Speech Recognition', 'Speech engine not available');
    }
    return available;
  }

  Future<void> _listenForTranscription() async {
    if (!await _ensureSpeechReady()) return;
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    final systemLocale = await _speechToText.systemLocale();
    final localeId = systemLocale?.localeId;
    print('VoiceNotes STT locale: $localeId');
    isTranscribing.value = true;
    await _speechToText.listen(
      partialResults: true,
      listenMode: ListenMode.dictation,
      localeId: localeId,
      listenFor: const Duration(minutes: 30),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: false,
      onSoundLevelChange: (level) {
        _lastSoundLevel = level;
        if (level > -1.0) {
          print('VoiceNotes STT sound: $level');
        }
      },
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        if (result.finalResult) {
          if (_transcriptBuffer.isEmpty) {
            _transcriptBuffer = words;
          } else {
            _transcriptBuffer = '$_transcriptBuffer\n$words';
          }
          liveTranscript.value = _transcriptBuffer;
        } else {
          if (_transcriptBuffer.isEmpty) {
            liveTranscript.value = words;
          } else {
            liveTranscript.value = '$_transcriptBuffer\n$words';
          }
        }
      },
    );
  }

  void _finalizeTranscript() {
    final current = liveTranscript.value.trim();
    if (current.isEmpty) return;
    final buffer = _transcriptBuffer.trim();
    if (buffer.isEmpty) {
      _transcriptBuffer = current;
      liveTranscript.value = _transcriptBuffer;
      return;
    }
    if (current != buffer) {
      if (current.startsWith(buffer)) {
        final suffix = current.substring(buffer.length).trim();
        if (suffix.isNotEmpty) {
          _transcriptBuffer = '$buffer\n$suffix';
        }
      } else {
        _transcriptBuffer = '$buffer\n$current';
      }
      liveTranscript.value = _transcriptBuffer;
    }
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
        Get.snackbar('Playback', 'No audio saved for this note');
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
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return 'Note $month/$day $hour:$minute';
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
