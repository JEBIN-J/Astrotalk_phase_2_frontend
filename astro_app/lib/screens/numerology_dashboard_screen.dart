import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'numerology_calculator_screen.dart';

class NumerologyDashboardScreen extends StatelessWidget {
  const NumerologyDashboardScreen({super.key});

  Widget _buildExploreCard(BuildContext context, String title, String subtitle, IconData icon, {bool isNew = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C23),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFF2A2A35), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF8B92FF), size: 26.sp),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFA0A0AB), height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isNew) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2B4A),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.outfit(fontSize: 9.sp, color: const Color(0xFF9EA3FF), fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        leadingWidth: 70.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Center(
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2A2A35)),
              ),
              child: Icon(Icons.person_outline, color: const Color(0xFF8B92FF), size: 20.sp),
            ),
          ),
        ),
        title: Text('Good evening', style: GoogleFonts.outfit(fontSize: 15.sp, color: const Color(0xFFE2E2E5), fontWeight: FontWeight.w500)),
        actions: [
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C23),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFF2A2A35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFB347), size: 16),
                  SizedBox(width: 6.w),
                  Text('20', style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Center(
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C23),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF2A2A35)),
              ),
              child: Icon(Icons.menu, color: const Color(0xFFE2E2E5), size: 18.sp),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak Banner
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C23),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFF2A2A35), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text('1', style: GoogleFonts.outfit(fontSize: 60.sp, height: 1, fontWeight: FontWeight.w800, color: const Color(0xFF8B92FF))),
                    ),
                    SizedBox(width: 24.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TODAY FOR YOU', style: GoogleFonts.outfit(fontSize: 10.sp, letterSpacing: 2.5, fontWeight: FontWeight.w600, color: const Color(0xFFA0A0AB))),
                              Icon(Icons.ios_share, color: const Color(0xFFA0A0AB), size: 16.sp),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('A day to begin...', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                              Icon(Icons.chevron_right, color: const Color(0xFFA0A0AB), size: 20.sp),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B2B36),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text('1-DAY STREAK', style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFFC0C0C8))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              
              // Sign in Banner
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF27263E),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign in to secure your coins', style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          SizedBox(height: 6.h),
                          Text('+20 coins bonus when you sign in', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0CB))),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9C9FF),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text('Sign in now', style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E1E36))),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              
              Text('EXPLORE', style: GoogleFonts.outfit(fontSize: 11.sp, letterSpacing: 2.5, fontWeight: FontWeight.w700, color: const Color(0xFFC0C0C8))),
              SizedBox(height: 16.h),
              
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.78, // Taller cards to accommodate text beautifully
                ),
                children: [
                  _buildExploreCard(
                    context, 
                    'Numerology\nCalculator', 
                    'Calculate your\nnumerology report...', 
                    Icons.grid_view_rounded,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NumerologyCalculatorScreen()));
                    }
                  ),
                  _buildExploreCard(context, 'Name\nCorrection', 'Find the spelling that\nsuits your numbers', Icons.edit_note_rounded, isNew: true),
                  _buildExploreCard(context, 'Mobile\nNumber', 'The most advanced\nmobile number anal...', Icons.phone_rounded, isNew: true),
                  _buildExploreCard(context, 'Child\nNumerology', 'Find the best dates\nto give birth and ch...', Icons.child_care_rounded, isNew: true),
                  _buildExploreCard(context, 'Advanced\nCompatibility', 'Check compatibility\nusing DOB, Numero...', Icons.favorite_outline_rounded, isNew: true),
                  _buildExploreCard(context, 'Learn\nNumerology', 'Unlock and read\nexpert guides to ma...', Icons.menu_book_rounded, isNew: true),
                  _buildExploreCard(context, 'Angel\nNumbers', 'Discover the meaning\nof angel numbers a...', Icons.auto_awesome),
                ],
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
