import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/free_talk_controller.dart';
import 'free_talk_bubble.dart';
import '../../../core/theme/text_styles.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
    controller = Get.find<FreeTalkController>();
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
    const Color bgTop = Color(0xFF0F172A);
    const Color bgBottom = Color(0xFF1E293B);
    const Color accent = Color(0xFF2DD4BF);
    const Color accentDark = Color(0xFF0F766E);
    const Color panel = Color(0xFFF8FAFC);
    const Color textPrimary = Color(0xFFF8FAFC);
    const Color textMuted = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgTop,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Free Talk',
          style: AppTextStyles.heading
              .copyWith(fontSize: 18, color: textPrimary),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dual Conversation',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 22,
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick two languages and keep the flow going.',
                      style: AppTextStyles.body.copyWith(
                        color: textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showLanguagePicker(true),
                            child: Container(
                              height: 54,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.language,
                                      color: textPrimary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Obx(() => Text(
                                          controller.languageAName.value,
                                          style: AppTextStyles.button.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                  ),
                                  const Icon(Icons.expand_more,
                                      color: textPrimary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => controller.swapLanguages(),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [accent, accentDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.swap_horiz,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showLanguagePicker(false),
                            child: Container(
                              height: 54,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.language,
                                      color: textPrimary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Obx(() => Text(
                                          controller.languageBName.value,
                                          style: AppTextStyles.button.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                  ),
                                  const Icon(Icons.expand_more,
                                      color: textPrimary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Obx(() {
                    final messages = controller.messages;
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (controller.isListening.value)
                              SpinKitWave(
                                color: accentDark,
                                size: 36.0,
                              ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                controller.currentStatus.value,
                                key: ValueKey(
                                    controller.currentStatus.value),
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 20,
                                  color: const Color(0xFF0F172A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap the button to start',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return FreeTalkBubble(message: messages[index]);
                      },
                    );
                  }),
                ),
              ),
              FadeTransition(
                opacity: _bottomFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isProcessing.value
                            ? null
                            : (controller.isListening.value
                                ? controller.stopFreeTalk
                                : controller.startFreeTalk),
                        icon: Icon(
                          controller.isListening.value
                              ? Icons.stop
                              : Icons.mic,
                          color: Colors.white,
                        ),
                        label: Text(
                          controller.isProcessing.value
                              ? 'Working...'
                              : (controller.isListening.value
                                  ? 'Stop'
                                  : 'Start Speaking'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.isListening.value
                              ? Colors.red
                              : accentDark,
                          foregroundColor: Colors.white,
                          textStyle: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32.0, vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                          shadowColor: accent.withOpacity(0.4),
                        ),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
