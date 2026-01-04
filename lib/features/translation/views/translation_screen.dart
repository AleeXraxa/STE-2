import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/translation_controller.dart';
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
              child: Obx(() {
                List<Widget> messageWidgets = [];
                for (var msg in controller.englishMessages) {
                  messageWidgets.add(
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'EN: $msg',
                          style:
                              AppTextStyles.body.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
                for (var msg in controller.spanishMessages) {
                  messageWidgets.add(
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ES: $msg',
                          style:
                              AppTextStyles.body.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
                if (controller.currentEnglishText.value.isNotEmpty) {
                  messageWidgets.add(
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'EN: ${controller.currentEnglishText.value}',
                          style:
                              AppTextStyles.body.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
                if (controller.currentSpanishText.value.isNotEmpty) {
                  messageWidgets.add(
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ES: ${controller.currentSpanishText.value}',
                          style:
                              AppTextStyles.body.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
                return ListView(
                  children: messageWidgets,
                );
              }),
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
