class FreeTalkMessage {
  final String id;
  final String original;
  final String translated;
  final String sourceLang;
  final DateTime timestamp;

  FreeTalkMessage({
    required this.id,
    required this.original,
    required this.translated,
    required this.sourceLang,
    required this.timestamp,
  });

  factory FreeTalkMessage.create(
      String original, String translated, String sourceLang) {
    return FreeTalkMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      original: original,
      translated: translated,
      sourceLang: sourceLang,
      timestamp: DateTime.now(),
    );
  }
}
