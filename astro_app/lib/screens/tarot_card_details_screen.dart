import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/astro_api_service.dart';

import '../theme/app_theme.dart';

class TarotCardDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final String positionName;
  final AppColorPalette currentPalette;
  final bool isDark;

  const TarotCardDetailsScreen({
    Key? key, 
    required this.cardData, 
    required this.positionName,
    this.currentPalette = AppColorPalette.emeraldDivine,
    this.isDark = false,
  }) : super(key: key);

  Color get _primaryColor {
    switch (currentPalette) {
      case AppColorPalette.sacredSaffron: return AppTheme.saffronPrimary;
      case AppColorPalette.emeraldDivine: return AppTheme.emeraldPrimary;
      case AppColorPalette.royalIndigo: return AppTheme.royalIndigo;
      case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicNavy;
    }
  }

  Color get _surfaceColor {
    if (isDark) {
      switch (currentPalette) {
        case AppColorPalette.sacredSaffron: return AppTheme.saffronCard;
        case AppColorPalette.emeraldDivine: return AppTheme.emeraldCard;
        case AppColorPalette.royalIndigo: return AppTheme.royalCard;
        case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicSurface;
      }
    } else {
      switch (currentPalette) {
        case AppColorPalette.sacredSaffron: return const Color(0xFFFFF7F0);
        case AppColorPalette.emeraldDivine: return const Color(0xFFF5FBF6);
        case AppColorPalette.royalIndigo: return const Color(0xFFF3F5FC);
        case AppColorPalette.midnightCosmic: default: return const Color(0xFFF4F7FB);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = cardData['orientation'] as String? ?? 'Upright';
    final isReversed = orientation == 'Reversed';
    final keywords = cardData['keywords'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: _primaryColor, // Deep theme background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(cardData['name'] ?? 'Card Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18.sp, letterSpacing: 1.2, color: _primaryColor)),
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _surfaceColor,
              isDark ? _surfaceColor : const Color(0xFFFFFCED),
              _surfaceColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle gold background designs
            Positioned(
              top: -50.h,
              right: -50.w,
              child: Icon(Icons.star_outline_rounded, size: 250.sp, color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
            ),
            Positioned(
              top: 200.h,
              left: -40.w,
              child: Icon(Icons.auto_awesome, size: 150.sp, color: const Color(0xFFFFD700).withValues(alpha: 0.12)),
            ),
            Positioned(
              bottom: 150.h,
              right: -30.w,
              child: Icon(Icons.brightness_4_outlined, size: 180.sp, color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
            ),
            // 4. Main Content
            SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 40.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                  child: Column(
                    children: [
                      Text(
                        positionName.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 14.sp, color: _primaryColor, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      ),
                      SizedBox(height: 24.h),
                      // Image placeholder/render
                      Hero(
                        tag: 'card_${cardData['card_id']}',
                        child: Container(
                          height: 380.h,
                          width: 230.w,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: _primaryColor.withValues(alpha: 0.5), width: 2.0),
                            boxShadow: [
                              BoxShadow(color: _primaryColor.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5),
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 15))
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18.r),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  'https://www.transparenttextures.com/patterns/stardust.png',
                                  repeat: ImageRepeat.repeat,
                                  color: Colors.white.withValues(alpha: 0.05),
                                  colorBlendMode: BlendMode.modulate,
                                ),
                                Padding(
                                  padding: EdgeInsets.all(4.w),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14.r),
                                    child: Image.network(
                                      '${AstroApiService.baseUrl.replaceAll('/api/v1', '')}/static/${cardData['image'] ?? 'assets/tarot/${cardData['name'].toString().toLowerCase().replaceAll(' ', '_')}.webp'}?v=3',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            'assets/images/tarot/tarot_back.jpg',
                                            fit: BoxFit.cover,
                                            color: Colors.black.withValues(alpha: 0.5),
                                            colorBlendMode: BlendMode.darken,
                                          ),
                                          Icon(Icons.style_outlined, size: 72.sp, color: const Color(0xFFF5D67D)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        '${cardData['name']}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 32.sp, fontWeight: FontWeight.bold, color: _primaryColor, height: 1.1),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        orientation,
                        style: GoogleFonts.outfit(fontSize: 18.sp, color: _primaryColor.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (keywords.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Center(
                          child: Wrap(
                            spacing: 10.w,
                            runSpacing: 10.h,
                            alignment: WrapAlignment.center,
                            children: keywords.map((k) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1), // Theme colored glass
                                borderRadius: BorderRadius.circular(30.r),
                                border: Border.all(color: _primaryColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                k.toString().toUpperCase(), 
                                style: GoogleFonts.outfit(color: _primaryColor, fontWeight: FontWeight.w600, fontSize: 12.sp, letterSpacing: 1.0)
                              ),
                            )).toList(),
                          ),
                        ),
                        SizedBox(height: 36.h),
                      ],
                      
                      _buildSectionTitle('Detailed Interpretation'),
                      _buildGlassCard(_generateDetailedInterpretation(cardData, isReversed)),
                      SizedBox(height: 28.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
      ),
    );
  }

  String _generateDetailedInterpretation(Map<String, dynamic> data, bool isReversed) {
    String interpretation = "";
    
    // 1. Base Meaning
    String baseMeaning = isReversed ? (data['reversed_meaning'] ?? '') : (data['upright_meaning'] ?? '');
    if (baseMeaning.isNotEmpty) {
      interpretation += baseMeaning;
    }
    
    // 2. Add Life Areas seamlessly
    String lifeAreas = "";
    if (data['love_meaning'] != null) lifeAreas += "${data['love_meaning']} ";
    if (data['career_meaning'] != null) lifeAreas += "${data['career_meaning']} ";
    if (data['finance_meaning'] != null) lifeAreas += "${data['finance_meaning']} ";
    if (data['spiritual_meaning'] != null) lifeAreas += "${data['spiritual_meaning']} ";
    
    if (lifeAreas.trim().isNotEmpty) {
      interpretation += "\n\n" + lifeAreas.trim();
    }
    
    // 3. Add Advice
    if (data['advice'] != null) {
      interpretation += "\n\nGuidance: ${data['advice']}";
    }
    
    // 4. Fallback if absolutely everything is missing
    if (interpretation.isEmpty) {
      interpretation = data['context_meaning'] ?? data['core_meaning'] ?? "The cosmos keeps its secrets for now.";
    }
    
    return interpretation;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h, left: 4.w),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: _primaryColor, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _primaryColor, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.1), // Solid theme glass without blur
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        content,
        style: GoogleFonts.outfit(
          fontSize: 17.sp, 
          height: 1.6, 
          color: _primaryColor.withValues(alpha: 0.95),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
