import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home'), backgroundColor: AppColors.primary),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Get.toNamed('/translation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.button,
          ),
          child: Text('Translation Machine'),
        ),
      ),
    );
  }
}
