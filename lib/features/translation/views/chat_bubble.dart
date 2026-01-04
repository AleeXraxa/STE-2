import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/message.dart';
import '../controllers/translation_controller.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final int index;
  final TranslationController controller;

  const ChatBubble(
      {required this.message, required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    bool isEnglish = message.sourceLang == 'en';
    return Align(
      alignment: isEnglish ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnglish ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.original,
              style: AppTextStyles.body
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.translated,
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ),
                Obx(() => IconButton(
                      icon: Icon(
                        controller.playingIndex.value == index
                            ? Icons.stop
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => controller.play(index),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
