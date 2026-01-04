import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show
        FlutterBluePlus,
        BluetoothDevice,
        ScanResult,
        BluetoothAdapterState,
        BluetoothConnectionState;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class BluetoothService extends GetxController {
  var isScanning = false.obs;
  var devices = <BluetoothDevice>[].obs;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  var connectedDeviceName = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen for Bluetooth adapter state changes
    FlutterBluePlus.adapterState.listen((state) {
      print('DEBUG: Bluetooth adapter state changed to: $state');
      if (state == BluetoothAdapterState.off) {
        // Bluetooth turned off, clear connected device
        connectedDevice.value = null;
        connectedDeviceName.value = '';
        print('DEBUG: Cleared connected device due to Bluetooth off');
      }
      // Don't automatically show devices when Bluetooth turns on
    });
  }

  Future<void> checkConnectedDevices() async {
    try {
      // For classic Bluetooth devices, flutter_blue_plus can't detect system connections
      // So we check if Bluetooth is on and show bonded devices as "connected"
      var adapterState = await FlutterBluePlus.adapterState.first;
      print('DEBUG: Bluetooth adapter state: $adapterState');

      if (adapterState == BluetoothAdapterState.on) {
        var bonded = await FlutterBluePlus.bondedDevices;
        print('DEBUG: Found ${bonded.length} bonded devices');

        if (bonded.isNotEmpty) {
          // Find the device with "MB-H2" or similar in name, or take the first
          var targetDevice = bonded.firstWhere(
            (d) =>
                d.platformName.contains('MB-H2') ||
                d.platformName.contains('Morui'),
            orElse: () => bonded.first,
          );

          connectedDevice.value = targetDevice;
          connectedDeviceName.value = targetDevice.platformName.isNotEmpty
              ? targetDevice.platformName
              : targetDevice.localName?.isNotEmpty == true
                  ? targetDevice.localName!
                  : 'Connected Device';
          print(
              'DEBUG: Showing bonded device as connected: ${connectedDeviceName.value}');
        } else {
          connectedDevice.value = null;
          connectedDeviceName.value = '';
          print('DEBUG: No bonded devices found');
        }
      } else {
        connectedDevice.value = null;
        connectedDeviceName.value = '';
        print('DEBUG: Bluetooth is off');
      }
    } catch (e) {
      print('DEBUG: Error checking devices: $e');
    }
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> startScan() async {
    await requestPermissions();

    // Check if Bluetooth is on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    isScanning.value = true;
    devices.clear();

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devices.any((d) => d.remoteId == r.device.remoteId)) {
          devices.add(r.device);
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    isScanning.value = false;
  }

  Future<void> openBluetoothSettings() async {
    print('DEBUG: Opening Bluetooth settings');
    await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
    // After opening settings, check for actually connected devices after a delay
    Future.delayed(Duration(seconds: 2), () async {
      print('DEBUG: Checking for connected devices after settings');
      await checkConnectedDevices();
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // For demo, simulate connection
      connectedDevice.value = device;
      connectedDeviceName.value = device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown Device';
      Get.snackbar('Connected', 'Connected to ${connectedDeviceName.value}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice.value != null) {
      await connectedDevice.value!.disconnect();
      connectedDevice.value = null;
      connectedDeviceName.value = '';
      Get.snackbar('Disconnected', 'Device disconnected');
    }
  }
}
