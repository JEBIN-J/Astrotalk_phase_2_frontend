import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 1. High Performance Animated Cosmic Starfield Background
class CosmicStarfieldBackground extends StatefulWidget {
  final Widget child;
  final int starCount;
  final bool isDark;

  const CosmicStarfieldBackground({
    super.key,
    required this.child,
    this.starCount = 45,
    this.isDark = true,
  });

  @override
  State<CosmicStarfieldBackground> createState() => _CosmicStarfieldBackgroundState();
}

class _CosmicStarfieldBackgroundState extends State<CosmicStarfieldBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_StarParticle> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    final rand = math.Random(42);
    _stars = List.generate(widget.starCount, (index) {
      return _StarParticle(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        radius: 0.8.r + rand.nextDouble() * 1.8,
        twinkleSpeed: 1.0 + rand.nextDouble() * 3.0,
        phase: rand.nextDouble() * math.pi * 2,
        color: rand.nextDouble() > 0.35
            ? (rand.nextBool() ? const Color(0xFF818CF8) : const Color(0xFF38BDF8))
            : const Color(0xFFFFD54F),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _StarfieldPainter(
                    stars: _stars,
                    progress: _controller.value,
                    isDark: widget.isDark,
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _StarParticle {
  final double x;
  final double y;
  final double radius;
  final double twinkleSpeed;
  final double phase;
  final Color color;

  _StarParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.twinkleSpeed,
    required this.phase,
    required this.color,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double progress;
  final bool isDark;

  _StarfieldPainter({
    required this.stars,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    for (final star in stars) {
      final t = (progress * star.twinkleSpeed * math.pi * 2 + star.phase);
      final opacity = 0.15 + 0.65 * ((math.sin(t) + 1) / 2);
      final alphaMultiplier = isDark ? 1.0 : 0.45;

      final paint = Paint()
        ..color = star.color.withValues(alpha: opacity * alphaMultiplier)
        ..style = PaintingStyle.fill;

      final center = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(center, star.radius, paint);

      // Subtle glow for larger stars
      if (star.radius > 1.8 && isDark) {
        final glowPaint = Paint()
          ..color = star.color.withValues(alpha: opacity * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(center, star.radius * 2.2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

/// 2. Pulsing Glow Aura for active transits, muhurtas & status tags
class PulsingAuraWidget extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlur;

  const PulsingAuraWidget({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF6366F1),
    this.maxBlur = 12.0,
  });

  @override
  State<PulsingAuraWidget> createState() => _PulsingAuraWidgetState();
}

class _PulsingAuraWidgetState extends State<PulsingAuraWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.2, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _animation.value * 0.4),
                blurRadius: widget.maxBlur * _animation.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 3. Shimmer Effect for Badges and Buttons
class ShimmerBadge extends StatefulWidget {
  final String text;
  final Gradient baseGradient;
  final Color textColor;
  final double fontSize;

  const ShimmerBadge({
    super.key,
    required this.text,
    required this.baseGradient,
    this.textColor = Colors.white,
    this.fontSize = 9.5,
  });

  @override
  State<ShimmerBadge> createState() => _ShimmerBadgeState();
}

class _ShimmerBadgeState extends State<ShimmerBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
          decoration: BoxDecoration(
            gradient: widget.baseGradient,
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: widget.textColor,
                  letterSpacing: 0.3,
                ),
              ),
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    final progress = _controller.value;
                    return LinearGradient(
                      begin: Alignment(-1.5 + 3.0 * progress, 0),
                      end: Alignment(-0.5 + 3.0 * progress, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ).createShader(bounds);
                  },
                  child: Container(color: Colors.white.withValues(alpha: 0.01)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 4. Tactile Bouncy Scale Feedback on Tap
class BouncyTouchCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const BouncyTouchCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.94,
  });

  @override
  State<BouncyTouchCard> createState() => _BouncyTouchCardState();
}

class _BouncyTouchCardState extends State<BouncyTouchCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// 5. Staggered Animated Item Entrance (Slide & Fade)
class StaggeredAnimatedItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;

  const StaggeredAnimatedItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  State<StaggeredAnimatedItem> createState() => _StaggeredAnimatedItemState();
}

class _StaggeredAnimatedItemState extends State<StaggeredAnimatedItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = widget.baseDelay * math.min(widget.index, 12);
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 6. Continuous Smooth Rotating Widget (for Mandalas, Sun, Moon & Chakras)
class SmoothRotatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool clockwise;

  const SmoothRotatingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 30),
    this.clockwise = true,
  });

  @override
  State<SmoothRotatingWidget> createState() => _SmoothRotatingWidgetState();
}

class _SmoothRotatingWidgetState extends State<SmoothRotatingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: RotationTransition(
        turns: widget.clockwise ? _controller : ReverseAnimation(_controller),
        child: widget.child,
      ),
    );
  }
}


/// Breathing Aura Widget (Pulsing Glow)
class BreathingAuraWidget extends StatefulWidget {
  final Widget child;
  final Color auraColor;
  final double beginScale;
  final double endScale;
  final Duration duration;

