import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/services/bluetooth_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;

  // Connect area animations
  late Animation<double> _connectFadeAnimation;
  late Animation<Offset> _connectSlideAnimation;

  // AI Assistant animations
  late Animation<double> _assistantFadeAnimation;
  late Animation<Offset> _assistantSlideAnimation;

  // Translate section animations
  late Animation<double> _translateFadeAnimation;
  late Animation<Offset> _translateSlideAnimation;

  // Buttons animations
  late Animation<double> _buttonsFadeAnimation;
  late Animation<Offset> _buttonsSlideAnimation;

  @override
  void initState() {
    super.initState();
    Get.put(BluetoothService());
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    // Check for connected devices when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bluetoothService = Get.find<BluetoothService>();
      bluetoothService.startConnectedDevicePolling();
      bluetoothService.checkConnectedDevices();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Connect area animations (0.0 - 0.3)
    _connectFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _connectSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    // AI Assistant animations (0.2 - 0.6)
    _assistantFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    _assistantSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    // Translate section animations (0.4 - 0.8)
    _translateFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.4, 0.8, curve: Curves.easeOut),
    ));

    _translateSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.4, 0.8, curve: Curves.easeOut),
    ));

    // Buttons animations (0.6 - 1.0)
    _buttonsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    _buttonsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Always restart animation when screen is visited
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart animation every time screen comes into focus
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    final bluetoothService = Get.find<BluetoothService>();
    bluetoothService.stopConnectedDevicePolling();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bluetoothService = Get.find<BluetoothService>();
    if (state == AppLifecycleState.resumed) {
      bluetoothService.startConnectedDevicePolling();
      bluetoothService.checkConnectedDevices();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      bluetoothService.stopConnectedDevicePolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF2F4),
      appBar: AppBar(
        title: Text(
          'Smart Translation Earbuds',
          style: AppTextStyles.heading
              .copyWith(fontSize: 18, color: Color(0xFF003049)),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEDF2F4),
        actions: [
          IconButton(
            icon: Icon(Icons.book, color: Color(0xFF003049)),
            onPressed: () {
              // TODO: Implement book functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Center(
              child: FadeTransition(
                opacity: _connectFadeAnimation,
                child: SlideTransition(
                  position: _connectSlideAnimation,
                  child: Obx(() {
                    final bluetoothService = Get.find<BluetoothService>();
                    if (bluetoothService.isConnecting.value) {
                      return Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF003049)),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Connecting...',
                            style: AppTextStyles.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                        ],
                      );
                    } else if (bluetoothService
                        .connectedDeviceName.value.isEmpty) {
                      return Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF003049),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add,
                                  color: Colors.white, size: 30),
                              onPressed: () {
                                bluetoothService.openBluetoothSettings();
                              },
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Connect',
                            style: AppTextStyles.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                        ],
                      );
                    } else {
                      return GestureDetector(
                        onTap: () {
                          bluetoothService.disconnect();
                        },
                        child: Column(
                          children: [
                            Text(
                              bluetoothService.connectedDeviceName.value,
                              style: AppTextStyles.heading.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Tap to disconnect',
                              style: AppTextStyles.body.copyWith(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _assistantFadeAnimation,
              child: SlideTransition(
                position: _assistantSlideAnimation,
                child: GestureDetector(
                  onTap: () => Get.toNamed('/assistant'),
                  child: Container(
                    width: double.infinity,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Color(0xFF003049),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Hi ~ I\'m your AI assistant',
                            style: AppTextStyles.body.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tap to start Chatting',
                                    style: AppTextStyles.body.copyWith(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.black,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _translateFadeAnimation,
              child: SlideTransition(
                position: _translateSlideAnimation,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Translate',
                    style: AppTextStyles.heading
                        .copyWith(fontSize: 20, color: Colors.black),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: FadeTransition(
                opacity: _buttonsFadeAnimation,
                child: SlideTransition(
                  position: _buttonsSlideAnimation,
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildTranslateButton('Free Talk (Dual Ear)', Icons.mic,
                          () => Get.toNamed('/free_talk')),
                      _buildTranslateButton(
                          'Translation Machine', Icons.translate, () {
                        Get.toNamed('/translation');
                      }),
                      _buildTranslateButton(
                          'Headphone & Phone', Icons.headphones, () {
                        Get.snackbar('Coming Soon',
                            'Headphone & Phone feature coming soon');
                      }),
                      _buildTranslateButton('Voice Notes', Icons.note, () {
                        Get.toNamed('/voice_notes');
                      }),
                      _buildTranslateButton('Photo Translation', Icons.photo,
                          () {
                        Get.toNamed('/photo_translation');
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslateButton(
      String title, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Color(0xFF003049),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            Icon(
              icon,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
