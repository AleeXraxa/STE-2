import 'package:get/get.dart';
import '../controllers/free_talk_controller.dart';

class FreeTalkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FreeTalkController>(() => FreeTalkController());
  }
}
