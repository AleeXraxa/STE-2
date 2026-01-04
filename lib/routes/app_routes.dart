import 'package:get/get.dart';
import '../features/home/views/home_screen.dart';
import '../features/translation/views/translation_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String translation = '/translation';

  static final List<GetPage> getPages = [
    GetPage(name: home, page: () => HomeScreen()),
    GetPage(name: translation, page: () => TranslationScreen()),
  ];
}
