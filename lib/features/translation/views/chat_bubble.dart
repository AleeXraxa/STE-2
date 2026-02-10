import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/message.dart';
import '../controllers/translation_controller.dart';
import '../../../core/theme/text_styles.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final int index;
  final TranslationController controller;

  const ChatBubble(
      {required this.message,
      required this.index,
      required this.controller,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSourceLanguage =
        message.sourceLang == controller.selectedSourceLanguage.value;
    return Obx(() => Align(
          alignment: isSourceLanguage ? Alignment.topLeft : Alignment.topRight,
          child: GestureDetector(
            onTap: controller.isSelectionMode.value
                ? () {
                    if (controller.selectedMessages.contains(message)) {
                      controller.selectedMessages.remove(message);
                    } else {
                      controller.selectedMessages.add(message);
                    }
                  }
                : null,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6),
              decoration: BoxDecoration(
                color: isSourceLanguage ? Color(0xFF003049) : Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.isSelectionMode.value)
                    Checkbox(
                      value: controller.selectedMessages.contains(message),
                      onChanged: (value) {
                        if (value == true) {
                          controller.selectedMessages.add(message);
                        } else {
                          controller.selectedMessages.remove(message);
                        }
                      },
                      activeColor:
                          isSourceLanguage ? Colors.white : Color(0xFF003049),
                      checkColor:
                          isSourceLanguage ? Color(0xFF003049) : Colors.white,
                    ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.original,
                          style: AppTextStyles.body.copyWith(
                              color: isSourceLanguage
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                message.translated,
                                style: AppTextStyles.body.copyWith(
                                    color: isSourceLanguage
                                        ? Colors.white
                                        : Colors.black,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                            Obx(() => AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  transform: Matrix4.identity()
                                    ..scale(
                                        controller.playingIndex.value == index
                                            ? 1.2
                                            : 1.0),
                                  child: IconButton(
                                    icon: Icon(
                                      controller.playingIndex.value == index
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      color: isSourceLanguage
                                          ? Colors.white
                                          : Colors.black,
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
                ],
              ),
            ),
          ),
        ));
  }
}
