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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Align(
              alignment: isEnglish ? Alignment.topLeft : Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  // Add interactive feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message tapped'),
                      duration: Duration(seconds: 1),
                      backgroundColor: AppColors.gradientEnd,
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.chatBubbleBackground,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gradientEnd.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.gradientEnd.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.original,
                        style: AppTextStyles.body.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.translated,
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.gradientEnd,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                          Obx(() => AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                transform: Matrix4.identity()
                                  ..scale(controller.playingIndex.value == index
                                      ? 1.2
                                      : 1.0),
                                child: IconButton(
                                  icon: Icon(
                                    controller.playingIndex.value == index
                                        ? Icons.stop
                                        : Icons.play_arrow,
                                    color:
                                        controller.playingIndex.value == index
                                            ? AppColors.gradientEnd
                                            : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () => controller.play(index),
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
