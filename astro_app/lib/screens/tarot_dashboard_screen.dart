import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tarot_reading_screen.dart';
import 'tarot_history_screen.dart';
import 'tarot_library_screen.dart';
import 'tarot_deck_selection_screen.dart';

class TarotDashboardScreen extends StatefulWidget {
  const TarotDashboardScreen({super.key});

  @override
  State<TarotDashboardScreen> createState() => _TarotDashboardScreenState();
}

class _TarotDashboardScreenState extends State<TarotDashboardScreen> {
  void _openSpread(String endpoint, String title, {String? question}) {
    int requiredCards = 1;
    if (endpoint == 'three-card') {
      requiredCards = 3;
    } else if (endpoint == 'love' || endpoint == 'career') {
      requiredCards = 5;
    } else if (endpoint == 'celtic-cross') {
      requiredCards = 10;
    } else if (endpoint == 'year-ahead') {
      requiredCards = 12;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TarotDeckSelectionScreen(
        endpoint: endpoint,
        title: title,
        question: question ?? title,
        requiredCards: requiredCards,
      )
    ));
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(top: 32.h, bottom: 16.h, left: 20.w, right: 20.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF022C22), Color(0xFF0A3A2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 20.sp),
          ),
          SizedBox(width: 14.w),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF022C22), // Deep Emerald
                Color(0xFF1B5E20), // Rich Green
                Color(0xFF022C22), // Deep Emerald
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              title, 
              style: GoogleFonts.outfit(
                fontSize: 24.sp, 
                fontWeight: FontWeight.w800, 
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String imageAsset, VoidCallback onTap) {
    bool isNetwork = imageAsset.startsWith('http');
    ImageProvider imgProvider = isNetwork 
        ? NetworkImage(imageAsset) 
        : AssetImage(imageAsset) as ImageProvider;

    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            width: 160.w,
            height: 180.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                width: 1.5,
              ),
              image: DecorationImage(
                image: imgProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.8), width: 1.w),
                    ),
                    child: Icon(Icons.auto_awesome, color: const Color(0xFFFFD700), size: 14.sp),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      title, 
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Widget> cards) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: cards,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Tarot Mystique', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20), fontSize: 24.sp)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF1B5E20)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TarotHistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.library_books, color: Color(0xFF1B5E20)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TarotLibraryScreen())),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF5FBF6), // Very light Green
              const Color(0xFFFFFCED), // Very light Gold
              const Color(0xFFF9FDF9), // Very light Green
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
            Positioned(
              bottom: 400.h,
              left: 20.w,
              child: Icon(Icons.flare, size: 100.sp, color: const Color(0xFFFFD700).withValues(alpha: 0.12)),
            ),
            SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.only(bottom: 40.h, top: 10.h),
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    child: Text(
                      "Seek clarity in the cards",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        color: const Color(0xFFB8860B),
                        letterSpacing: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  
                  _buildSectionHeader('Get Answers', Icons.auto_awesome),
                  _buildHorizontalList([
                    _buildCategoryCard('Is the answer Yes or No?', 'assets/images/tarot/tarot_yes_no.jpg', () => _openSpread('yes-no', 'Is the answer Yes or No?')),
                    _buildCategoryCard('Immediate Question on Your Mind', 'assets/images/tarot/tarot_immediate.jpg', () => _openSpread('single', 'Immediate Question')),
                    _buildCategoryCard('Will Your Wish Be Fulfilled?', 'assets/images/tarot/tarot_wish.jpg', () => _openSpread('celtic-cross', 'Will Your Wish Be Fulfilled?')),
                    _buildCategoryCard('Get Help in Making a Decision', 'assets/images/tarot/tarot_decision.jpg', () => _openSpread('three-card', 'Decision Spread')),
                  ]),

                  _buildSectionHeader('New Readings', Icons.flare),
                  _buildHorizontalList([
                    _buildCategoryCard('Wheel of the Year 2026', 'assets/images/tarot/tarot_wheel.jpg', () => _openSpread('year-ahead', 'Wheel of the Year 2026')),
                    _buildCategoryCard('Is It a Good Time to Start a New Relationship?', 'assets/images/tarot/tarot_relationship.jpg', () => _openSpread('love', 'New Relationship Timing')),
                    _buildCategoryCard('What Is My Education Horoscope 2026?', 'assets/images/tarot/tarot_education.jpg', () => _openSpread('single', 'Education 2026')),
                    _buildCategoryCard('What Should I Do to Achieve My Dream Job?', 'assets/images/tarot/tarot_job.jpg', () => _openSpread('career', 'Dream Job 2026')),
                  ]),

                  _buildSectionHeader('Love & Relationship', Icons.favorite),
                  _buildHorizontalList([
                    _buildCategoryCard('Does Your Relationship Have Potential?', 'assets/images/tarot/tarot_love_potential.jpg', () => _openSpread('love', 'Relationship Potential')),
                    _buildCategoryCard('What Is the Purpose of Your Relationship?', 'assets/images/tarot/tarot_love_purpose.jpg', () => _openSpread('love', 'Relationship Purpose')),
                    _buildCategoryCard('Find Out About Your Love Life', 'assets/images/tarot/tarot_love_life.jpg', () => _openSpread('love', 'Love Life Overview')),
                    _buildCategoryCard('Complete Relationship Analysis', 'assets/images/tarot/tarot_love_analysis.jpg', () => _openSpread('celtic-cross', 'Complete Relationship Analysis')),
                    _buildCategoryCard('Sneak Peek Inside Your Dating Life', 'assets/images/tarot/tarot_love_dating.jpg', () => _openSpread('three-card', 'Dating Life')),
                  ]),
                  
                  _buildSectionHeader('Horoscope', Icons.calendar_month),
                  _buildHorizontalList([
                    _buildCategoryCard('Your Monthly Tarot Reading', 'assets/images/tarot/tarot_horoscope_monthly.jpg', () => _openSpread('celtic-cross', 'Monthly Reading')),
                    _buildCategoryCard('Your Birthday Tarot Reading', 'assets/images/tarot/tarot_horoscope_birthday.jpg', () => _openSpread('year-ahead', 'Birthday Reading')),
                    _buildCategoryCard('Your 2026 Tarot Reading', 'assets/images/tarot/tarot_horoscope_2026.jpg', () => _openSpread('year-ahead', '2026 Reading')),
                  ]),

                  _buildSectionHeader('Dreams & Ambitions', Icons.cloud_outlined),
                  _buildHorizontalList([
                    _buildCategoryCard('What Does Life Have in Store for You?', 'assets/images/tarot/tarot_dreams_life.jpg', () => _openSpread('celtic-cross', 'Life in Store')),
                    _buildCategoryCard('The Past, Present and Future', 'assets/images/tarot/tarot_dreams_past.jpg', () => _openSpread('three-card', 'Past, Present and Future')),
                    _buildCategoryCard('What Is Your Life\'s Purpose?', 'assets/images/tarot/tarot_dreams_purpose.jpg', () => _openSpread('celtic-cross', 'Life Purpose')),
                    _buildCategoryCard('Is Travel on the Cards for You?', 'assets/images/tarot/tarot_dreams_travel.jpg', () => _openSpread('three-card', 'Travel Reading')),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
