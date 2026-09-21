import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tarot_dashboard_screen.dart';

class TarotAnimationScreen extends StatefulWidget {
  const TarotAnimationScreen({Key? key}) : super(key: key);

  @override
  State<TarotAnimationScreen> createState() => _TarotAnimationScreenState();
}

class _TarotAnimationScreenState extends State<TarotAnimationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _rotationAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _textOpacityAnim;
  late Animation<double> _bgScaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationAnim = Tween<double>(begin: 0.0, end: 2.0 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.1).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 60),
    ]).animate(_controller);

    _glowAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 5.0, end: 40.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 40.0, end: 10.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(_controller);

    _textOpacityAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    ]).animate(_controller);
    
    _bgScaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const TarotDashboardScreen(),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Beautiful generated splash screen image with slow zoom-in
              Positioned.fill(
                child: Transform.scale(
                  scale: _bgScaleAnim.value,
                  child: Image.asset(
                    'assets/images/tarot/tarot_splash_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Subtle dark gradient overlay at the bottom for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200.h,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF0B0F19).withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Fading Text over the gorgeous background
              Positioned(
                bottom: 80.h,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _textOpacityAnim.value,
                  child: Text(
                    "Connecting to the mystical energies...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
