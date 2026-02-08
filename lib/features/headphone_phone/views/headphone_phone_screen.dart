import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/text_styles.dart';
import '../controllers/headphone_phone_controller.dart';
import '../models/headphone_phone_message.dart';

class HeadphonePhoneScreen extends StatefulWidget {
  const HeadphonePhoneScreen({super.key});

  @override
  State<HeadphonePhoneScreen> createState() => _HeadphonePhoneScreenState();
}

class _HeadphonePhoneScreenState extends State<HeadphonePhoneScreen> {
  late HeadphonePhoneController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(HeadphonePhoneController());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _showLanguagePicker({
    required bool isPhone,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F4),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF003049),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Select ${isPhone ? 'Phone' : 'Earbud'} Language',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {},
                        decoration: InputDecoration(
                          hintText: 'Search languages...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon:
                              const Icon(Icons.search, color: Color(0xFF003049)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final langs = controller.supportedLanguages;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: langs.length,
                    itemBuilder: (context, index) {
                      final lang = langs[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
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
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF003049),
                          ),
                          onTap: () {
                            if (isPhone) {
                              controller.selectPhoneLanguage(
                                  lang['code']!, lang['name']!);
                            } else {
                              controller.selectEarbudLanguage(
                                  lang['code']!, lang['name']!);
                            }
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  );
                }),
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
      backgroundColor: const Color(0xFFEDF2F4),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003049)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Headphone & Phone',
          style: AppTextStyles.heading
              .copyWith(fontSize: 18, color: const Color(0xFF003049)),
        ),
        backgroundColor: const Color(0xFFEDF2F4),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLanguagePicker(isPhone: true),
                    child: Obx(() => _langChip(
                          title: 'Phone',
                          value: controller.phoneLangName.value,
                        )),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLanguagePicker(isPhone: false),
                    child: Obx(() => _langChip(
                          title: 'Earbuds',
                          value: controller.earbudLangName.value,
                        )),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final msgs = controller.messages;
              if (msgs.isEmpty) {
                return Center(
                  child: Text(
                    controller.status.value,
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 20,
                      color: const Color(0xFF003049),
                    ),
                  ),
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
              return ListView.builder(
                controller: _scrollController,
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  return _bubble(msgs[index]);
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => controller.startPhoneListening(),
                        onTapUp: (_) => controller.stopPhoneListening(),
                        onTapCancel: () => controller.stopPhoneListening(),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: controller.isListeningPhone.value
                                ? Colors.red
                                : const Color(0xFF003049),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              controller.isListeningPhone.value
                                  ? 'Listening...'
                                  : 'Press to Talk (Phone)',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: controller.isListeningEarbud.value
                            ? Colors.red
                            : const Color(0xFF003049),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.headphones, color: Colors.white),
                    ),
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Tap your earbud media button to speak',
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langChip({required String title, required String value}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2F4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF003049).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF003049),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF003049)),
        ],
      ),
    );
  }

  Widget _bubble(HeadphonePhoneMessage msg) {
    return Align(
      alignment: msg.fromPhone ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.fromPhone ? Colors.grey[300] : const Color(0xFF003049),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.original,
              style: GoogleFonts.poppins(
                color: msg.fromPhone ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    msg.translated,
                    style: GoogleFonts.poppins(
                      color: msg.fromPhone ? Colors.black54 : Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.speakTranslation(msg),
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
