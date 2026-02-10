class VoiceNote {
  final String id;
  final String title;
  final String filePath;
  final String transcript;
  final DateTime createdAt;
  final int duration; // in seconds
  final bool isPlaying;

  VoiceNote({
    required this.id,
    required this.title,
    required this.filePath,
    required this.transcript,
    required this.createdAt,
    this.duration = 0,
    this.isPlaying = false,
  });

  VoiceNote copyWith({
    String? id,
    String? title,
    String? filePath,
    String? transcript,
    DateTime? createdAt,
    int? duration,
    bool? isPlaying,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      transcript: transcript ?? this.transcript,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'transcript': transcript,
      'createdAt': createdAt.toIso8601String(),
      'duration': duration,
      'isPlaying': isPlaying,
    };
  }

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id'],
      title: json['title'],
      filePath: json['filePath'],
      transcript: json['transcript'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      duration: json['duration'],
      isPlaying: json['isPlaying'],
    );
  }
}
