import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiCallingScreen extends StatefulWidget {
  const AiCallingScreen({super.key});

  @override
  State<AiCallingScreen> createState() => _AiCallingScreenState();
}

class _AiCallingScreenState extends State<AiCallingScreen> with TickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeaker = true;
  int _seconds = 0;
  Timer? _timer;
  
  late AnimationController _rippleController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
    
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          // Background Gradient and Stars
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF0B1120)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 16.h),
                // Top Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: Color(0xFF34D399)),
                            SizedBox(width: 6.w),
                            Text(
                              'End-to-End Encrypted',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 32.w), // Balance spacing
                    ],
                  ),
                ),
                
                Spacer(),
                
                // AI Avatar with Ripples
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          final progress = (_rippleController.value + (index / 3)) % 1.0;
                          final size = 160.0 + (progress * 200.0);
                          final opacity = 1.0 - progress;
                          return Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFB7185).withValues(alpha: opacity * 0.5),
                                width: 2.w,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    
                    // Main Avatar
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.05),
                          child: Container(
                            width: 160.w,
                            height: 160.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(Icons.auto_awesome, size: 64, color: Colors.white),
                          ),
                        );
                      }
                    ),
                  ],
                ),
                
                SizedBox(height: 50.h),
                
                Text(
                  'Vedic AI Astrologer',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _formattedTime,
                  style: GoogleFonts.firaCode(
                    color: Colors.white70,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                Spacer(),
                
                // Controls Glass Panel
                Container(
                  margin: EdgeInsets.all(24.w),
                  padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 32.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(40.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: 'Mute',
                        isActive: _isMuted,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _buildEndCallButton(context),
                      _buildControlButton(
                        icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: 'Speaker',
                        isActive: _isSpeaker,
                        onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0F172A) : Colors.white,
              size: 28,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'End',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
