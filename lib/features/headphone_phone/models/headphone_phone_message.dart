class HeadphonePhoneMessage {
  final String id;
  final String original;
  final String translated;
  final String sourceLang;
  final bool fromPhone;

  HeadphonePhoneMessage({
    required this.id,
    required this.original,
    required this.translated,
    required this.sourceLang,
    required this.fromPhone,
  });

  factory HeadphonePhoneMessage.create({
    required String original,
    required String translated,
    required String sourceLang,
    required bool fromPhone,
  }) {
    return HeadphonePhoneMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      original: original,
      translated: translated,
      sourceLang: sourceLang,
      fromPhone: fromPhone,
    );
  }
}
