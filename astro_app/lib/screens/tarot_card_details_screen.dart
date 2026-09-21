import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(cardData['name'] ?? 'Card Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF1E293B),
              padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
              child: Column(
                children: [
                  Text(
                    positionName,
                    style: GoogleFonts.outfit(fontSize: 18.sp, color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  // Image placeholder/render
                  Hero(
                    tag: 'card_${cardData['card_id']}',
                    child: Container(
                      height: 300.h,
                      width: 200.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(color: Colors.black45, blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5))
                        ]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Transform.rotate(
                          angle: isReversed ? 3.14159 : 0,
                          child: cardData['image'] != null
                              ? Image.network(
                                  '${AstroApiService.baseUrl.replaceAll('/api/v1', '')}/${cardData['image']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.style, size: 100.sp, color: const Color(0xFF4338CA)),
                                )
                              : Icon(Icons.style, size: 100.sp, color: const Color(0xFF4338CA)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '${cardData['name']} ($orientation)',
                    style: GoogleFonts.outfit(fontSize: 26.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: keywords.map((k) => Chip(
                      label: Text(k.toString(), style: GoogleFonts.outfit(color: const Color(0xFF4338CA), fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFF4338CA).withOpacity(0.1),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  SizedBox(height: 24.h),
                  
                  _buildSectionTitle('Contextual Meaning'),
                  _buildContentCard(cardData['context_meaning'] ?? 'No contextual meaning available.'),
                  
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Core Meaning'),
                  _buildContentCard(cardData['core_meaning'] ?? 'No core meaning available.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildContentCard(String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFF4338CA).withOpacity(0.1)),
      ),
      child: Text(
        content,
        style: GoogleFonts.outfit(fontSize: 16.sp, height: 1.5, color: const Color(0xFF475569)),
      ),
    );
  }
}
