import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle body = GoogleFonts.montserrat(
    fontSize: 16,
    color: AppColors.text,
  );

  static TextStyle button = GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}