  const BreathingAuraWidget({
    super.key,
    required this.child,
    required this.auraColor,
    this.beginScale = 0.95,
    this.endScale = 1.05,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<BreathingAuraWidget> createState() => _BreathingAuraWidgetState();
}

class _BreathingAuraWidgetState extends State<BreathingAuraWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: widget.beginScale, end: widget.endScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.auraColor.withValues(alpha: 0.5 * (1 - (_animation.value - widget.beginScale) / (widget.endScale - widget.beginScale))),
                  blurRadius: 40 * _animation.value,
                  spreadRadius: 10 * _animation.value,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Floating Widget (Smooth Up and Down)
class FloatingWidget extends StatefulWidget {
  final Widget child;
  final double floatDistance;
  final Duration duration;

  const FloatingWidget({
    super.key,
    required this.child,
    this.floatDistance = 6.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -widget.floatDistance, end: widget.floatDistance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmering Border Container
class ShimmeringBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final List<Color> colors;
  final double borderWidth;
  final Duration duration;

  const ShimmeringBorder({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    required this.colors,
    this.borderWidth = 2.0,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<ShimmeringBorder> createState() => _ShimmeringBorderState();
}

class _ShimmeringBorderState extends State<ShimmeringBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: SweepGradient(
              colors: widget.colors,
              stops: _generateStops(widget.colors.length),
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: widget.borderRadius.subtract(BorderRadius.circular(widget.borderWidth / 2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.child,
          ),
        );
      },
    );
  }

  List<double> _generateStops(int length) {
    if (length <= 1) return [1.0];
    return List.generate(length, (index) => index / (length - 1));
  }
}



/// ─────────────────────────────────────────────────────────────
/// Cosmic Dust Particle Background
/// Tiny glowing particles drift slowly across the background
/// like cosmic dust suspended in deep space.
/// ─────────────────────────────────────────────────────────────
class CosmicDustBackground extends StatefulWidget {
  final int particleCount;
  final Color primaryColor;
  final Color accentColor;

  const CosmicDustBackground({
    super.key,
    this.particleCount = 60,
    this.primaryColor = Colors.white,
    this.accentColor = const Color(0xFFB0C4DE),
  });

  @override
  State<CosmicDustBackground> createState() => _CosmicDustBackgroundState();
}

class _CosmicDustBackgroundState extends State<CosmicDustBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_DustParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    final rng = math.Random(42); // fixed seed for consistent placement
    _particles = List.generate(widget.particleCount, (i) {
      // Purposely vary size a LOT: tiny dust, medium orbs, a few large soft glows
      final sizeClass = rng.nextDouble();
      final double size;
      final double opacity;
      if (sizeClass < 0.55) {
        // 55% are tiny specks  2–6px
        size = rng.nextDouble() * 4 + 2;
        opacity = rng.nextDouble() * 0.45 + 0.25;
      } else if (sizeClass < 0.85) {
        // 30% are medium dots  8–20px
        size = rng.nextDouble() * 12 + 8;
        opacity = rng.nextDouble() * 0.25 + 0.10;
      } else {
        // 15% are large soft glow orbs  28–55px
        size = rng.nextDouble() * 27 + 28;
        opacity = rng.nextDouble() * 0.08 + 0.04;
      }

      return _DustParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: size,
        speed: rng.nextDouble() * 0.18 + 0.06,
        driftX: (rng.nextDouble() - 0.5) * 0.06,
        opacity: opacity,
        colorIndex: rng.nextInt(2),
        twinkleOffset: rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => RepaintBoundary(
        child: CustomPaint(
          painter: _DustPainter(
            particles: _particles,
            t: _controller.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DustParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double driftX;
  final double opacity;
  final int colorIndex;
  final double twinkleOffset;

  const _DustParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.driftX,
    required this.opacity,
    required this.colorIndex,
    required this.twinkleOffset,
  });
}

class _DustPainter extends CustomPainter {
  final List<_DustParticle> particles;
  final double t;
  final Color primaryColor;
  final Color accentColor;

  _DustPainter({
    required this.particles,
    required this.t,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Vertical float upward, wrapping
      double cy = ((p.y - t * p.speed) % 1.0 + 1.0) % 1.0;
      // Gentle horizontal drift using sine wave
      double cx = p.x + math.sin(t * math.pi * 2 * 0.5 + p.y * 8) * p.driftX;
      cx = cx % 1.0;

      final px = cx * size.width;
      final py = cy * size.height;

      // Twinkle: subtle opacity oscillation
      final twinkle = math.sin(t * math.pi * 2 * 2 + p.twinkleOffset * math.pi * 2);
      final alpha = (p.opacity + twinkle * p.opacity * 0.3).clamp(0.0, 1.0);

      final color = p.colorIndex == 0
          ? primaryColor.withValues(alpha: alpha)
          : accentColor.withValues(alpha: alpha);

      if (p.size <= 6) {
        // Tiny dot — crisp point
        final paint = Paint()..color = color;
        canvas.drawCircle(Offset(px, py), p.size / 2, paint);
      } else if (p.size <= 22) {
        // Medium — soft filled circle with radial fade
        final paint = Paint()
          ..shader = RadialGradient(colors: [
            color,
            color.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: Offset(px, py), radius: p.size));
        canvas.drawCircle(Offset(px, py), p.size, paint);
      } else {
        // Large — very soft glow orb (double layer)
        final outerPaint = Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: alpha * 0.6),
            color.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: Offset(px, py), radius: p.size));
        canvas.drawCircle(Offset(px, py), p.size, outerPaint);

        final innerPaint = Paint()
          ..shader = RadialGradient(colors: [
            color,
            color.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: Offset(px, py), radius: p.size * 0.35));
        canvas.drawCircle(Offset(px, py), p.size * 0.35, innerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter old) =>
      old.t != t;
}
