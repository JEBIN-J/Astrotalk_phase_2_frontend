import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/astro_api_service.dart';

class TarotCardDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final String positionName;

  const TarotCardDetailsScreen({Key? key, required this.cardData, required this.positionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orientation = cardData['orientation'] as String? ?? 'Upright';
    final isReversed = orientation == 'Reversed';
    final keywords = cardData['keywords'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF021B10), // Dark green background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(cardData['name'] ?? 'Card Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18.sp, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF5D67D),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/tarot/tarot_cosmic_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0xFF021B10).withValues(alpha: 0.85), // Dark green tint
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
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
                        style: GoogleFonts.outfit(fontSize: 14.sp, color: const Color(0xFFF5D67D), fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      ),
                      SizedBox(height: 24.h),
                      // Image placeholder/render
                      Hero(
                        tag: 'card_${cardData['card_id']}',
                        child: Container(
                          height: 380.h,
                          width: 230.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF021B10),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.4), width: 2.0),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFF5D67D).withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 5),
                              BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 20, offset: const Offset(0, 15))
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
                        style: GoogleFonts.outfit(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        orientation,
                        style: GoogleFonts.outfit(fontSize: 18.sp, color: const Color(0xFFF5D67D), fontStyle: FontStyle.italic),
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
                                color: const Color(0xFFF5D67D).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(30.r),
                                border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                k.toString().toUpperCase(), 
                                style: GoogleFonts.outfit(color: const Color(0xFFF5D67D), fontWeight: FontWeight.w600, fontSize: 12.sp, letterSpacing: 1.0)
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
          Icon(Icons.auto_awesome, color: const Color(0xFFF5D67D), size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFFF5D67D), letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(String content) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: const Color(0xFF021B10).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
