import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import '../widgets/celestial_animations.dart';

class TarotLearnModuleScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Map<String, String>> sections;
  final AppColorPalette currentPalette;
  final Color primaryColor;
  final bool isDark;
  final Color accentColor;

  const TarotLearnModuleScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.currentPalette,
    required this.primaryColor,
    required this.isDark,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = accentColor;
    final surfaceColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.cosmicNavy : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.celestialGold),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: AppTheme.celestialGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Header Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.getHeaderGradient(currentPalette, isDark),
              ),
              child: CosmicStarfieldBackground(
                isDark: isDark,
                starCount: 36,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CosmicDustBackground(
                        particleCount: 60,
                        primaryColor: primaryColor,
                        accentColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.only(top: 60.h, bottom: 40.h),
              physics: const BouncingScrollPhysics(),
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(32.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Center(
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        ...sections.map((section) => _buildContentSection(section['title']!, section['body']!, themeColor, textColor)).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(String sectionTitle, String body, Color themeColor, Color textColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: themeColor, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  sectionTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              height: 1.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
