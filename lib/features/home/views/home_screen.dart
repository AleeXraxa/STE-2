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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1F2A),
              Color(0xFF12394A),
              Color(0xFF0B2A36),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                FadeTransition(
                  opacity: _connectFadeAnimation,
                  child: SlideTransition(
                    position: _connectSlideAnimation,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Translation Earbuds',
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Instant, hands-free conversations',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0x33FFFFFF),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.book, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _connectFadeAnimation,
                  child: SlideTransition(
                    position: _connectSlideAnimation,
                    child: Obx(() {
                      final bluetoothService = Get.find<BluetoothService>();
                      final isConnected =
                          bluetoothService.connectedDeviceName.value.isNotEmpty;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? const Color(0xFF00F5D4)
                                    : const Color(0xFF203846),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isConnected
                                    ? Icons.bluetooth_connected
                                    : Icons.bluetooth,
                                color: isConnected
                                    ? const Color(0xFF003049)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: bluetoothService.isConnecting.value
                                  ? Text(
                                      'Connecting...',
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : isConnected
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bluetoothService
                                                  .connectedDeviceName.value,
                                              style:
                                                  AppTextStyles.body.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Tap to disconnect',
                                              style:
                                                  AppTextStyles.body.copyWith(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'No device connected',
                                              style:
                                                  AppTextStyles.body.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Open Bluetooth settings',
                                              style:
                                                  AppTextStyles.body.copyWith(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isConnected
                                      ? const Color(0xFF2B4756)
                                      : const Color(0xFF00F5D4),
                                  foregroundColor: isConnected
                                      ? Colors.white
                                      : const Color(0xFF003049),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                onPressed: () {
                                  if (bluetoothService.isConnecting.value) {
                                    return;
                                  }
                                  if (isConnected) {
                                    bluetoothService.disconnect();
                                  } else {
                                    bluetoothService.openBluetoothSettings();
                                  }
                                },
                                child: Text(
                                  isConnected ? 'Disconnect' : 'Connect',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _assistantFadeAnimation,
                  child: SlideTransition(
                    position: _assistantSlideAnimation,
                    child: GestureDetector(
                      onTap: () => Get.toNamed('/assistant'),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF00F5D4), Color(0xFF7BDFF2)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0x33003049),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF003049),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Assistant',
                                      style: AppTextStyles.heading.copyWith(
                                        color: const Color(0xFF003049),
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ask anything. Translate instantly.',
                                      style: AppTextStyles.body.copyWith(
                                        color: const Color(0xCC003049),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF003049),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _translateFadeAnimation,
                  child: SlideTransition(
                    position: _translateSlideAnimation,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Translate',
                        style: AppTextStyles.heading
                            .copyWith(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FadeTransition(
                    opacity: _buttonsFadeAnimation,
                    child: SlideTransition(
                      position: _buttonsSlideAnimation,
                      child: GridView.count(
                        crossAxisCount: size.width < 380 ? 1 : 2,
                        childAspectRatio: size.width < 380 ? 3.2 : 1.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildFeatureCard(
                            'Free Talk (Dual Ear)',
                            Icons.mic,
                            const Color(0xFF2B4756),
                            () => Get.toNamed('/free_talk'),
                          ),
                          _buildFeatureCard(
                            'Translation Machine',
                            Icons.translate,
                            const Color(0xFF1D6E7A),
                            () => Get.toNamed('/translation'),
                          ),
                          _buildFeatureCard(
                            'Voice Notes',
                            Icons.note,
                            const Color(0xFF2D5A4F),
                            () => Get.toNamed('/voice_notes'),
                          ),
                          _buildFeatureCard(
                            'Photo Translation',
                            Icons.photo,
                            const Color(0xFF3D5A80),
                            () => Get.toNamed('/photo_translation'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    IconData icon,
    Color accent,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Open',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
