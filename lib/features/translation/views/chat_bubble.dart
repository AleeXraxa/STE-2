import 'package:flutter/material.dart';
import '../models/message.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    bool isEnglish = message.language == 'en';
    return Align(
      alignment: isEnglish ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnglish ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${isEnglish ? 'EN' : 'ES'}: ${message.text}',
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
