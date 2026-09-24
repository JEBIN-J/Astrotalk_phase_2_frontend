import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tarot_dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/celestial_animations.dart';

class TarotAnimationScreen extends StatefulWidget {
  final AppColorPalette currentPalette;
  final bool isDark;

  const TarotAnimationScreen({
    super.key, 
    this.currentPalette = AppColorPalette.midnightCosmic,
    this.isDark = false,
  });

  @override
  State<TarotAnimationScreen> createState() => _TarotAnimationScreenState();
}

class _TarotAnimationScreenState extends State<TarotAnimationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => TarotDashboardScreen(
                currentPalette: widget.currentPalette,
                isDark: widget.isDark,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
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

  Color get _primaryColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return AppTheme.saffronPrimary;
      case AppColorPalette.emeraldDivine: return AppTheme.emeraldPrimary;
      case AppColorPalette.royalIndigo: return AppTheme.royalIndigo;
      case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicNavy;
    }
  }

  Color get _surfaceColor {
    if (widget.isDark) {
      switch (widget.currentPalette) {
        case AppColorPalette.sacredSaffron: return AppTheme.saffronCard;
        case AppColorPalette.emeraldDivine: return AppTheme.emeraldCard;
        case AppColorPalette.royalIndigo: return AppTheme.royalCard;
        case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicSurface;
      }
    } else {
      switch (widget.currentPalette) {
        case AppColorPalette.sacredSaffron: return const Color(0xFFFFF7F0);
        case AppColorPalette.emeraldDivine: return const Color(0xFFF5FBF6);
        case AppColorPalette.royalIndigo: return const Color(0xFFF3F5FC);
        case AppColorPalette.midnightCosmic: default: return const Color(0xFFF4F7FB);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int numCards = 10; 
    final double radius = 130.w;

    return Scaffold(
      backgroundColor: _primaryColor, 
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
          // 1. Theme-appropriate Cosmic Background Image
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Subtle zoom-in effect on the background
                final double bgScale = 1.0 + (_controller.value * 0.15);
                return Transform.scale(
                  scale: bgScale,
                  child: SizedBox.expand(
                    child: Image.asset(
                      'assets/images/tarot/tarot_bg.jpg',
                      fit: BoxFit.cover,
                      color: widget.currentPalette == AppColorPalette.emeraldDivine 
                          ? Colors.black.withValues(alpha: 0.3)
                          : _primaryColor.withValues(alpha: 0.6), 
                      colorBlendMode: widget.currentPalette == AppColorPalette.emeraldDivine 
                          ? BlendMode.darken
                          : BlendMode.overlay,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. Elegant Starfield
          Positioned.fill(
            child: CosmicStarfieldBackground(
              isDark: widget.isDark,
              starCount: 250, // Even more bubbles!
              child: Container(),
            ),
          ),
          
          // Cards flying animation
          ...List.generate(numCards, (i) {
            final double initialAngle = (i / numCards) * 2 * math.pi;
            
            final Animation<double> flyInAnim = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic), 
            );
            
            final Animation<double> rotateAnim = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.25, 0.7, curve: Curves.easeInOutSine), 
            );
            
            final double startFlyOut = 0.7 + (i * 0.03); 
            final double endFlyOut = math.min(1.0, startFlyOut + 0.15);
            final Animation<double> flyOutAnim = CurvedAnimation(
              parent: _controller,
              curve: Interval(startFlyOut, endFlyOut, curve: Curves.easeInBack),
            );

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double currentAngle = initialAngle + (rotateAnim.value * 2 * math.pi * 1.5);
                
                double x = 0;
                double y = 0;
                double scale = 1.0;
                
                if (flyOutAnim.value > 0.0) {
                  final startX = radius * math.cos(currentAngle);
                  final startY = radius * math.sin(currentAngle);
                  
                  x = startX + (flyOutAnim.value * 500.w); 
                  y = startY + (math.pow(flyOutAnim.value, 2) * 200.h); 
                  scale = 1.0 - (flyOutAnim.value * 0.5); 
                } else {
                  final targetX = radius * math.cos(currentAngle);
                  final targetY = radius * math.sin(currentAngle);
                  
                  final normalizedY = (math.sin(currentAngle) + 1) / 2; 
                  final depthScale = 0.85 + (normalizedY * 0.3); 
                  
                  final startX = -300.w;
                  final startY = -400.h;
                  
                  x = startX + (targetX - startX) * flyInAnim.value;
                  y = startY + (targetY - startY) * flyInAnim.value;
                  
                  final hoverY = math.sin((_controller.value * math.pi * 8) + i) * 10.h;
                  y += hoverY * rotateAnim.value;
                  
                  scale = depthScale * (0.2 + (flyInAnim.value * 0.8));
                }
                
                final double flipAngle = (1.0 - flyInAnim.value) * math.pi * 6; 
                final double exitSpin = flyOutAnim.value * math.pi * 2;
                final double finalRotationY = flipAngle + exitSpin;
                final double finalRotationZ = (flyOutAnim.value * math.pi * 0.5);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0005) // Reduced perspective to prevent Z-clipping missing cards
                    ..translate(x, y)
                    ..scale(scale)
                    ..rotateY(finalRotationY)
                    ..rotateZ(finalRotationZ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: (flyInAnim.value - flyOutAnim.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 50.w, 
                      height: 85.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/tarot/tarot_back.jpg'),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.9), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5D67D).withValues(alpha: 0.8), // Stronger bright glow
                            blurRadius: 20, 
                            spreadRadius: 4
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.7), // Stronger drop shadow
                            blurRadius: 15, 
                            offset: const Offset(0, 5)
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // 5. Elegant Fading Text at the bottom
          Positioned(
            bottom: 80.h,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double opacity = 0.0;
                if (_controller.value < 0.2) {
                  opacity = _controller.value * 5;
                } else if (_controller.value > 0.8) {
                  opacity = (1.0 - _controller.value) * 5;
                } else {
                  opacity = 0.7 + 0.3 * math.sin(_controller.value * math.pi * 10);
                }
                
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Text(
                    "Connecting to mystical energies...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFF5D67D), 
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}
