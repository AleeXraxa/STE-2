import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class BluetoothService extends GetxController {
  var isScanning = false.obs;
  var isConnecting = false.obs;
  var devices = <BluetoothDevice>[].obs;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  var connectedDeviceName = ''.obs;
  var isClassicConnected = false.obs;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _adapterSubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _connectedPollTimer;
  static const MethodChannel _classicChannel =
      MethodChannel('classic_bluetooth');

  @override
  void onInit() {
    super.onInit();

    // Listen for Bluetooth adapter state changes
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      print('DEBUG: Bluetooth adapter state changed to: $state');
      if (state == BluetoothAdapterState.off) {
        // Bluetooth turned off, clear connected device
        connectedDevice.value = null;
        connectedDeviceName.value = '';
        print('DEBUG: Cleared connected device due to Bluetooth off');
      } else if (state == BluetoothAdapterState.on) {
        // Bluetooth turned on, check for connected devices
        checkConnectedDevices();
      }
    });

    // React to actual BLE connection state changes
    _connectionSubscription =
        FlutterBluePlus.events.onConnectionStateChanged.listen((event) {
      print('DEBUG: Connection state changed to: ${event.connectionState}');
      if (event.connectionState == BluetoothConnectionState.connected) {
        connectedDevice.value = event.device;
        connectedDeviceName.value = event.device.platformName.isNotEmpty
            ? event.device.platformName
            : event.device.remoteId.toString();
        isClassicConnected.value = false;
      } else if (event.connectionState ==
          BluetoothConnectionState.disconnected) {
        if (connectedDevice.value?.remoteId == event.device.remoteId) {
          connectedDevice.value = null;
          connectedDeviceName.value = '';
          isClassicConnected.value = false;
          Get.snackbar('Disconnected', 'Device disconnected');
        }
      }
    });

    // Do not infer connections on startup.
    // We only set connectedDeviceName when a real connection event is observed.
    _startConnectedDevicePolling();
  }

  Future<void> checkConnectedDevices() async {
    try {
      var adapterState = await FlutterBluePlus.adapterState.first;
      print('DEBUG: Bluetooth adapter state: $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        connectedDevice.value = null;
        connectedDeviceName.value = '';
        isClassicConnected.value = false;
        print('DEBUG: Bluetooth is off');
        return;
      }

      // If app already has an active BLE connection, keep it
      final current = connectedDevice.value;
      if (current != null) {
        if (current.isConnected) {
          connectedDeviceName.value = current.platformName.isNotEmpty
              ? current.platformName
              : current.remoteId.toString();
          isClassicConnected.value = false;
          return;
        } else {
          connectedDevice.value = null;
          connectedDeviceName.value = '';
          isClassicConnected.value = false;
        }
      }

      // Check for system-connected devices (e.g., connected via settings)
      final systemDevices = await FlutterBluePlus.systemDevices([Guid("1800")]);
      if (systemDevices.isNotEmpty) {
        final device = systemDevices.first;
        connectedDevice.value = device;
        connectedDeviceName.value = device.platformName.isNotEmpty
            ? device.platformName
            : device.remoteId.toString();
        isClassicConnected.value = false;
        print(
            'DEBUG: Found system connected device: ${connectedDeviceName.value}');
      } else {
        final classicName = await _getClassicConnectedDeviceName();
        if (classicName != null && classicName.isNotEmpty) {
          connectedDevice.value = null;
          connectedDeviceName.value = classicName;
          isClassicConnected.value = true;
          print('DEBUG: Found classic connected device: $classicName');
        } else {
          connectedDevice.value = null;
          connectedDeviceName.value = '';
          isClassicConnected.value = false;
          print('DEBUG: No connected devices found');
        }
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

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devices.any((d) => d.remoteId == r.device.remoteId)) {
          devices.add(r.device);
        }
      }
    });
    FlutterBluePlus.cancelWhenScanComplete(_scanSubscription!);

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
      isConnecting.value = true;
      await device.connect();
      connectedDevice.value = device;
      connectedDeviceName.value = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.toString();
      Get.snackbar('Connected', 'Connected to ${connectedDeviceName.value}');
      isConnecting.value = false;
    } catch (e) {
      isConnecting.value = false;
      Get.snackbar('Error', 'Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice.value != null) {
      await connectedDevice.value!.disconnect();
      connectedDevice.value = null;
      connectedDeviceName.value = '';
      isClassicConnected.value = false;
      Get.snackbar('Disconnected', 'Device disconnected');
      return;
    }
    if (isClassicConnected.value) {
      await openBluetoothSettings();
    }
  }

  Future<String?> _getClassicConnectedDeviceName() async {
    try {
      final name = await _classicChannel
          .invokeMethod<String>('getConnectedAudioDeviceName');
      return name;
    } catch (e) {
      print('DEBUG: Classic BT lookup failed: $e');
      return null;
    }
  }

  void _startConnectedDevicePolling() {
    _connectedPollTimer?.cancel();
    _connectedPollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkConnectedDevices());
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _adapterSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectedPollTimer?.cancel();
    super.onClose();
  }
}
