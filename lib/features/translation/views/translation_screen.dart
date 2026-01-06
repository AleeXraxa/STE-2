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

class _TranslationScreenState extends State<TranslationScreen>
    with TickerProviderStateMixin {
  late TranslationController controller;

  late AnimationController _animationController;
  late Animation<double> _bottomFadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TranslationController());
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bottomFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 0.6, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TranslationController>(
      builder: (controller) => Scaffold(
        backgroundColor: Color(0xFFEDF2F4),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF003049)),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Translation Machine',
            style: AppTextStyles.heading
                .copyWith(fontSize: 18, color: Color(0xFF003049)),
          ),
          backgroundColor: Color(0xFFEDF2F4),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF003049)),
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
                        color: Color(0xFFEDF2F4),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: Color(0xFF003049).withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
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
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xFF003049)),
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
                      color: Color(0xFF003049),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
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
                        color: Color(0xFFEDF2F4),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: Color(0xFF003049).withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
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
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xFF003049)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// ✅ Chat Messages List
            Expanded(
              child: GetBuilder<TranslationController>(
                builder: (controller) {
                  final messages = controller.chatMessages;
                  return ListView.builder(
                    itemCount: messages.length,
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        key: ValueKey(index),
                        message: messages[index],
                        index: index,
                        controller: controller,
                      );
                    },
                  );
                },
              ),
            ),

            /// ✅ Bottom Voice Buttons
            FadeTransition(
              opacity: _bottomFadeAnimation,
              child: Container(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFFEDF2F4),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.2)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: controller.isListeningEnglish.value
                                ? () => controller.stopListeningEnglish()
                                : () => controller.startListeningEnglish(),
                            icon: Icon(
                              controller.isListeningEnglish.value
                                  ? Icons.stop
                                  : Icons.mic,
                              color: Colors.white,
                            ),
                            label: Text('Speak English'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF003049),
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
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Obx(
                        () => Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFFEDF2F4),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.2)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: controller.isListeningSpanish.value
                                ? () => controller.stopListeningSpanish()
                                : () => controller.startListeningSpanish(),
                            icon: Icon(
                              controller.isListeningSpanish.value
                                  ? Icons.stop
                                  : Icons.mic,
                              color: Colors.white,
                            ),
                            label: Text('Speak Spanish'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF003049),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
