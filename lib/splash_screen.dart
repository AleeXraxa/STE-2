import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  _startAnimation() async {
    // Fade in over 3 seconds
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      _opacity = 1.0;
    });

    // Show spinner after fade-in completes
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      _showSpinner = true;
    });

    // Wait 3 seconds with spinner, then navigate
    await Future.delayed(Duration(seconds: 3));
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF003049),
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: Duration(seconds: 3),
          curve: Curves.easeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'STE',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Smart Translation Earbuds',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              if (_showSpinner) ...[
                SizedBox(height: 40),
                SpinKitFadingCircle(
                  color: Colors.white,
                  size: 50.0,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
