import 'package:get/get.dart';
import '../controllers/assistant_controller.dart';

class AssistantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AssistantController>(() => AssistantController());
  }
}
