import 'package:get/get.dart';
import '../controllers/voice_notes_controller.dart';

class VoiceNotesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VoiceNotesController>(() => VoiceNotesController());
  }
}
