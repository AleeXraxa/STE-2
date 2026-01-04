import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../controllers/assistant_controller.dart';
import '../models/chat_message.dart';

class AssistantScreen extends StatefulWidget {
  @override
  _AssistantScreenState createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final String selectedLanguage =
      'English'; // Placeholder, can be dynamic later
  bool showKeyboardFirst = false;
  bool hasText = false;
  final TextEditingController _textController = TextEditingController();
  late AssistantController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AssistantController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.darkBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              selectedLanguage,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(Icons.book, color: Colors.white),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.gradientEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy,
              size: 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.buttonBackground,
              borderRadius: BorderRadius.circular(16),
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
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
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
          return _buildMessageBubble(controller.chatMessages[index]);
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

  Widget _buildMessageBubble(dynamic message, {bool isPartial = false}) {
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
            color: isUser ? Colors.lightBlue[200] : Colors.grey[700],
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
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
          color: Colors.grey[700],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AI is thinking...',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
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
                        hintStyle: TextStyle(color: Colors.white, fontSize: 12),
                        filled: true,
                        fillColor: Colors.black,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white, width: 2),
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
                            controller.sendTypedMessage(_textController.text);
                            _textController.clear();
                            setState(() => hasText = false);
                          }
                        : () => setState(
                            () => showKeyboardFirst = !showKeyboardFirst),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBackground,
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
                  child: GestureDetector(
                    onTap: controller.startListening,
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Obx(() => Text(
                                controller.isListening.value
                                    ? 'Listening…'
                                    : 'Click and Speak',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => showKeyboardFirst = !showKeyboardFirst),
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child:
                          Icon(Icons.keyboard, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
