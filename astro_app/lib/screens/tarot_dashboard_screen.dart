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
import 'tarot_learn_module_screen.dart';

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

  Widget _buildReadingsTab() {
    return Stack(
      children: [
        // 1. Same dark starry header background as the Home tab
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 250.h,
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
        
        // 2. Same scrolling white/surface container as the Home tab
        SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: 120.h, top: 80.h),
            physics: const BouncingScrollPhysics(),
            children: [
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
                  padding: EdgeInsets.only(top: 30.h, bottom: 20.h, left: 16.w, right: 16.w),
                  child: Column(
                    children: [
                      Text(
                        "Deep Mystical Readings",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? _accentLight : _primaryColor,
                          shadows: [
                            Shadow(color: (widget.isDark ? _accentLight : _primaryColor).withValues(alpha: 0.2), blurRadius: 4),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "Select a spread for your real-time guidance",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          color: widget.isDark ? Colors.white70 : _accentColor,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      _buildReadingOptionTile(
                        title: "Yes or No Reading",
                        subtitle: "Quick, immediate answers to burning questions",
                        icon: Icons.check_circle_outline,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openSpread('yes-no', 'Yes or No Reading'),
                      ),
                      _buildReadingOptionTile(
                        title: "Daily Tarot",
                        subtitle: "Your energy and guidance for the day",
                        icon: Icons.wb_sunny_outlined,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openSpread('single', 'Daily Tarot'),
                      ),
                      _buildReadingOptionTile(
                        title: "Past, Present, Future",
                        subtitle: "Understand the flow of your life's journey",
                        icon: Icons.timeline,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openSpread('three-card', 'Past, Present, Future'),
                      ),
                      _buildReadingOptionTile(
                        title: "Love & Relationships",
                        subtitle: "Deep dive into romantic connections",
                        icon: Icons.favorite_border,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openSpread('love', 'Love Reading'),
                      ),
                      _buildReadingOptionTile(
                        title: "Career & Finances",
                        subtitle: "Pathways to success and abundance",
                        icon: Icons.work_outline,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openSpread('career', 'Career Reading'),
                      ),
                      _buildReadingOptionTile(
                        title: "Celtic Cross",
                        subtitle: "The ultimate 10-card deep dive analysis",
                        icon: Icons.grid_view,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openSpread('celtic-cross', 'Celtic Cross'),
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

  Widget _buildReadingOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: accentColor.withValues(alpha: widget.isDark ? 0.3 : 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: widget.isDark ? 0.05 : 0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          splashColor: accentColor.withValues(alpha: 0.2),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: widget.isDark ? 0.1 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          color: widget.isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accentColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearnTab() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 250.h,
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
            padding: EdgeInsets.only(bottom: 120.h, top: 80.h),
            physics: const BouncingScrollPhysics(),
            children: [
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
                  padding: EdgeInsets.only(top: 30.h, bottom: 20.h, left: 16.w, right: 16.w),
                  child: Column(
                    children: [
                      Text(
                        "Tarot Wisdom",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? _accentLight : _primaryColor,
                          shadows: [
                            Shadow(color: (widget.isDark ? _accentLight : _primaryColor).withValues(alpha: 0.2), blurRadius: 4),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "Master the art and secrets of the cards",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          color: widget.isDark ? Colors.white70 : _accentColor,
                        ),
                      ),
                      SizedBox(height: 30.h),
                      _buildLearnOptionTile(
                        title: "Tarot Basics",
                        subtitle: "Start your journey and learn the fundamentals",
                        icon: Icons.menu_book,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openLearnModule("Tarot Basics", "Start your journey and learn the fundamentals", [
                          {"title": "What is Tarot?", "body": "Tarot is a deck of 78 cards used for divination, self-reflection, and spiritual guidance. It is not about predicting a fixed future, but rather understanding the energies present in your life and how you can navigate them."},
                          {"title": "The Deck Structure", "body": "A standard Tarot deck consists of two main parts:\n- The Major Arcana (22 cards) representing significant life lessons and karmic influences.\n- The Minor Arcana (56 cards) reflecting the trials, tribulations, and everyday experiences."},
                          {"title": "How to Read", "body": "Begin by relaxing and focusing your mind on a question. Shuffle the cards while holding your intention, draw the cards, and use your intuition combined with the traditional meanings to interpret the story they tell."}
                        ]),
                      ),
                      _buildLearnOptionTile(
                        title: "The Major Arcana",
                        subtitle: "The 22 cards of life's karmic and spiritual lessons",
                        icon: Icons.star_border,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openLearnModule("The Major Arcana", "The 22 cards of life's karmic and spiritual lessons", [
                          {"title": "The Fool's Journey", "body": "The Major Arcana follows 'The Fool' (Card 0) through a journey of spiritual awakening, starting from innocent beginnings and culminating with 'The World' (Card 21), representing completion and cosmic harmony."},
                          {"title": "Key Archetypes", "body": "Cards like The Magician, The High Priestess, The Emperor, and The Lovers represent powerful universal archetypes. When these cards appear in a reading, they point to significant, life-altering themes rather than passing daily concerns."},
                        ]),
                      ),
                      _buildLearnOptionTile(
                        title: "The Minor Arcana",
                        subtitle: "The 56 cards reflecting the trials of daily life",
                        icon: Icons.style_outlined,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openLearnModule("The Minor Arcana", "The 56 cards reflecting the trials of daily life", [
                          {"title": "The Four Suits", "body": "The Minor Arcana is divided into four suits, each corresponding to an element and an aspect of life:\n- Cups (Water): Emotions, relationships, and intuition.\n- Wands (Fire): Passion, energy, and action.\n- Swords (Air): Intellect, thoughts, and conflict.\n- Pentacles (Earth): Material wealth, career, and physical health."},
                          {"title": "Numerology in the Minors", "body": "Each suit contains cards numbered Ace through 10, plus four Court Cards (Page, Knight, Queen, King). The numbers have intrinsic meanings (e.g., Aces represent new beginnings, Tens represent culmination)."}
                        ]),
                      ),
                      _buildLearnOptionTile(
                        title: "Reading Spreads",
                        subtitle: "How to lay out cards and interpret their connections",
                        icon: Icons.auto_awesome_mosaic_outlined,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openLearnModule("Reading Spreads", "How to lay out cards and interpret their connections", [
                          {"title": "One-Card Pull", "body": "The simplest spread. Great for a daily focus, a quick 'yes or no' answer, or sudden inspiration."},
                          {"title": "Three-Card Spread", "body": "A versatile spread typically representing Past, Present, and Future, or Mind, Body, and Spirit."},
                          {"title": "The Celtic Cross", "body": "A comprehensive 10-card spread that provides deep insight into a specific situation, covering underlying influences, past events, future outcomes, and the querent's environment."}
                        ]),
                      ),
                      _buildLearnOptionTile(
                        title: "Astrology & Tarot",
                        subtitle: "Discover the cosmic links between planets and cards",
                        icon: Icons.public,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openLearnModule("Astrology & Tarot", "Discover the cosmic links between planets and cards", [
                          {"title": "Zodiac Correspondences", "body": "Many Tarot cards are intrinsically linked to astrological signs. For example, The Emperor is tied to Aries, The Lovers to Gemini, and Death to Scorpio."},
                          {"title": "Planetary Influences", "body": "The planets also rule the cards. The Sun, Moon, and Star cards are obvious planetary links, but others exist as well, such as The Tower being ruled by Mars, bringing sudden, forceful change."}
                        ]),
                      ),
                      _buildLearnOptionTile(
                        title: "Intuition Mastery",
                        subtitle: "Trust your inner voice during a reading",
                        icon: Icons.visibility_outlined,
                        accentColor: widget.isDark ? _accentColor : _primaryColor,
                        onTap: () => _openLearnModule("Intuition Mastery", "Trust your inner voice during a reading", [
                          {"title": "Look Beyond the Book", "body": "While traditional meanings are a great foundation, your personal reaction to the imagery on the card is equally valid. Notice what symbols catch your eye first."},
                          {"title": "Connecting the Cards", "body": "True mastery comes from seeing the story between the cards. Do the figures face each other? Do the elements clash or harmonize? Let your intuition weave the narrative."}
                        ]),
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

  Widget _buildLearnOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: accentColor.withValues(alpha: widget.isDark ? 0.3 : 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: widget.isDark ? 0.05 : 0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          splashColor: accentColor.withValues(alpha: 0.2),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: widget.isDark ? 0.1 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          color: widget.isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accentColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLearnModule(String title, String subtitle, List<Map<String, String>> sections) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TarotLearnModuleScreen(
          title: title,
          subtitle: subtitle,
          sections: sections,
          currentPalette: widget.currentPalette,
          primaryColor: _primaryColor,
          isDark: widget.isDark,
          accentColor: widget.isDark ? _accentColor : _primaryColor,
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
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          _buildReadingsTab(),
          _buildLearnTab(),
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
