import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tarot_reading_screen.dart';
import 'tarot_history_screen.dart';
import 'tarot_library_screen.dart';
import 'tarot_deck_selection_screen.dart';

import '../theme/app_theme.dart';
import '../widgets/celestial_animations.dart';

import 'tarot_chatbot_screen.dart';

class TarotDashboardScreen extends StatefulWidget {
  final AppColorPalette currentPalette;
  final bool isDark;

  const TarotDashboardScreen({
    super.key,
    this.currentPalette = AppColorPalette.midnightCosmic,
    this.isDark = false,
  });

  @override
  State<TarotDashboardScreen> createState() => _TarotDashboardScreenState();
}

class _TarotDashboardScreenState extends State<TarotDashboardScreen> {
  int _currentIndex = 0;

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
        currentPalette: widget.currentPalette,
        isDark: widget.isDark,
      )
    ));
  }

  Color get _primaryColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return AppTheme.saffronPrimary;
      case AppColorPalette.emeraldDivine: return AppTheme.emeraldPrimary;
      case AppColorPalette.royalIndigo: return AppTheme.royalIndigo;
      case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicNavy;
    }
  }

  Color get _secondaryColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return AppTheme.saffronBorder;
      case AppColorPalette.emeraldDivine: return AppTheme.emeraldBorder;
      case AppColorPalette.royalIndigo: return AppTheme.royalBorder;
      case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicBorder;
    }
  }

  Color get _surfaceColor {
    if (widget.isDark) {
      switch (widget.currentPalette) {
        case AppColorPalette.sacredSaffron: return AppTheme.saffronCard;
        case AppColorPalette.emeraldDivine: return AppTheme.emeraldCard;
        case AppColorPalette.royalIndigo: return AppTheme.royalCard;
        case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicSurface;
      }
    } else {
      switch (widget.currentPalette) {
        case AppColorPalette.sacredSaffron: return const Color(0xFFFFF7F0);
        case AppColorPalette.emeraldDivine: return const Color(0xFFF5FBF6);
        case AppColorPalette.royalIndigo: return const Color(0xFFF3F5FC);
        case AppColorPalette.midnightCosmic: default: return const Color(0xFFF4F7FB);
      }
    }
  }

  Color get _accentColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return const Color(0xFFFFB300); 
      case AppColorPalette.emeraldDivine: return const Color(0xFFD4AF37); 
      case AppColorPalette.royalIndigo: return const Color(0xFFE5C07B); 
      case AppColorPalette.midnightCosmic: default: return const Color(0xFFF5D67D); 
    }
  }

  Color get _accentLight {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return const Color(0xFFFFE0B2); 
      case AppColorPalette.emeraldDivine: return const Color(0xFFF9E596); 
      case AppColorPalette.royalIndigo: return const Color(0xFFF5E6C3); 
      case AppColorPalette.midnightCosmic: default: return const Color(0xFFFFF1BD); 
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 16.h, left: 20.w, right: 20.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: _accentColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                _primaryColor, 
                _secondaryColor, 
                _primaryColor, 
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
                    color: _accentColor.withValues(alpha: 0.3),
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
            width: 140.w, // Reduced width so the next card peeks in from the right edge
            height: 160.h, // Adjusted height to maintain aspect ratio
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
              image: DecorationImage(
                image: imgProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  _accentColor.withValues(alpha: 0.3), 
                  BlendMode.hue
                ),
              ),
              boxShadow: [
                BoxShadow(color: _accentColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
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
                      border: Border.all(color: _accentColor.withValues(alpha: 0.8), width: 1.w),
                    ),
                    child: Icon(Icons.auto_awesome, color: _accentColor, size: 14.sp),
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



  Widget _buildDashboardTab() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.getHeaderGradient(widget.currentPalette, widget.isDark),
            ),
            child: CosmicStarfieldBackground(
              isDark: widget.isDark,
              starCount: 36,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CosmicDustBackground(
                      particleCount: 60,
                      primaryColor: _accentColor,
                      accentColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: 120.h, top: 15.h), // Increased bottom padding to clear the floating bottom navigation bar
            physics: const BouncingScrollPhysics(),
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _accentColor.withValues(alpha: 0.25),
                        _accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: _accentColor, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "Seek clarity in the cards",
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          color: _accentLight,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.auto_awesome, color: _accentColor, size: 16.sp),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                  child: Column(
                    children: [
                      _buildSectionHeader('Get Answers', Icons.auto_awesome),
                      _HorizontalSection(
                        primaryColor: _primaryColor,
                        accentColor: _accentColor,
                        cards: [
                          _buildCategoryCard('Is the answer Yes or No?', 'assets/images/tarot/tarot_yes_no.jpg', () => _openSpread('yes-no', 'Is the answer Yes or No?')),
                          _buildCategoryCard('Immediate Question on Your Mind', 'assets/images/tarot/tarot_immediate.jpg', () => _openSpread('single', 'Immediate Question')),
                          _buildCategoryCard('Will Your Wish Be Fulfilled?', 'assets/images/tarot/tarot_wish.jpg', () => _openSpread('celtic-cross', 'Will Your Wish Be Fulfilled?')),
                          _buildCategoryCard('Get Help in Making a Decision', 'assets/images/tarot/tarot_decision.jpg', () => _openSpread('three-card', 'Decision Spread')),
                        ],
                      ),
                      _buildSectionHeader('New Readings', Icons.flare),
                      _HorizontalSection(
                        primaryColor: _primaryColor,
                        accentColor: _accentColor,
                        cards: [
                          _buildCategoryCard('Wheel of the Year 2026', 'assets/images/tarot/tarot_wheel.jpg', () => _openSpread('year-ahead', 'Wheel of the Year 2026')),
                          _buildCategoryCard('Is It a Good Time to Start a New Relationship?', 'assets/images/tarot/tarot_relationship.jpg', () => _openSpread('love', 'New Relationship Timing')),
                          _buildCategoryCard('What Is My Education Horoscope 2026?', 'assets/images/tarot/tarot_education.jpg', () => _openSpread('single', 'Education 2026')),
                          _buildCategoryCard('What Should I Do to Achieve My Dream Job?', 'assets/images/tarot/tarot_job.jpg', () => _openSpread('career', 'Dream Job 2026')),
                        ],
                      ),
                      _buildSectionHeader('Love & Relationship', Icons.favorite),
                      _HorizontalSection(
                        primaryColor: _primaryColor,
                        accentColor: _accentColor,
                        cards: [
                          _buildCategoryCard('Does Your Relationship Have Potential?', 'assets/images/tarot/tarot_love_potential.jpg', () => _openSpread('love', 'Relationship Potential')),
                          _buildCategoryCard('What Is the Purpose of Your Relationship?', 'assets/images/tarot/tarot_love_purpose.jpg', () => _openSpread('love', 'Relationship Purpose')),
                          _buildCategoryCard('Find Out About Your Love Life', 'assets/images/tarot/tarot_love_life.jpg', () => _openSpread('love', 'Love Life Overview')),
                          _buildCategoryCard('Complete Relationship Analysis', 'assets/images/tarot/tarot_love_analysis.jpg', () => _openSpread('celtic-cross', 'Complete Relationship Analysis')),
                          _buildCategoryCard('Sneak Peek Inside Your Dating Life', 'assets/images/tarot/tarot_love_dating.jpg', () => _openSpread('three-card', 'Dating Life')),
                        ],
                      ),
                      _buildSectionHeader('Horoscope', Icons.calendar_month),
                      _HorizontalSection(
                        primaryColor: _primaryColor,
                        accentColor: _accentColor,
                        cards: [
                          _buildCategoryCard('Your Monthly Tarot Reading', 'assets/images/tarot/tarot_horoscope_monthly.jpg', () => _openSpread('celtic-cross', 'Monthly Reading')),
                          _buildCategoryCard('Your Birthday Tarot Reading', 'assets/images/tarot/tarot_horoscope_birthday.jpg', () => _openSpread('year-ahead', 'Birthday Reading')),
                          _buildCategoryCard('Your 2026 Tarot Reading', 'assets/images/tarot/tarot_horoscope_2026.jpg', () => _openSpread('year-ahead', '2026 Reading')),
                        ],
                      ),
                      _buildSectionHeader('Dreams & Ambitions', Icons.cloud_outlined),
                      _HorizontalSection(
                        primaryColor: _primaryColor,
                        accentColor: _accentColor,
                        cards: [
                          _buildCategoryCard('What Does Life Have in Store for You?', 'assets/images/tarot/tarot_dreams_life.jpg', () => _openSpread('celtic-cross', 'Life in Store')),
                          _buildCategoryCard('The Past, Present and Future', 'assets/images/tarot/tarot_dreams_past.jpg', () => _openSpread('three-card', 'Past, Present and Future')),
                          _buildCategoryCard('What Is Your Life\'s Purpose?', 'assets/images/tarot/tarot_dreams_purpose.jpg', () => _openSpread('celtic-cross', 'Life Purpose')),
                          _buildCategoryCard('Is Travel on the Cards for You?', 'assets/images/tarot/tarot_dreams_travel.jpg', () => _openSpread('three-card', 'Travel Reading')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              _accentColor, 
              _accentLight, 
              _accentColor, 
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            _currentIndex == 3 ? 'Ask Tarot' : 'Tarot Mystique', 
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 26.sp,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: _accentColor.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: _accentColor),
        actions: _currentIndex == 3 ? [] : [
          IconButton(
            icon: Icon(Icons.history, color: _accentColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TarotHistoryScreen())),
          ),
          IconButton(
            icon: Icon(Icons.library_books, color: _accentColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TarotLibraryScreen())),
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          Center(child: Text("Readings - Coming Soon", style: GoogleFonts.outfit(color: _accentColor))),
          Center(child: Text("Learn - Coming Soon", style: GoogleFonts.outfit(color: _accentColor))),
          TarotChatbotScreen(currentPalette: widget.currentPalette, isDark: widget.isDark),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getHeaderGradient(widget.currentPalette, widget.isDark),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.25),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: _accentColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
          child: CosmicStarfieldBackground(
            isDark: widget.isDark,
            starCount: 20,
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: _accentColor,
                unselectedItemColor: Colors.white60,
                selectedLabelStyle: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w500),
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 6.h), child: const Icon(Icons.star_border, size: 24)),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 6.h), 
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.star, size: 30, color: _accentColor.withValues(alpha: 0.5)),
                          const Icon(Icons.star, size: 24),
                        ],
                      )
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 6.h), child: const Icon(Icons.public, size: 24)),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 6.h), 
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.public, size: 30, color: _accentColor.withValues(alpha: 0.5)),
                          const Icon(Icons.public, size: 24),
                        ],
                      )
                    ),
                    label: 'Readings',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 6.h), child: const Icon(Icons.style_outlined, size: 24)),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 6.h), 
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.style, size: 30, color: _accentColor.withValues(alpha: 0.5)),
                          const Icon(Icons.style, size: 24),
                        ],
                      )
                    ),
                    label: 'Learn',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 6.h), child: const Icon(Icons.smart_toy_outlined, size: 24)),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 6.h), 
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.smart_toy, size: 30, color: _accentColor.withValues(alpha: 0.5)),
                          const Icon(Icons.smart_toy, size: 24),
                        ],
                      )
                    ),
                    label: 'Chatbot',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalSection extends StatefulWidget {
  final List<Widget> cards;
  final Color primaryColor;
  final Color accentColor;

  const _HorizontalSection({
    required this.cards,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<_HorizontalSection> createState() => _HorizontalSectionState();
}

class _HorizontalSectionState extends State<_HorizontalSection> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    final atEnd = currentScroll >= maxScroll - 20;
    if (atEnd != _isAtEnd) {
      setState(() {
        _isAtEnd = atEnd;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleViewAllTap() {
    if (!_scrollController.hasClients) return;
    
    if (_isAtEnd) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: widget.cards,
          ),
        ),
        Positioned(
          right: 12.w,
          child: InkWell(
            onTap: _handleViewAllTap,
            borderRadius: BorderRadius.circular(30.r),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.accentColor, width: 1.5.w),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isAtEnd ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                    color: widget.accentColor,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
