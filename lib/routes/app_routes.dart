import 'package:get/get.dart';
import '../features/home/views/home_screen.dart';
import '../features/translation/views/translation_screen.dart';
import '../features/assistant/views/assistant_screen.dart';
import '../features/free_talk/views/free_talk_screen.dart';
import '../splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String translation = '/translation';
  static const String assistant = '/assistant';
  static const String freeTalk = '/free_talk';

  static final List<GetPage> getPages = [
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: home, page: () => HomeScreen()),
    GetPage(name: translation, page: () => TranslationScreen()),
    GetPage(name: assistant, page: () => AssistantScreen()),
    GetPage(name: freeTalk, page: () => FreeTalkScreen()),
  ];
}
