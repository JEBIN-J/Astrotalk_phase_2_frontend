import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/celestial_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  int _selectedWidgetIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Android Home Screen Widgets',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        physics: const BouncingScrollPhysics(),
        children: [
          Text('Live Widget Previews', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 12.h),

          // Widget 1: Daily Panchang Widget
          BouncyTouchCard(
            onTap: () => setState(() => _selectedWidgetIndex = 0),
            child: _buildWidgetPreviewCard(
              'Daily Panchang & Rahu Kaal (4x2)',
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: _selectedWidgetIndex == 0 ? const Color(0xFF4F46E5) : const Color(0xFFD97706).withValues(alpha: 0.4), width: _selectedWidgetIndex == 0 ? 2 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TODAY\'S PANCHANG', style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
                        Text('New Delhi', style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.white70)),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text('Shukla Dwitiya • Rohini Nakshatra', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text('☀️ Sunrise: 06:41 AM', style: GoogleFonts.outfit(fontSize: 11.sp, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 8.w),
                        Flexible(child: Text('⚠️ Rahu Kaal: 12:28 - 02:04 PM', style: GoogleFonts.outfit(fontSize: 11.sp, color: const Color(0xFFF87171), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              isDark,
              isSelected: _selectedWidgetIndex == 0,
            ),
          ),
          SizedBox(height: 16.h),

          // Widget 2: Live Astrological Clock
          BouncyTouchCard(
            onTap: () => setState(() => _selectedWidgetIndex = 1),
            child: _buildWidgetPreviewCard(
              'Live Rahu Kaal & Muhurta Clock (2x2)',
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(18.r),
                  border: _selectedWidgetIndex == 1 ? Border.all(color: const Color(0xFF4F46E5), width: 2.w) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ABHIJIT MUHURTA', style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white70)),
                    SizedBox(height: 2.h),
                    Text('Active Now', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    Text('11:58 AM - 12:49 PM', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 11.sp)),
                  ],
                ),
              ),
              isDark,
              isSelected: _selectedWidgetIndex == 1,
            ),
          ),
          SizedBox(height: 24.h),

          BouncyTouchCard(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Widget pinned to Android Home Screen!', style: GoogleFonts.outfit()),
                  backgroundColor: const Color(0xFF4F46E5),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              height: 52.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_to_home_screen_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8.w),
                  Text('Pin Widget to Home Screen', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetPreviewCard(String title, Widget preview, bool isDark, {bool isSelected = false}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4F46E5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp)),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 18),
            ],
          ),
          SizedBox(height: 10.h),
          preview,
        ],
      ),
    );
  }
}
