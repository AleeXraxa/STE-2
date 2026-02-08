import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/translation_controller.dart';
import 'chat_bubble.dart';
import '../../../core/theme/text_styles.dart';

class TranslationScreen extends StatefulWidget {
  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen>
    with TickerProviderStateMixin {
  late TranslationController controller;
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
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

  void _showLanguagePicker(bool isSource) {
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
                      'Select ${isSource ? 'Source' : 'Target'} Language',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
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
                        onChanged: (value) => controller.updateSearchQuery(value),
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
                              if (isSource) {
                                controller.selectSourceLanguage(
                                    lang['code']!, lang['name']!);
                              } else {
                                controller.selectTargetLanguage(
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
    const Color accent = Color(0xFF38BDF8);
    const Color accentDark = Color(0xFF0369A1);
    const Color panel = Color(0xFFF8FAFC);
    const Color textPrimary = Color(0xFFF8FAFC);
    const Color textMuted = Color(0xFF94A3B8);

    return GetBuilder<TranslationController>(
      builder: (controller) => Scaffold(
        backgroundColor: bgTop,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Translation Machine',
            style: AppTextStyles.heading
                .copyWith(fontSize: 18, color: textPrimary),
          ),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(Icons.checklist, color: textPrimary),
              onPressed: () => controller.isSelectionMode.toggle(),
            )
          ],
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instant Translation',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 22,
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Set your source and target languages.',
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
                                            controller
                                                .selectedSourceLanguageName
                                                .value,
                                            style:
                                                AppTextStyles.button.copyWith(
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
                                            controller
                                                .selectedTargetLanguageName
                                                .value,
                                            style:
                                                AppTextStyles.button.copyWith(
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
                    child: GetBuilder<TranslationController>(
                      builder: (controller) {
                        final messages = controller.chatMessages;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          physics: const BouncingScrollPhysics(),
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
                ),
                FadeTransition(
                  opacity: _bottomFadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Obx(
                      () => controller.isSelectionMode.value
                          ? Row(
                              children: [
                                Expanded(
                                  child: Obx(() => Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: controller
                                                  .selectedMessages.isNotEmpty
                                              ? panel
                                              : Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                              color: controller
                                                      .selectedMessages
                                                      .isNotEmpty
                                                  ? Colors.black
                                                      .withOpacity(0.2)
                                                  : Colors.grey[400]!),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: controller.selectedMessages
                                                  .isNotEmpty
                                              ? () {
                                                  controller
                                                      .deleteSelectedMessages();
                                                  controller.isSelectionMode
                                                      .value = false;
                                                }
                                              : null,
                                          icon: Icon(Icons.delete,
                                              color: controller.selectedMessages
                                                      .isNotEmpty
                                                  ? Colors.white
                                                  : Colors.grey[500]),
                                          label: const Text('Delete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: controller
                                                    .selectedMessages
                                                    .isNotEmpty
                                                ? Colors.red
                                                : Colors.grey[400],
                                            shadowColor: Colors.transparent,
                                            foregroundColor: controller
                                                    .selectedMessages
                                                    .isNotEmpty
                                                ? Colors.white
                                                : Colors.grey[500],
                                            textStyle:
                                                AppTextStyles.button.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                        ),
                                      )),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: panel,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                          color: Colors.black
                                              .withOpacity(0.2)),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        controller.isSelectionMode.value =
                                            false;
                                        controller.selectedMessages.clear();
                                      },
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.white),
                                      label: const Text('Cancel'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentDark,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        textStyle:
                                            AppTextStyles.button.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Obx(
                                    () => Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color:
                                            controller.isListeningTarget.value
                                                ? Colors.grey[300]
                                                : panel,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        border: Border.all(
                                            color: controller
                                                    .isListeningTarget.value
                                                ? Colors.grey[400]!
                                                : Colors.black
                                                    .withOpacity(0.2)),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: controller
                                                .isListeningTarget.value
                                            ? null
                                            : (controller
                                                    .isListeningSource.value
                                                ? () => controller
                                                    .stopListeningSource()
                                                : () => controller
                                                    .startListeningSource()),
                                        icon: Icon(
                                          controller.isListeningSource.value
                                              ? Icons.stop
                                              : Icons.mic,
                                          color: controller
                                                  .isListeningTarget.value
                                              ? Colors.grey[500]
                                              : Colors.white,
                                        ),
                                        label: Obx(() => Text(
                                            'Speak ${controller.selectedSourceLanguageName.value}',
                                            style: TextStyle(
                                              color: controller
                                                      .isListeningTarget.value
                                                  ? Colors.grey[500]
                                                  : Colors.white,
                                            ))),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: controller
                                                  .isListeningTarget.value
                                              ? Colors.grey[400]
                                              : accentDark,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: controller
                                                  .isListeningTarget.value
                                              ? Colors.grey[500]
                                              : Colors.white,
                                          textStyle:
                                              AppTextStyles.button.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Obx(
                                    () => Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color:
                                            controller.isListeningSource.value
                                                ? Colors.grey[300]
                                                : panel,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        border: Border.all(
                                            color: controller
                                                    .isListeningSource.value
                                                ? Colors.grey[400]!
                                                : Colors.black
                                                    .withOpacity(0.2)),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: controller
                                                .isListeningSource.value
                                            ? null
                                            : (controller
                                                    .isListeningTarget.value
                                                ? () => controller
                                                    .stopListeningTarget()
                                                : () => controller
                                                    .startListeningTarget()),
                                        icon: Icon(
                                          controller.isListeningTarget.value
                                              ? Icons.stop
                                              : Icons.mic,
                                          color: controller
                                                  .isListeningSource.value
                                              ? Colors.grey[500]
                                              : Colors.white,
                                        ),
                                        label: Obx(() => Text(
                                            'Speak ${controller.selectedTargetLanguageName.value}',
                                            style: TextStyle(
                                              color: controller
                                                      .isListeningSource.value
                                                  ? Colors.grey[500]
                                                  : Colors.white,
                                            ))),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: controller
                                                  .isListeningSource.value
                                              ? Colors.grey[400]
                                              : accentDark,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: controller
                                                  .isListeningSource.value
                                              ? Colors.grey[500]
                                              : Colors.white,
                                          textStyle:
                                              AppTextStyles.button.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
