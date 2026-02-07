import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotos() async {
    if (Platform.isAndroid) {
      final media = await Permission.photos.request();
      if (media.isGranted) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    final photos = await Permission.photos.request();
    return photos.isGranted;
  }

  static Future<void> requestBluetooth() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }
}
