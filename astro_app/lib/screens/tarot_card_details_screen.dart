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
      backgroundColor: _primaryColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(cardData['name'] ?? 'Card Details',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                letterSpacing: 1.2,
                color: _primaryColor)),
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
            Positioned(
              top: -50.h, right: -50.w,
              child: Icon(Icons.star_outline_rounded,
                  size: 250.sp,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
            ),
            Positioned(
              top: 200.h, left: -40.w,
              child: Icon(Icons.auto_awesome,
                  size: 150.sp,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.12)),
            ),
            Positioned(
              bottom: 150.h, right: -30.w,
              child: Icon(Icons.brightness_4_outlined,
                  size: 180.sp,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Card image + title ──────────────────────────────────
                    Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 20.h, horizontal: 16.w),
                      child: Column(
                        children: [
                          Text(positionName.toUpperCase(),
                              style: GoogleFonts.outfit(
                                  fontSize: 14.sp,
                                  color: _primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0)),
                          SizedBox(height: 24.h),
                          Hero(
                            tag: 'card_${cardData['card_id']}',
                            child: Container(
                              height: 380.h,
                              width: 230.w,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: _primaryColor.withValues(alpha: 0.5),
                                    width: 2.0),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          _primaryColor.withValues(alpha: 0.15),
                                      blurRadius: 40,
                                      spreadRadius: 5),
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 15))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18.r),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.transparenttextures.com/patterns/stardust.png',
                                      repeat: ImageRepeat.repeat,
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
                                      colorBlendMode: BlendMode.modulate,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(4.w),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(14.r),
                                        child: Image.network(
                                          '${AstroApiService.baseUrl.replaceAll('/api/v1', '')}/static/${cardData['image'] ?? 'assets/tarot/${cardData['name'].toString().toLowerCase().replaceAll(' ', '_')}.webp'}?v=3',
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            final localAssetPath =
                                                'assets/images/tarot/cards/${cardData['name'].toString().toLowerCase().replaceAll(' ', '_')}.jpg';
                                            return Image.asset(
                                              localAssetPath,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/tarot/tarot_back.jpg',
                                                    fit: BoxFit.cover,
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
                                                    colorBlendMode:
                                                        BlendMode.darken,
                                                  ),
                                                  Icon(
                                                      Icons.style_outlined,
                                                      size: 72.sp,
                                                      color: const Color(
                                                          0xFFF5D67D)),
                                                ],
                                              ),
                                            );
                                          },
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
                            style: GoogleFonts.outfit(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                                height: 1.1),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            orientation,
                            style: GoogleFonts.outfit(
                                fontSize: 18.sp,
                                color: _primaryColor.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic),
                          ),
                          // arcana / suit badge row
                          if (cardData['arcana_type'] != null ||
                              cardData['suit'] != null) ...[
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (cardData['arcana_type'] != null)
                                  _badge(
                                      '${cardData['arcana_type']} Arcana'),
                                if (cardData['suit'] != null)
                                  _badge('${cardData['suit']}'),
                                if (cardData['number'] != null)
                                  _badge('Card ${cardData['number']}'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Keywords ────────────────────────────────────────────
                    if (keywords.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Center(
                          child: Wrap(
                            spacing: 10.w,
                            runSpacing: 10.h,
                            alignment: WrapAlignment.center,
                            children: keywords
                                .map((k) => Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: _primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(30.r),
                                        border: Border.all(
                                            color: _primaryColor
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        k.toString().toUpperCase(),
                                        style: GoogleFonts.outfit(
                                            color: _primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.sp,
                                            letterSpacing: 1.0),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),

                    SizedBox(height: 28.h),

                    // ── Single combined interpretation card ─────────────────
                    Builder(builder: (context) {
                      final combined = _buildCombinedInterpretation(cardData, isReversed);
                      if (combined.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Detailed Interpretation'),
                            _buildGlassCard(combined),
                            SizedBox(height: 28.h),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds one info section — only renders if [value] is non-null & non-empty.
  Widget _buildRealSection({
    required IconData icon,
    required String title,
    required String? value,
  }) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                    letterSpacing: 1.5),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.25), width: 1.2),
            ),
            child: Text(
              value.trim(),
              style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  height: 1.65,
                  color: _primaryColor.withValues(alpha: 0.92),
                  letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  /// Small badge chip for arcana/suit/number.
  Widget _badge(String label) => Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.r),
          border:
              Border.all(color: _primaryColor.withValues(alpha: 0.35)),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11.sp,
                color: _primaryColor,
                fontWeight: FontWeight.w600)),
      );

  /// Joins non-null, non-empty strings with a newline separator.
  String? _joinNonNull(List<String?> values) {
    final filtered =
        values.where((v) => v != null && v.trim().isNotEmpty).cast<String>().toList();
    return filtered.isEmpty ? null : filtered.join('\n\n');
  }



  /// Builds one combined interpretation string from REAL backend fields only.
  /// Ignores the repetitive auto-generated placeholders and uses the handcrafted meanings.
  String _buildCombinedInterpretation(Map<String, dynamic> data, bool isReversed) {
    String interpretation = "";

    // 1. Core Meaning (Prioritize handcrafted 'meaning_upright' over templated 'upright_meaning')
    String coreMeaning = isReversed
        ? (data['meaning_reversed']?.toString() ?? data['reversed_meaning']?.toString() ?? '')
        : (data['meaning_upright']?.toString() ?? data['upright_meaning']?.toString() ?? data['core_meaning']?.toString() ?? '');
    
    if (coreMeaning.trim().isNotEmpty) {
      interpretation += coreMeaning.trim();
    }

    // 2. Full description (handcrafted lore/imagery)
    String desc = data['description']?.toString() ?? data['card_description']?.toString() ?? '';
    if (desc.trim().isNotEmpty) {
      if (interpretation.isNotEmpty) interpretation += "\n\n";
      interpretation += desc.trim();
    }

    // (We intentionally skip the templated fields like love_meaning, career_meaning, 
    // past_meaning, etc., because they are just auto-generated repetitive placeholders
    // that repeat the same keywords over and over, ruining the readability.)

    // 3. Yes/No Answer
    String yesNo = data['yes_no_meaning']?.toString() ?? '';
    if (yesNo.trim().isNotEmpty) {
      if (interpretation.isNotEmpty) interpretation += "\n\n";
      interpretation += "✦ Answer: ${yesNo.trim()}";
    }

    // 4. Advice / Guidance
    String advice = data['advice']?.toString() ?? '';
    if (advice.trim().isNotEmpty) {
      if (interpretation.isNotEmpty) interpretation += "\n\n";
      interpretation += "✦ Guidance: ${advice.trim()}";
    }

    // Fallback if everything is somehow missing
    if (interpretation.trim().isEmpty) {
      return "The cosmos holds the wisdom of ${data['name'] ?? 'this card'} close for now. Sit in quiet reflection and the meaning will reveal itself.";
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
