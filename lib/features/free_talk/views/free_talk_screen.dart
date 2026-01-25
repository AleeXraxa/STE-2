import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/free_talk_controller.dart';
import 'free_talk_bubble.dart';
import '../../../core/theme/text_styles.dart';

class FreeTalkScreen extends StatefulWidget {
  @override
  _FreeTalkScreenState createState() => _FreeTalkScreenState();
}

class _FreeTalkScreenState extends State<FreeTalkScreen>
    with TickerProviderStateMixin {
  late FreeTalkController controller;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _bottomFadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FreeTalkController());
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF2F4),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF003049)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Free Talk (Dual Ear)',
          style: AppTextStyles.heading
              .copyWith(fontSize: 18, color: Color(0xFF003049)),
        ),
        backgroundColor: Color(0xFFEDF2F4),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Center(
              child: Text(
                'English ↔ Hindi',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 18,
                  color: Color(0xFF003049),
                ),
              ),
            ),
          ),
          // Chat Messages
          Expanded(
            child: Obx(() {
              final messages = controller.messages;
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    controller.currentStatus.value,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 24,
                      color: Color(0xFF003049),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              // Auto-scroll to bottom when messages change
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
              return ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return FreeTalkBubble(message: messages[index]);
                },
              );
            }),
          ),
          FadeTransition(
            opacity: _bottomFadeAnimation,
            child: Container(
              padding: EdgeInsets.all(20.0),
              child: Obx(() => ElevatedButton.icon(
                    onPressed: controller.isListening.value
                        ? controller.stopFreeTalk
                        : controller.startFreeTalk,
                    icon: Icon(
                      controller.isListening.value ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                    label: Text(
                        controller.isListening.value ? 'Stop' : 'Start Speak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isListening.value
                          ? Colors.red
                          : Color(0xFF003049),
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      textStyle: AppTextStyles.button
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      padding: EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
