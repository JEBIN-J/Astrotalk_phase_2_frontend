import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/astro_item.dart';

class ComingSoonScreen extends StatefulWidget {
  final AstroItem item;
  const ComingSoonScreen({super.key, required this.item});

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  IconData _getIcon() {
    switch (widget.item.id) {
      case 'ai_calling': return Icons.mic_rounded;
      case 'chat_bot': return Icons.auto_awesome;
      case 'face_reading': return Icons.face_retouching_natural_rounded;
      case 'palm_reading': return Icons.back_hand_rounded;
      case 'notifications': return Icons.notifications_active_rounded;
      case 'subscribe': return Icons.workspace_premium_rounded;
      default: return Icons.rocket_launch_rounded;
    }
  }
  
  String _getDescription() {
    switch (widget.item.id) {
      case 'ai_calling':
        return "We are training our AI on thousands of classical Vedic scriptures to provide you with real-time, personalized voice consultations.";
      case 'chat_bot':
        return "Our advanced AI Astrologer Chat Bot is currently analyzing planetary movements to bring you instant, accurate chat consultations.";
      case 'face_reading':
        return "We are perfecting our AI facial mapping technology to read your planetary influences directly from your facial structure.";
      case 'palm_reading':
        return "Our AI is currently learning the ancient art of Palmistry (Samudrika Shastra) to decode the lines on your hands with high precision.";
      case 'notifications':
        return "We are building a smart push notification system to instantly alert you of major planetary transits and customized daily horoscopes.";
      case 'subscribe':
        return "Our premium Astro Pro subscription is coming soon! Unlock unlimited AI consultations, high-resolution PDF downloads, and ad-free access.";
      default:
        return "We are working hard to bring this amazing new feature to you very soon. Stay tuned!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.1),
                          child: Container(
                            width: 140.w,
                            height: 140.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [widget.item.primaryColor, widget.item.secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.item.secondaryColor.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10 * _pulseController.value,
                                ),
                              ],
                            ),
                            child: Icon(_getIcon(), size: 70, color: Colors.white),
                          ),
                        );
                      }
                    ),
                    SizedBox(height: 48.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'COMING SOON',
                        style: GoogleFonts.outfit(
                          color: widget.item.secondaryColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      widget.item.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _getDescription(),
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 15.sp,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('We will notify you when ${widget.item.title} goes live!'),
                              backgroundColor: widget.item.secondaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(color: widget.item.secondaryColor, width: 1.5),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Notify Me',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
