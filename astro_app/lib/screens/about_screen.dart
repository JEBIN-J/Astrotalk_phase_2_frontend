import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'About ABC App',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 44),
                ),
                SizedBox(height: 14.h),
                Text('ABC App', style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.w800)),
                Text('Advanced Vedic Astrology & Panchanga Platform', style: GoogleFonts.outfit(fontSize: 13.sp, color: Colors.grey)),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('Version 2.4.0 (Build 2026.08)', style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          Text('Engine Specifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 12.h),
          _buildInfoTile('Calculation Core', 'High Precision Core Engine', isDark),
          _buildInfoTile('Ayanamsa Precision', 'Lahiri (Chitra Paksha) with 0.001" arcsecond precision', isDark),
          _buildInfoTile('Panchanga Algorithm', 'Traditional 5-Anga Surya Siddhanta + Modern Ephemeris', isDark),
          _buildInfoTile('Kundli Milan', '36 Guna Ashtakoota with Nadi & Bhakoot dosha cancellation', isDark),
          SizedBox(height: 20.h),

          Text('Legal & Privacy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 12.h),
          _buildActionTile('Privacy Policy', Icons.privacy_tip_outlined, isDark),
          _buildActionTile('Terms of Service', Icons.description_outlined, isDark),
          _buildActionTile('Open Source Licenses', Icons.code_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String desc, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: const Color(0xFF3B82F6))),
          SizedBox(height: 3.h),
          Text(desc, style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        title: Text(title, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () {},
      ),
    );
  }
}
