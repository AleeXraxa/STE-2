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
            color: const Color(0xFFEEF2F6),
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
                  color: Color(0xFF0F172A),
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
                              const Icon(Icons.search, color: Color(0xFF0F172A)),
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
                            color: Color(0xFF0F172A),
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
    const Color bgTop = Color(0xFF0F172A);
    const Color bgBottom = Color(0xFF1E293B);
    const Color accent = Color(0xFF22D3EE);
    const Color accentDark = Color(0xFF0E7490);
    const Color panel = Color(0xFFF8FAFC);
    const Color textPrimary = Color(0xFFF8FAFC);
    const Color textMuted = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgTop,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Headphone & Phone',
          style:
              AppTextStyles.heading.copyWith(fontSize: 18, color: textPrimary),
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
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dual Channel Talk',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 22,
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hold phone to speak. Earbud listens for replies.',
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
                            onTap: () => _showLanguagePicker(isPhone: true),
                            child: Obx(() => _langChip(
                                  title: 'Phone',
                                  value: controller.phoneLangName.value,
                                  accent: accent,
                                  textColor: textPrimary,
                                )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showLanguagePicker(isPhone: false),
                            child: Obx(() => _langChip(
                                  title: 'Earbuds',
                                  value: controller.earbudLangName.value,
                                  accent: accent,
                                  textColor: textPrimary,
                                )),
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
                    final msgs = controller.messages;
                    if (msgs.isEmpty) {
                      return Center(
                        child: Text(
                          controller.status.value,
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 20,
                            color: const Color(0xFF0F172A),
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
                        return _bubble(msgs[index], accentDark);
                      },
                    );
                  }),
                ),
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
                              height: 52,
                              decoration: BoxDecoration(
                                color: controller.isListeningPhone.value
                                    ? Colors.red
                                    : accentDark,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  controller.isListeningPhone.value
                                      ? 'Listening...'
                                      : 'Hold to Talk (Phone)',
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
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: controller.isListeningEarbud.value
                                ? Colors.red
                                : accentDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child:
                              const Icon(Icons.headphones, color: Colors.white),
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
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langChip({
    required String title,
    required String value,
    required Color accent,
    required Color textColor,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: accent),
        ],
      ),
    );
  }

  Widget _bubble(HeadphonePhoneMessage msg, Color accentDark) {
    return Align(
      alignment: msg.fromPhone ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.fromPhone ? Colors.grey[200] : accentDark,
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
