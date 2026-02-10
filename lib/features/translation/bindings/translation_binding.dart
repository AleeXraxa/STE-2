import 'package:get/get.dart';
import '../controllers/translation_controller.dart';

class TranslationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TranslationController>(() => TranslationController());
  }
}
