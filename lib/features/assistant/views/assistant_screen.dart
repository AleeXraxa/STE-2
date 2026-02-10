import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/assistant_controller.dart';
import '../models/chat_message.dart';

class AssistantScreen extends StatefulWidget {
  @override
  _AssistantScreenState createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  bool showKeyboardFirst = false;
  bool hasText = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AssistantController controller;

  late AnimationController _animationController;
  late Animation<double> _circleFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _bottomFadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AssistantController>();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _circleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.3, 0.6, curve: Curves.easeOut),
    ));

    _bottomFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 1.0, curve: Curves.easeOut),
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
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showLanguagePicker() {
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
            color: const Color(0xFF0B2A36),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F2A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Select Language',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Search Bar
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0x22FFFFFF)),
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            controller.updateSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: 'Search languages...',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                        style: TextStyle(color: Colors.white),
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
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: ListTile(
                            title: Text(
                              lang['name']!,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              lang['code']!,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                            ),
                            onTap: () {
                              controller.selectLanguage(
                                  lang['code']!, lang['name']!);
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1F2A),
              Color(0xFF12394A),
              Color(0xFF0B2A36),
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI Assistant',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showLanguagePicker(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0x22FFFFFF)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.language,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Obx(() => Text(
                                      controller.selectedLanguageName.value,
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.book, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: controller.chatMessages.isEmpty &&
                            !controller.isListening.value
                        ? _buildIntro()
                        : _buildMessages(),
                  ),
                  _buildBottomSection(),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 24),
          FadeTransition(
            opacity: _circleFadeAnimation,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF00F5D4), Color(0xFF12394A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 52,
                color: Color(0xFF003049),
              ),
            ),
          ),
          SizedBox(height: 16),
          FadeTransition(
            opacity: _textFadeAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Hi~ I'm your AI assistant",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "If you have any question, you can ask me at any time~",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    _scrollToBottom();
    return ListView.builder(
      controller: _scrollController,
      itemCount: controller.chatMessages.length +
          (controller.isListening.value ? 1 : 0) +
          (controller.isLoading.value ? 1 : 0) +
          (controller.errorMessage.value.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < controller.chatMessages.length) {
          return _buildMessageBubble(controller.chatMessages[index],
              index: index);
        } else if (controller.isListening.value &&
            index == controller.chatMessages.length) {
          return _buildMessageBubble(controller.livePartialText.value,
              isPartial: true);
        } else if (controller.isLoading.value &&
            index ==
                controller.chatMessages.length +
                    (controller.isListening.value ? 1 : 0)) {
          return _buildLoadingBubble();
        } else if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorBubble(controller.errorMessage.value);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageBubble(dynamic message,
      {bool isPartial = false, int index = -1}) {
    String text;
    bool isUser;
    if (message is ChatMessage) {
      text = message.text;
      isUser = message.isUser;
    } else {
      text = message as String;
      isUser = true; // partial is user
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 500),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.all(16),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF1D3A4A) : const Color(0xFF00F5D4),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
              bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
            ),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.manrope(
                    color: isUser ? Colors.white : const Color(0xFF003049),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isUser && !isPartial && index != -1)
                Obx(() => GestureDetector(
                      onTap: () => controller.speakText(text, index),
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          controller.speakingIndex.value == index
                              ? Icons.stop
                              : Icons.play_arrow,
                          color: const Color(0xFF003049),
                          size: 20,
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI is thinking...',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBubble(String message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x33FF6B6B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0x55FF6B6B)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(width: 8),
            TextButton(
              onPressed: controller.retryLast,
              child: Text(
                'Retry',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return FadeTransition(
        opacity: _bottomFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B2A36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: showKeyboardFirst
              ? Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 50,
                        child: TextField(
                          controller: _textController,
                          onChanged: (value) =>
                              setState(() => hasText = value.isNotEmpty),
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Please enter what you want to say~',
                            hintStyle:
                                TextStyle(color: Colors.white70, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0x1AFFFFFF),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.white24, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.white24, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Obx(() {
                        final isBusy = controller.isLoading.value;
                        return GestureDetector(
                            onTap: hasText
                                ? () {
                                    if (!isBusy) {
                                      controller.sendTypedMessage(
                                          _textController.text);
                                    }
                                    _textController.clear();
                                    setState(() => hasText = false);
                                  }
                                : () => setState(() =>
                                    showKeyboardFirst = !showKeyboardFirst),
                            child: Opacity(
                              opacity: isBusy ? 0.6 : 1.0,
                              child: Opacity(
                                opacity: controller.isLoading.value ? 0.6 : 1.0,
                                child: Container(
                                  height: 50,
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00F5D4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    hasText ? Icons.send : Icons.mic,
                                    color: const Color(0xFF003049),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ));
                      }),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Obx(() => GestureDetector(
                            onTap: controller.isLoading.value
                                ? null
                                : (controller.isListening.value
                                    ? controller.stopListening
                                    : controller.startListening),
                            child: Opacity(
                              opacity: controller.isLoading.value ? 0.6 : 1.0,
                              child: Container(
                                height: 50,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: controller.isListening.value
                                      ? const Color(0xFF00F5D4)
                                      : const Color(0x1AFFFFFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white24, width: 1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      controller.isListening.value
                                          ? Icons.stop
                                          : Icons.mic,
                                      color: controller.isListening.value
                                          ? const Color(0xFF003049)
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      controller.isLoading.value
                                          ? 'Thinking...'
                                          : (controller.isListening.value
                                              ? 'Stop & Send'
                                              : 'Click and Speak'),
                                      style: GoogleFonts.manrope(
                                        color: controller.isListening.value
                                            ? const Color(0xFF003049)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () => setState(
                            () => showKeyboardFirst = !showKeyboardFirst),
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Icon(Icons.keyboard,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
        ));
  }
}
