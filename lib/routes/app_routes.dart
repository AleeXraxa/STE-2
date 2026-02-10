import 'package:get/get.dart';
import '../features/home/views/home_screen.dart';
import '../features/translation/views/translation_screen.dart';
import '../features/translation/bindings/translation_binding.dart';
import '../features/assistant/views/assistant_screen.dart';
import '../features/assistant/bindings/assistant_binding.dart';
import '../features/free_talk/views/free_talk_screen.dart';
import '../features/free_talk/bindings/free_talk_binding.dart';
import '../features/voice_notes/views/voice_notes_screen.dart';
import '../features/photo_translation/views/photo_translation_screen.dart';
import '../features/headphone_phone/views/headphone_phone_screen.dart';
import '../splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String translation = '/translation';
  static const String assistant = '/assistant';
  static const String freeTalk = '/free_talk';
  static const String voiceNotes = '/voice_notes';
  static const String photoTranslation = '/photo_translation';
  static const String headphonePhone = '/headphone_phone';

  static final List<GetPage> getPages = [
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: home, page: () => HomeScreen()),
    GetPage(
        name: translation,
        page: () => TranslationScreen(),
        binding: TranslationBinding()),
    GetPage(
        name: assistant,
        page: () => AssistantScreen(),
        binding: AssistantBinding()),
    GetPage(
        name: freeTalk, page: () => FreeTalkScreen(), binding: FreeTalkBinding()),
    GetPage(name: voiceNotes, page: () => VoiceNotesScreen()),
    GetPage(name: photoTranslation, page: () => PhotoTranslationScreen()),
    GetPage(name: headphonePhone, page: () => HeadphonePhoneScreen()),
  ];
}
