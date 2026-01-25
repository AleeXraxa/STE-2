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
  late AssistantController controller;

  late AnimationController _animationController;
  late Animation<double> _circleFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _bottomFadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AssistantController());
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
    super.dispose();
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
            color: Color(0xFFEDF2F4),
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
                  color: Color(0xFF003049),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Select Language',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              lang['code']!,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Color(0xFF003049),
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
    return Scaffold(
      backgroundColor: Color(0xFFEDF2F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFEDF2F4),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF003049)),
          onPressed: () => Get.back(),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showLanguagePicker(),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF003049),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Obx(() => Text(
                        controller.selectedLanguageName.value,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.book, color: Color(0xFF003049)),
        ],
      ),
      body: Obx(() => Column(
            children: [
              Expanded(
                child: controller.chatMessages.isEmpty &&
                        !controller.isListening.value
                    ? _buildIntro()
                    : _buildMessages(),
              ),
              _buildBottomSection(),
            ],
          )),
    );
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 30),
          FadeTransition(
            opacity: _circleFadeAnimation,
            child: Container(
              width: 100,
              height: 100,
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
              child: Icon(
                Icons.smart_toy,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 20),
          FadeTransition(
            opacity: _textFadeAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF003049),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Hi~ I'm your AI assistant",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "If you have any question, you can ask me at any time~",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
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
    return ListView.builder(
      itemCount: controller.chatMessages.length +
          (controller.isListening.value ? 1 : 0) +
          (controller.isLoading.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < controller.chatMessages.length) {
          return _buildMessageBubble(controller.chatMessages[index],
              index: index);
        } else if (controller.isListening.value &&
            index == controller.chatMessages.length) {
          return _buildMessageBubble(controller.livePartialText.value,
              isPartial: true);
        } else if (controller.isLoading.value) {
          return _buildLoadingBubble();
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
            color: isUser ? Colors.grey[300] : Color(0xFF003049),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
              bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.montserrat(
                    color: isUser ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
                          color: Colors.white,
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
          color: Color(0xFF003049),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI is thinking...',
              style: GoogleFonts.montserrat(
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

  Widget _buildBottomSection() {
    return FadeTransition(
        opacity: _bottomFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF003049),
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
                              color: Colors.black, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Please enter what you want to say~',
                            hintStyle:
                                TextStyle(color: Colors.black, fontSize: 12),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.black, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.black, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: hasText
                            ? () {
                                controller
                                    .sendTypedMessage(_textController.text);
                                _textController.clear();
                                setState(() => hasText = false);
                              }
                            : () => setState(
                                () => showKeyboardFirst = !showKeyboardFirst),
                        child: Container(
                          height: 50,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Color(0xFF003049),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            hasText ? Icons.send : Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Obx(() => GestureDetector(
                            onTap: controller.isListening.value
                                ? controller.stopListening
                                : controller.startListening,
                            child: Container(
                              height: 50,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Color(0xFF003049),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    controller.isListening.value
                                        ? Icons.stop
                                        : Icons.mic,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    controller.isListening.value
                                        ? 'Stop & Send'
                                        : 'Click and Speak',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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
                            color: Color(0xFF003049),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
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
