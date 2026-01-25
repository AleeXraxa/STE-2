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
                      'Select ${isSource ? 'Source' : 'Target'} Language',
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
              icon: Icon(Icons.checklist, color: Color(0xFF003049)),
              onPressed: () => controller.isSelectionMode.toggle(),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Obx(() => Text(
                                      controller
                                          .selectedSourceLanguageName.value,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Obx(() => Text(
                                      controller
                                          .selectedTargetLanguageName.value,
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

            /// ✅ Chat Messages List
            Expanded(
              child: GetBuilder<TranslationController>(
                builder: (controller) {
                  final messages = controller.chatMessages;
                  // Scroll to bottom when messages change
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  return ListView.builder(
                    controller: _scrollController,
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

            /// ✅ Bottom Buttons
            FadeTransition(
              opacity: _bottomFadeAnimation,
              child: Container(
                padding: EdgeInsets.all(20.0),
                child: Obx(() => controller.isSelectionMode.value
                    ? Row(
                        children: [
                          Expanded(
                            child: Obx(() => Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        controller.selectedMessages.isNotEmpty
                                            ? Color(0xFFEDF2F4)
                                            : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                        color: controller
                                                .selectedMessages.isNotEmpty
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.grey[400]!),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: controller
                                            .selectedMessages.isNotEmpty
                                        ? () {
                                            controller.deleteSelectedMessages();
                                            controller.isSelectionMode.value =
                                                false;
                                          }
                                        : null,
                                    icon: Icon(Icons.delete,
                                        color: controller
                                                .selectedMessages.isNotEmpty
                                            ? Colors.white
                                            : Colors.grey[500]),
                                    label: Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          controller.selectedMessages.isNotEmpty
                                              ? Colors.red
                                              : Colors.grey[400],
                                      shadowColor: Colors.transparent,
                                      foregroundColor:
                                          controller.selectedMessages.isNotEmpty
                                              ? Colors.white
                                              : Colors.grey[500],
                                      textStyle: AppTextStyles.button.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                                )),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xFFEDF2F4),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: Colors.black.withOpacity(0.2)),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  controller.isSelectionMode.value = false;
                                  controller.selectedMessages.clear();
                                },
                                icon: Icon(Icons.cancel, color: Colors.white),
                                label: Text('Cancel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF003049),
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  textStyle: AppTextStyles.button.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
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
                                  color: controller.isListeningTarget.value
                                      ? Colors.grey[300]
                                      : Color(0xFFEDF2F4),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                      color: controller.isListeningTarget.value
                                          ? Colors.grey[400]!
                                          : Colors.black.withOpacity(0.2)),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: controller.isListeningTarget.value
                                      ? null
                                      : (controller.isListeningSource.value
                                          ? () =>
                                              controller.stopListeningSource()
                                          : () => controller
                                              .startListeningSource()),
                                  icon: Icon(
                                    controller.isListeningSource.value
                                        ? Icons.stop
                                        : Icons.mic,
                                    color: controller.isListeningTarget.value
                                        ? Colors.grey[500]
                                        : Colors.white,
                                  ),
                                  label: Obx(() => Text(
                                      'Speak ${controller.selectedSourceLanguageName.value}',
                                      style: TextStyle(
                                        color:
                                            controller.isListeningTarget.value
                                                ? Colors.grey[500]
                                                : Colors.white,
                                      ))),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        controller.isListeningTarget.value
                                            ? Colors.grey[400]
                                            : Color(0xFF003049),
                                    shadowColor: Colors.transparent,
                                    foregroundColor:
                                        controller.isListeningTarget.value
                                            ? Colors.grey[500]
                                            : Colors.white,
                                    textStyle: AppTextStyles.button.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
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
                                  color: controller.isListeningSource.value
                                      ? Colors.grey[300]
                                      : Color(0xFFEDF2F4),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                      color: controller.isListeningSource.value
                                          ? Colors.grey[400]!
                                          : Colors.black.withOpacity(0.2)),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: controller.isListeningSource.value
                                      ? null
                                      : (controller.isListeningTarget.value
                                          ? () =>
                                              controller.stopListeningTarget()
                                          : () => controller
                                              .startListeningTarget()),
                                  icon: Icon(
                                    controller.isListeningTarget.value
                                        ? Icons.stop
                                        : Icons.mic,
                                    color: controller.isListeningSource.value
                                        ? Colors.grey[500]
                                        : Colors.white,
                                  ),
                                  label: Obx(() => Text(
                                      'Speak ${controller.selectedTargetLanguageName.value}',
                                      style: TextStyle(
                                        color:
                                            controller.isListeningSource.value
                                                ? Colors.grey[500]
                                                : Colors.white,
                                      ))),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        controller.isListeningSource.value
                                            ? Colors.grey[400]
                                            : Color(0xFF003049),
                                    shadowColor: Colors.transparent,
                                    foregroundColor:
                                        controller.isListeningSource.value
                                            ? Colors.grey[500]
                                            : Colors.white,
                                    textStyle: AppTextStyles.button.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
