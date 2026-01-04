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
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text('Translation Machine',
              style: AppTextStyles.heading.copyWith(fontSize: 18)),
          backgroundColor: AppColors.darkBackground,
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {},
            )
          ],
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
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(25),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'English',
                                style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: AppColors.gradientEnd),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.gradientEnd],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.swap_horiz, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(25),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Spanish',
                                style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: AppColors.gradientEnd),
                            onPressed: () {},
                          ),
                        ],
                      ),
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
                    child: Obx(() => Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: controller.isListeningEnglish.value
                                ? () => controller.stopListeningEnglish()
                                : () => controller.startListeningEnglish(),
                            icon: Icon(
                              controller.isListeningEnglish.value
                                  ? Icons.stop
                                  : Icons.mic,
                              color: AppColors.gradientEnd,
                            ),
                            label: Text('Speak English'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              textStyle: AppTextStyles.button.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        )),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Obx(() => Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: controller.isListeningSpanish.value
                                ? () => controller.stopListeningSpanish()
                                : () => controller.startListeningSpanish(),
                            icon: Icon(
                              controller.isListeningSpanish.value
                                  ? Icons.stop
                                  : Icons.mic,
                              color: AppColors.gradientEnd,
                            ),
                            label: Text('Speak Spanish'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              textStyle: AppTextStyles.button.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
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
