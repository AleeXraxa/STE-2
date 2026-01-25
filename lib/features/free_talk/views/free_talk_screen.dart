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

  void _showLanguagePicker(bool isLanguageA) {
    // Reset search when opening picker
    controller.updateSearchQuery('');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Color(0xFFEDF2F4),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header with Search
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Color(0xFF003049),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Select ${isLanguageA ? 'Language A' : 'Language B'}',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Search Bar
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            controller.updateSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: 'Search languages...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xFF003049)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              // Language List
              Expanded(
                child: Obx(() => ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      itemCount: controller.filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final lang = controller.filteredLanguages[index];
                        return Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              lang['name']!,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              lang['code']!,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Color(0xFF003049),
                            ),
                            onTap: () {
                              if (isLanguageA) {
                                controller.selectLanguageA(
                                    lang['code']!, lang['name']!);
                              } else {
                                controller.selectLanguageB(
                                    lang['code']!, lang['name']!);
                              }
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    )),
              ),
            ],
          ),
        );
      },
    );
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLanguagePicker(true),
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
                              child: Obx(() => Text(
                                    controller.languageAName.value,
                                    style: AppTextStyles.button.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  )),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xFF003049)),
                            onPressed: () => _showLanguagePicker(true),
                          ),
                        ],
                      ),
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
                    onPressed: () => controller.swapLanguages(),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLanguagePicker(false),
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
                              child: Obx(() => Text(
                                    controller.languageBName.value,
                                    style: AppTextStyles.button.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  )),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xFF003049)),
                            onPressed: () => _showLanguagePicker(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
