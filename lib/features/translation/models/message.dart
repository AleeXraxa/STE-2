class Message {
  final String text;
  final String language;
  final bool isUser;
  final bool isPartial;

  Message(
      {required this.text,
      required this.language,
      required this.isUser,
      this.isPartial = false});
}
