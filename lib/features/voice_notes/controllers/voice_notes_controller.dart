import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/services/database_service.dart';
import '../../assistant/services/ai_service.dart';
import '../models/voice_note.dart';
import '../../../core/services/permission_service.dart';

class VoiceNotesController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseService _databaseService = DatabaseService();
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _recorder = AudioRecorder();
  final AIService _aiService = AIService();

  RxBool isRecording = false.obs;
  RxBool isCountingDown = false.obs;
  RxBool isPlaying = false.obs;
  RxBool isTranscribing = false.obs;
  RxInt recordingDuration = 0.obs;
  RxInt countdownSeconds = 0.obs;
  RxInt currentPlayingIndex = (-1).obs;
  RxList<VoiceNote> voiceNotes = <VoiceNote>[].obs;
  RxString liveTranscript = ''.obs;
  RxDouble audioLevel = 0.0.obs;
  RxSet<String> transcribingIds = <String>{}.obs;
  RxSet<String> transcriptionFailedIds = <String>{}.obs;
  RxMap<String, int> fileSizes = <String, int>{}.obs;

  // Current recording state
  String? _currentFilePath;
  String? _currentRecordingId;
  double _lastSoundLevel = 0.0;
  bool _restartTranscription = false;
  String _transcriptBuffer = '';
  bool _speechReady = false;
  bool _speechInitializing = false;
  Timer? _levelTimer;

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
      for (final note in notes) {
        _cacheFileSize(note);
      }
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
    if (isRecording.value || isCountingDown.value) return;
    final granted = await requestPermissions();
    if (!granted) {
      return;
    }

    final countdownOk = await _runCountdown();
    if (!countdownOk) {
      return;
    }

    _currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentFilePath = null;

    final audioStarted = await _startAudioRecording();
    if (!audioStarted) {
      Get.snackbar('Recording', 'Failed to start audio recording');
      return;
    }

    isRecording.value = true;

    // Post-recording transcription only
    liveTranscript.value = '';
    _transcriptBuffer = '';
    isTranscribing.value = false;
    recordingDuration.value = 0;

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
    if (!isRecording.value) return;
    isRecording.value = false;
    _stopLevelTimer();
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    await _speechToText.cancel();
    _speechReady = false;
    _speechInitializing = false;
    isTranscribing.value = false;
    await _stopAudioRecording();

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
      _cacheFileSize(newNote);
    } catch (e) {
      print('Error saving voice note: $e');
      Get.snackbar('Error', 'Failed to save voice note');
    }

    if (filePath.isNotEmpty) {
      _transcribeSavedAudio(id, filePath);
    }

    recordingDuration.value = 0;
    _currentFilePath = null;
    _currentRecordingId = null;
    liveTranscript.value = '';
    _transcriptBuffer = '';
  }

  Future<void> cancelRecording() async {
    if (!isRecording.value && !isCountingDown.value) return;
    isCountingDown.value = false;
    countdownSeconds.value = 0;
    isRecording.value = false;
    _stopLevelTimer();
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    await _speechToText.cancel();
    _speechReady = false;
    _speechInitializing = false;
    isTranscribing.value = false;
    await _stopAudioRecording();
    if (_currentFilePath != null && _currentFilePath!.isNotEmpty) {
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _currentFilePath = null;
    _currentRecordingId = null;
    recordingDuration.value = 0;
    liveTranscript.value = '';
    _transcriptBuffer = '';
  }

  Future<bool> _runCountdown() async {
    isCountingDown.value = true;
    for (var i = 3; i >= 1; i--) {
      countdownSeconds.value = i;
      await Future.delayed(const Duration(seconds: 1));
      if (!isCountingDown.value) {
        countdownSeconds.value = 0;
        return false;
      }
    }
    countdownSeconds.value = 0;
    isCountingDown.value = false;
    return true;
  }

  Future<void> _transcribeSavedAudio(String id, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        Get.snackbar('Transcription', 'Audio file not found');
        return;
      }
      transcribingIds.add(id);
      transcriptionFailedIds.remove(id);
      isTranscribing.value = true;
      final bytes = await file.readAsBytes();
      final text = await _aiService.transcribeAudioBytes(bytes);
      transcribingIds.remove(id);
      isTranscribing.value = false;

      if (text.trim().isEmpty) {
        transcriptionFailedIds.add(id);
        Get.snackbar('Transcription', 'No speech detected');
        return;
      }

      final index = voiceNotes.indexWhere((note) => note.id == id);
      if (index == -1) {
        return;
      }
      final updated = voiceNotes[index].copyWith(transcript: text.trim());
      await _databaseService.updateVoiceNote(updated);
      voiceNotes[index] = updated;
      Get.snackbar('Success', 'Transcription ready');
    } catch (e) {
      transcribingIds.remove(id);
      transcriptionFailedIds.add(id);
      isTranscribing.value = false;
      print('Error transcribing audio: $e');
      Get.snackbar('Transcription', 'Failed to transcribe recording');
    }
  }

  Future<void> retryTranscription(int index) async {
    final note = voiceNotes[index];
    if (note.filePath.isEmpty) {
      Get.snackbar('Transcription', 'Audio file not found');
      return;
    }
    await _transcribeSavedAudio(note.id, note.filePath);
  }

  void _cacheFileSize(VoiceNote note) {
    if (note.filePath.isEmpty) return;
    final file = File(note.filePath);
    file.exists().then((exists) async {
      if (!exists) return;
      final size = await file.length();
      fileSizes[note.id] = size;
    });
  }

  Future<bool> _startAudioRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        return false;
      }
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory(path.join(directory.path, 'voice_notes'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final id = _currentRecordingId ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = path.join(folder.path, '$id.m4a');
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
          androidConfig: AndroidRecordConfig(
            manageBluetooth: false,
            audioSource: AndroidAudioSource.mic,
          ),
        ),
        path: filePath,
      );
      _currentFilePath = filePath;
      _startLevelTimer();
      return true;
    } catch (e) {
      print('Error starting audio recording: $e');
      return false;
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      final recording = await _recorder.isRecording();
      if (!recording) return;
      final stoppedPath = await _recorder.stop();
      if (stoppedPath != null && stoppedPath.isNotEmpty) {
        _currentFilePath = stoppedPath;
      }
    } catch (e) {
      print('Error stopping audio recording: $e');
    }
  }

  void _startLevelTimer() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (!isRecording.value) return;
      try {
        final amp = await _recorder.getAmplitude();
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        audioLevel.value = normalized;
      } catch (_) {
        // ignore amplitude errors
      }
    });
  }

  void _stopLevelTimer() {
    _levelTimer?.cancel();
    _levelTimer = null;
    audioLevel.value = 0.0;
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
            _restartLiveTranscription();
            return;
          }
          isTranscribing.value = false;
        }
      },
      onError: (error) {
        print('VoiceNotes STT error: $error');
        if (isRecording.value) {
          _restartLiveTranscription();
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
    _recorder.dispose();
    _levelTimer?.cancel();
    super.onClose();
  }
}
