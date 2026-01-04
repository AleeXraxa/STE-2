import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/translation_controller.dart';
import '../models/message.dart';
import 'chat_bubble.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class TranslationScreen extends StatefulWidget {
  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  late TranslationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TranslationController());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TranslationController>(
      builder: (controller) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          title: Text('Translation Machine'),
          backgroundColor: AppColors.primary,
          actions: [IconButton(icon: Icon(Icons.edit), onPressed: () {})],
        ),
        body: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        textStyle: AppTextStyles.button,
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text('English'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.swap_horiz, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        textStyle: AppTextStyles.button,
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text('Spanish'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    itemCount: controller.chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = controller.chatMessages[index];
                      return ChatBubble(
                          message: message,
                          index: index,
                          controller: controller);
                    },
                  )),
            ),
            Container(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() => ElevatedButton.icon(
                          onPressed: controller.isListeningEnglish.value
                              ? () => controller.stopListeningEnglish()
                              : () => controller.startListeningEnglish(),
                          icon: Icon(controller.isListeningEnglish.value
                              ? Icons.stop
                              : Icons.mic),
                          label: Text('English'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            textStyle: AppTextStyles.button,
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        )),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Obx(() => ElevatedButton.icon(
                          onPressed: controller.isListeningSpanish.value
                              ? () => controller.stopListeningSpanish()
                              : () => controller.startListeningSpanish(),
                          icon: Icon(controller.isListeningSpanish.value
                              ? Icons.stop
                              : Icons.mic),
                          label: Text('Spanish'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            textStyle: AppTextStyles.button,
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
