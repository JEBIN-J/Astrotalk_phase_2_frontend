import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'tarot_card_details_screen.dart';
import '../services/astro_api_service.dart';

import '../theme/app_theme.dart';
import '../widgets/celestial_animations.dart';

class TarotReadingScreen extends StatefulWidget {
  final Map<String, dynamic> spreadData;
  final AppColorPalette currentPalette;
  final bool isDark;

  const TarotReadingScreen({
    Key? key, 
    required this.spreadData,
    this.currentPalette = AppColorPalette.emeraldDivine,
    this.isDark = false,
  }) : super(key: key);

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  final Set<int> _revealedIndices = {};

  Color get _primaryColor {
    switch (widget.currentPalette) {
      case AppColorPalette.sacredSaffron: return AppTheme.saffronPrimary;
      case AppColorPalette.emeraldDivine: return AppTheme.emeraldPrimary;
      case AppColorPalette.royalIndigo: return AppTheme.royalIndigo;
      case AppColorPalette.midnightCosmic: default: return AppTheme.cosmicNavy;
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

  @override
  Widget build(BuildContext context) {
    final positions = widget.spreadData['positions'] as List<dynamic>;
    
    final spreadType = widget.spreadData['spread_type'].toString().replaceAll('_', '/').toUpperCase();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '$spreadType READING', 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            fontSize: 18.sp,
            letterSpacing: 1.2,
          )
        ),
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
              widget.isDark ? _surfaceColor : const Color(0xFFFFFCED),
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
            SafeArea(
              child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(positions.length, (index) {
              final pos = positions[index];
              final card = pos['card'];
              final isRevealed = _revealedIndices.contains(index);

              return Padding(
                padding: EdgeInsets.only(bottom: index == positions.length - 1 ? 0 : 20.h),
                child: GestureDetector(
                  onTap: () {
                    if (!isRevealed) {
                      setState(() {
                        _revealedIndices.add(index);
                      });
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TarotCardDetailsScreen(
                          cardData: card,
                          positionName: pos['position_name'],
                          currentPalette: widget.currentPalette,
                          isDark: widget.isDark,
                        )
                      ));
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final rotateAnim = Tween(begin: 3.14159, end: 0.0).animate(animation);
                      return AnimatedBuilder(
                        animation: rotateAnim,
                        child: child,
                        builder: (context, child) {
                          final isUnder = (ValueKey(isRevealed) != child!.key);
                          var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                          tilt *= isUnder ? -1.0 : 1.0;
                          final value = isUnder ? min(rotateAnim.value, 3.14159 / 2) : rotateAnim.value;
                          return Transform(
                            transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                      );
                    },
                    child: isRevealed
                        ? _buildRevealedCard(pos, card, key: const ValueKey(true))
                        : _buildFaceDownCard(pos['position_name'], key: const ValueKey(false)),
                  ),
                ),
              );
            }),
          ),
        ),
        ),
      ),
      ],
      ),
      ),
    );
  }

  double min(double a, double b) => a < b ? a : b;

  Widget _buildFaceDownCard(String positionName, {Key? key}) {
    return Container(
      key: key,
      height: 400.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5D67D).withValues(alpha: 0.05), 
            blurRadius: 30, 
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.3), width: 1.5),
        image: DecorationImage(
          image: const AssetImage('assets/images/tarot/tarot_back.jpg'),
          fit: BoxFit.cover,
          colorFilter: widget.currentPalette == AppColorPalette.emeraldDivine 
              ? null
              : ColorFilter.mode(_primaryColor, BlendMode.hue),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              color: Colors.black.withValues(alpha: 0.4), // Darken the background image slightly so text is readable
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 36.h),
              Text(
                positionName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontSize: 22.sp,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5D67D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Tap to Reveal', 
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFF5D67D), 
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedCard(Map<String, dynamic> pos, Map<String, dynamic> card, {Key? key}) {
    final isReversed = card['orientation'] == 'Reversed';
    
    return Container(
      key: key,
      height: 480.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.8), // Dynamic background for the revealed card
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF5D67D).withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          ),
        ]
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _primaryColor, // Darker color behind image
                borderRadius: BorderRadius.vertical(top: Radius.circular(23.r)),
                border: Border(bottom: BorderSide(color: const Color(0xFFF5D67D).withValues(alpha: 0.5))),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    'https://www.transparenttextures.com/patterns/stardust.png',
                    repeat: ImageRepeat.repeat,
                    color: const Color(0xFFF5D67D).withValues(alpha: 0.05),
                    colorBlendMode: BlendMode.modulate,
                  ),
                  if (card['image'] != null || card['name'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(23.r)),
                      child: Image.network(
                          '${AstroApiService.baseUrl.replaceAll('/api/v1', '')}/static/${card['image'] ?? 'assets/tarot/${card['name'].toString().toLowerCase().replaceAll(' ', '_')}.webp'}?v=3',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to local asset if backend is unavailable
                            final localAssetPath = 'assets/images/tarot/cards/${card['name'].toString().toLowerCase().replaceAll(' ', '_')}.jpg';
                            return Image.asset(
                              localAssetPath,
                              width: double.infinity,
                              height: double.infinity,
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
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.style_outlined, size: 72.sp, color: const Color(0xFFF5D67D)),
                                      if (isReversed) ...[
                                        SizedBox(height: 12.h),
                                        Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFFEF4444), size: 28.sp),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                  else
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/tarot/tarot_back.jpg',
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.5),
                          colorBlendMode: BlendMode.darken,
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.style_outlined, size: 72.sp, color: const Color(0xFFF5D67D)),
                              if (isReversed) ...[
                                SizedBox(height: 12.h),
                                Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFFEF4444), size: 28.sp),
                              ]
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pos['position_name'].toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, 
                    fontSize: 11.sp, 
                    color: const Color(0xFFF5D67D),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
                if (card['yes_no_meaning'] != null && widget.spreadData['spread_type'] == 'yes_no') ...[
                  Text(
                    '${card['yes_no_meaning']}'.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.sp,
                      color: '${card['yes_no_meaning']}'.toLowerCase().contains('yes') 
                          ? const Color(0xFF4ADE80) 
                          : ('${card['yes_no_meaning']}'.toLowerCase().contains('no') 
                              ? const Color(0xFFF87171) 
                              : const Color(0xFFFCD34D)),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
                Text(
                  '${card['name']}'.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18.sp, 
                    color: Colors.white,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                Text(
                  _getMeaning(card),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp, 
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B).withValues(alpha: 0.6), 
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFF5D67D).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp, 
                          color: const Color(0xFFF5D67D), 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_rounded, size: 14.sp, color: const Color(0xFFF5D67D)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getMeaning(Map<String, dynamic> card) {
    bool isReversed = card['orientation'] == 'Reversed';
    String meaning = isReversed 
        ? (card['meaning_rev'] ?? card['reversed_meaning'] ?? card['desc'] ?? '') 
        : (card['meaning_up'] ?? card['desc'] ?? card['upright_meaning'] ?? '');
    if (meaning.trim().isEmpty) {
        meaning = card['context_meaning'] ?? card['core_meaning'] ?? 'A mysterious force surrounds this card.';
    }
    return meaning;
  }
}
