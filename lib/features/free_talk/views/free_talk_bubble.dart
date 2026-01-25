import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/free_talk_message.dart';
import '../controllers/free_talk_controller.dart';
import '../../../core/theme/text_styles.dart';

class FreeTalkBubble extends StatelessWidget {
  final FreeTalkMessage message;

  const FreeTalkBubble({required this.message, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the controller to access selected languages
    final controller = Get.find<FreeTalkController>();
    bool isLanguageA = message.sourceLang == controller.languageA.value;

    return Align(
      alignment: isLanguageA ? Alignment.topLeft : Alignment.topRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: isLanguageA ? Color(0xFF003049) : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original text (what user spoke)
            Text(
              message.original,
              style: AppTextStyles.body.copyWith(
                  color: isLanguageA ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            // Translated text
            Text(
              message.translated,
              style: AppTextStyles.body.copyWith(
                  color: isLanguageA ? Colors.white : Colors.black,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
