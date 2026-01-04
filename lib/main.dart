import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/app_routes.dart';
import 'core/theme/colors.dart';
import 'core/theme/text_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    print('Warning: .env file not found: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Multilingual Earbuds Translator',
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.getPages,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        textTheme: TextTheme(
          headlineLarge: AppTextStyles.heading,
          bodyLarge: AppTextStyles.body,
          labelLarge: AppTextStyles.button,
        ),
      ),
    );
  }
}
