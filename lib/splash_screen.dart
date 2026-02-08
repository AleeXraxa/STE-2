import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 120));
    _controller.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          Positioned(
            top: -size.width * 0.15,
            right: -size.width * 0.2,
            child: _GlowOrb(
              size: size.width * 0.65,
              colors: const [Color(0xFF00F5D4), Color(0x0000F5D4)],
            ),
          ),
          Positioned(
            bottom: -size.width * 0.25,
            left: -size.width * 0.1,
            child: _GlowOrb(
              size: size.width * 0.7,
              colors: const [Color(0xFF7BDFF2), Color(0x007BDFF2)],
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0x33FFFFFF),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'STE',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Smart Translation Earbuds',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Instant, hands-free conversations',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                height: 6,
                                width: 180,
                                child: LinearProgressIndicator(
                                  value: _controller.value.clamp(0.0, 1.0),
                                  backgroundColor: const Color(0x22FFFFFF),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF00F5D4),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowOrb({
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
