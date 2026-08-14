import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../models/astro_item.dart';
import '../theme/app_theme.dart';
import 'celestial_animations.dart';
import 'custom_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 1. Bento Grid Hero Card (Used in Astrotalk Bento style)
class BentoHeroCard extends StatelessWidget {
  final VoidCallback onTapKundli;
  final VoidCallback onTapAiCalling;
  final bool isDark;
  final AppColorPalette currentPalette;

  const BentoHeroCard({
    super.key,
    required this.onTapKundli,
    required this.onTapAiCalling,
    required this.isDark,
    required this.currentPalette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        gradient: AppTheme.getHeaderGradient(currentPalette, isDark),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Stack(
          children: [
            
            // Rotating celestial decorative watermark
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.12,
                child: SmoothRotatingWidget(
                  duration: const Duration(seconds: 45),
                  child: const VedicIcon(
                    iconKey: 'kundli',
                    size: 190,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(22.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBadge(
                        text: '★ FEATURED KUNDLI & AI',
                        baseGradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFF59E0B)],
                        ),
                        textColor: const Color(0xFF451A03),
                        fontSize: 10.sp,
                      ),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Detailed Janam Kundli\n& Life Horoscope',
                    style: GoogleFonts.outfit(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15.h,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'North, South & East Indian Charts, 120-Yr Vimshottari Dasha & Live AI Consultations.',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35.h,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      BouncyTouchCard(
                        onTap: onTapKundli,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF0F172A)),
                              SizedBox(width: 8.w),
                              Text(
                                'View Kundli',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.sp,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      BouncyTouchCard(
                        onTap: onTapAiCalling,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.mic, size: 18, color: Color(0xFFFDA4AF)),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'AI Astrologer',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Classic Elevated Vedic Tile with Spring Touch & Adaptive Scaling
class AstroClassicTile extends StatelessWidget {
  final AstroItem item;
  final VoidCallback onTap;

  const AstroClassicTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BouncyTouchCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D36) : Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2E56)
                : item.primaryColor.withValues(alpha: 0.14),
            width: 1.2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : item.primaryColor.withValues(alpha: 0.09),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final iconBoxSize = (constraints.maxHeight * 0.42).clamp(36.0, 52.0);
                  final iconSize = (iconBoxSize * 0.54).clamp(20.0, 28.0);

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              color: item.primaryColor.withValues(alpha: isDark ? 0.22 : 0.09),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: item.primaryColor.withValues(alpha: isDark ? 0.35 : 0.15),
                                width: 1.w,
                              ),
                            ),
                            child: Center(
                              child: VedicIcon(
                                iconKey: item.iconKey,
                                size: iconSize,
                                color: isDark ? item.secondaryColor : item.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15.h,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (item.badge != null)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: item.isPro
                    ? ShimmerBadge(
                        text: 'PRO',
                        baseGradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                        ),
                        fontSize: 8.5.sp,
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [item.primaryColor, item.secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.badge!,
                          style: GoogleFonts.outfit(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 3. Cosmic Glassmorphic Card (Deep space neon aura)
class AstroGlassmorphicCard extends StatelessWidget {
  final AstroItem item;
  final VoidCallback onTap;

  const AstroGlassmorphicCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTouchCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    item.primaryColor.withValues(alpha: 0.22),
                    const Color(0xFF0F172A).withValues(alpha: 0.85),
                  ]
                : [
                    item.primaryColor.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.95),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: item.secondaryColor.withValues(alpha: isDark ? 0.45 : 0.32),
            width: 1.4.w,
          ),
          boxShadow: [
            BoxShadow(
              color: item.primaryColor.withValues(alpha: isDark ? 0.28 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final iconBoxSize = (constraints.maxHeight * 0.42).clamp(36.0, 52.0);
                  final iconSize = (iconBoxSize * 0.54).clamp(20.0, 26.0);

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [item.primaryColor, item.secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: item.primaryColor.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: VedicIcon(
                                iconKey: item.iconKey,
                                size: iconSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (item.badge != null)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: item.isPro
                    ? ShimmerBadge(
                        text: 'PRO',
                        baseGradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                        ),
                        fontSize: 8.5.sp,
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [item.primaryColor, item.secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.badge!,
                          style: GoogleFonts.outfit(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 4. Sacred Gold & Saffron Temple Card
class AstroTempleCard extends StatelessWidget {
  final AstroItem item;
  final VoidCallback onTap;

  const AstroTempleCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTouchCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF26180B) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.55 : 0.4),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final iconBoxSize = (constraints.maxHeight * 0.42).clamp(36.0, 50.0);
                  final iconSize = (iconBoxSize * 0.54).clamp(20.0, 26.0);

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: VedicIcon(
                                iconKey: item.iconKey,
                                size: iconSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF78350F),
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (item.badge != null)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: item.isPro
                    ? ShimmerBadge(
                        text: 'PRO',
                        baseGradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                        ),
                        fontSize: 8.5.sp,
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.badge!,
                          style: GoogleFonts.outfit(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 5. Detailed Categorized List Tile
class AstroDetailedListTile extends StatelessWidget {
  final AstroItem item;
  final VoidCallback onTap;

  const AstroDetailedListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BouncyTouchCard(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D36) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          leading: Container(
            width: 46.w,
            height: 46.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.primaryColor, item.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: VedicIcon(
                iconKey: item.iconKey,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.title.replaceAll('\n', ' '),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5.sp,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (item.badge != null)
                item.isPro
                    ? ShimmerBadge(
                        text: 'PRO',
                        baseGradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                        ),
                        fontSize: 9.sp,
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: item.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.badge!,
                          style: GoogleFonts.outfit(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.bold,
                            color: item.primaryColor,
                          ),
                        ),
                      ),
            ],
          ),
          subtitle: Text(
            item.subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11.5.sp,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white38 : Colors.black26,
            size: 20,
          ),
        ),
      ),
    );
  }
}
