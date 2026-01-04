import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/services/bluetooth_service.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Get.put(BluetoothService());
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Smart Translation Earbuds',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.book, color: Colors.white),
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
              child: Obx(() {
                final bluetoothService = Get.find<BluetoothService>();
                if (bluetoothService.connectedDeviceName.value.isEmpty) {
                  return Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.gradientEnd],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: Colors.white, size: 30),
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
                            color: Colors.white),
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
                              color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Tap to disconnect',
                          style: AppTextStyles.body
                              .copyWith(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00453d), Color(0xFF01201b)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tap to start Chatting',
                              style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Translate',
                style: AppTextStyles.heading.copyWith(fontSize: 20),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildTranslateButton('Free Talk (Dual Ear)', Icons.mic, () {
                    Get.snackbar(
                        'Coming Soon', 'Free Talk feature coming soon');
                  }),
                  _buildTranslateButton('Translation Machine', Icons.translate,
                      () {
                    Get.toNamed('/translation');
                  }),
                  _buildTranslateButton('Headphone & Phone', Icons.headphones,
                      () {
                    Get.snackbar(
                        'Coming Soon', 'Headphone & Phone feature coming soon');
                  }),
                  _buildTranslateButton('Voice Notes', Icons.note, () {
                    Get.snackbar(
                        'Coming Soon', 'Voice Notes feature coming soon');
                  }),
                  _buildTranslateButton('Photo Translation', Icons.photo, () {
                    Get.snackbar(
                        'Coming Soon', 'Photo Translation feature coming soon');
                  }),
                ],
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
          color: AppColors.buttonBackground,
          borderRadius: BorderRadius.circular(10),
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
              color: AppColors.gradientEnd,
            ),
          ],
        ),
      ),
    );
  }
}
