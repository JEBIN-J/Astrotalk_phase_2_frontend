import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/astro_item.dart';
import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/astro_cards.dart';
import '../widgets/celestial_animations.dart';
import 'feature_sheets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final AppColorPalette currentPalette;
  final Function(AppColorPalette) onSelectPalette;

  const DashboardScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    required this.currentPalette,
    required this.onSelectPalette,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  AstroCategory _selectedCategory = AstroCategory.all;
  DashboardStyle _currentStyle = DashboardStyle.bentoModern;
  KundliChartStyle _defaultChartStyle = KundliChartStyle.northIndian;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _mandalaController;
  Map<String, dynamic>? _livePanchang;
  List<dynamic>? _liveTransits;

  @override
  void initState() {
    super.initState();
    _mandalaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
    _loadLiveDashboardData();
  }

  Future<void> _loadLiveDashboardData() async {
    final muhurat = await AstroApiService.getMuhurat();
    final notifications = await AstroApiService.getNotifications();
    if (mounted) {
      setState(() {
        _livePanchang = muhurat;
        _liveTransits = notifications;
      });
    }
  }

  @override
  void dispose() {
    _mandalaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AstroItem> get _filteredItems {
    return AstroItem.items.where((item) {
      final matchesCategory = _selectedCategory == AstroCategory.all || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openItem(AstroItem item) {
    AstroFeatureDialogs.openFeature(
      context,
      item,
      defaultChartStyle: _defaultChartStyle,
      onToggleTheme: widget.onToggleTheme,
      isDark: widget.isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM yyyy').format(now);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final headerGradient = AppTheme.getHeaderGradient(widget.currentPalette, isDark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080D1A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium U-Model Curved Celestial Header App Bar
          SliverAppBar(
            expandedHeight: isLandscape ? 180 : 275,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: ClipPath(
                clipper: RoundedBottomHeaderClipper(radius: 36.0.r),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: headerGradient,
                  ),
                  child: CosmicStarfieldBackground(
                    isDark: isDark,
                    starCount: 36,
                    child: Stack(
                      children: [
                        // Cosmic dust particles drifting through the header
                        Positioned.fill(
                          child: CosmicDustBackground(
                            particleCount: 65,
                            primaryColor: Colors.white,
                            accentColor: const Color(0xFFB0C4DE),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top Header Row: Branding & Actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Radiant golden emblem
                                        Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(14.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'AstroTalk',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: 21.sp,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                SizedBox(width: 4.w),
                                                Container(
                                                  width: 7.w,
                                                  height: 7.h,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFFFD54F),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Vedic Astrology & AI Kundli',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white.withValues(alpha: 0.78),
                                                fontSize: 11.5.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Action buttons in sleek pill containers
                                    Row(
                                      children: [
                                        _buildHeaderIconButton(
                                          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                          color: isDark ? const Color(0xFFFFD54F) : Colors.white,
                                          onTap: widget.onToggleTheme,
                                          tooltip: 'Toggle Theme',
                                        ),
                                        SizedBox(width: 6.w),
                                        _buildHeaderIconButton(
                                          icon: Icons.dashboard_customize_rounded,
                                          color: Colors.white,
                                          onTap: _openStyleSettingsModal,
                                          tooltip: 'Dashboard Customizer',
                                        ),
                                        SizedBox(width: 6.w),
                                        _buildHeaderIconButton(
                                          icon: Icons.notifications_active_rounded,
                                          color: Colors.white,
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Abhijit Muhurta is active: ${_livePanchang?['abhijit_muhurta'] ?? '11:58 AM - 12:49 PM'}', style: GoogleFonts.outfit()),
                                                backgroundColor: const Color(0xFF4338CA),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          tooltip: 'Astro Alerts',
                                          hasBadge: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 14.h),

                                // Glassmorphic Search Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                    child: Container(
                                      height: 44.h,
                                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          style: TextStyle(color: Colors.white, fontSize: 13.5.sp),
                                          cursorColor: const Color(0xFFFFD54F),
                                          decoration: InputDecoration(
                                            hintText: 'Search Kundli, Matching, Gochara, Ephemeris...',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.72),
                                              fontSize: 12.5.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              _searchQuery = val;
                                            });
                                          },
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _searchQuery = '';
                                              _searchController.clear();
                                            });
                                          },
                                          child: Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),

                                // Live Planetary Transit Ticker (Horizontal Pills)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: (_liveTransits != null && _liveTransits!.isNotEmpty)
                                        ? _liveTransits!.map((t) {
                                            final title = t['title'] ?? '';
                                            return Padding(
                                              padding: EdgeInsets.only(right: 8.w),
                                              child: _buildHeaderPill('✨ $title', const Color(0xFFD97706)),
                                            );
                                          }).toList()
                                        : [
                                            _buildHeaderPill('☀️ Sun in Aquarius', const Color(0xFFD97706)),
                                            SizedBox(width: 8.w),
                                            _buildHeaderPill('🌙 Moon in Rohini', const Color(0xFF3B82F6)),
                                            SizedBox(width: 8.w),
                                            _buildHeaderPill('✨ Abhijit Active', const Color(0xFF059669)),
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
                ),
              ),
            ),
          ),

          // 2. Live Panchang Card with Generous Top Padding (below the U-shape curve)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: _buildLivePanchangCard(context, dateStr, isDark),
            ),
          ),

          // 3. Featured Daily Insights Carousel
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _buildDailyInsightsCarousel(isDark),
            ),
          ),

          // 4. Category Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _buildCategoryChips(context, isDark),
            ),
          ),

          // 5. Layout Style Status & Quick Look Switcher Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  BouncyTouchCard(
                    onTap: _openStyleSettingsModal,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _currentStyle.icon,
                            size: 14,
                            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            _currentStyle.title,
                            style: GoogleFonts.outfit(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Astrotalk Bento Hero Card (if in Bento Mode)
          if (_currentStyle == DashboardStyle.bentoModern && _searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 2, 16, 14),
                child: StaggeredAnimatedItem(
                  index: 0,
                  child: BentoHeroCard(
                    isDark: isDark,
                    currentPalette: widget.currentPalette,
                    onTapKundli: () => AstroFeatureDialogs.openFeature(
                      context,
                      AstroItem.items.firstWhere((i) => i.id == 'horoscope'),
                      defaultChartStyle: _defaultChartStyle,
                    ),
                    onTapAiCalling: () => AstroFeatureDialogs.openFeature(
                      context,
                      AstroItem.items.firstWhere((i) => i.id == 'ai_calling'),
                      defaultChartStyle: _defaultChartStyle,
                    ),
                  ),
                ),
              ),
            ),

          // 6.5. Daily Horoscope Personalized Banner
          SliverToBoxAdapter(
            child: _buildDailyHoroscopeBanner(context, isDark),
          ),
          


          // 7. Responsive Dynamic Grid of Modules (with safe bottom padding)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 64),
            sliver: _buildResponsiveModulesGrid(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    bool hasBadge = false,
  }) {
    return BouncyTouchCard(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(7.5.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Stack(
          children: [
            Icon(icon, color: color, size: 18),
            if (hasBadge)
              Positioned(
                right: 0.w,
                top: 0.h,
                child: Container(
                  width: 6.5.w,
                  height: 6.5.h,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPill(String text, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BreathingAuraWidget(
            auraColor: accentColor,
            beginScale: 0.8,
            endScale: 1.3,
            duration: const Duration(milliseconds: 1200),
            child: Container(
              width: 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        ),
       ),
      ),
    );
  }

  // --- Live Panchang Summary Banner with Pulsing Aura ---
  Widget _buildLivePanchangCard(BuildContext context, String dateStr, bool isDark) {
    final sunrise = _livePanchang?['sunrise']?.toString() ?? '05:48 AM';
    final sunset = _livePanchang?['sunset']?.toString() ?? '07:08 PM';
    final rahuKaal = _livePanchang?['rahu_kaal']?.toString().split('(').first.trim() ?? '12:28 PM';
    final paksha = 'Shubh Muhurat';

    return BouncyTouchCard(
      onTap: () => _openItem(
        AstroItem.items.firstWhere((i) => i.id == 'muhurat'),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D36) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0),
            width: 1.3.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFF4338CA).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFFD97706)),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      dateStr,
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    PulsingAuraWidget(
                      glowColor: const Color(0xFFD97706),
                      maxBlur: 6,
                      child: ShimmerBadge(
                        text: paksha,
                        baseGradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                        ),
                        textColor: Colors.white,
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFD97706)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;
                return Row(
                  children: [
                    _buildPanchangPill('Sunrise', sunrise, Icons.brightness_high_rounded, const Color(0xFF6366F1), isDark, isNarrow),
                    SizedBox(width: 8.w),
                    _buildPanchangPill('Sunset', sunset, Icons.brightness_4_rounded, const Color(0xFF0D9488), isDark, isNarrow),
                    SizedBox(width: 8.w),
                    _buildPanchangPill('Rahu Kaal', rahuKaal, Icons.warning_amber_rounded, const Color(0xFFE11D48), isDark, isNarrow),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchangPill(String title, String val, IconData icon, Color color, bool isDark, bool isNarrow) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 10, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: isNarrow ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                val,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isNarrow ? 12 : 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Daily Insights Marquee / Carousel ---
  Widget _buildDailyInsightsCarousel(bool isDark) {
    final insights = DailyAstroInsight.sampleInsights;
    return SizedBox(
      height: 84.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: insights.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final item = insights[index];
          return BouncyTouchCard(
            child: Container(
              width: 254.w,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D36) : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: item.color.withValues(alpha: isDark ? 0.4 : 0.2),
                  width: 1.2.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: isDark ? 0.08 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9.w),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item.description,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5.sp,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Category Chips ---
  Widget _buildCategoryChips(BuildContext context, bool isDark) {
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AstroCategory.values.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final cat = AstroCategory.values[index];
          final isSelected = cat == _selectedCategory;

          return BouncyTouchCard(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 20.w : 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? const Color(0xFF131D36) : Colors.white),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : (isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                  width: 1.2.w,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    cat.title,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Daily Horoscope Banner ---
  Widget _buildDailyHoroscopeBanner(BuildContext context, bool isDark) {
    if (_searchQuery.isNotEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 14.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF4338CA).withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.15,
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(45 / 360),
                  child: Icon(Icons.wb_sunny_rounded, size: 100, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: const Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 8.w),
                    Text(
                      'Your Daily Insight',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  "Jupiter's alignment brings a wave of positive energy to your career today. Embrace new opportunities and stay confident.",
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _buildMiniBadge('Lucky Color: Indigo', const Color(0xFF6366F1)),
                    SizedBox(width: 8.w),
                    _buildMiniBadge('Lucky No: 7', const Color(0xFF10B981)),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // --- Live Astrologers Row ---


  // --- Dynamic Responsive Grid/List of Modules ---
  Widget _buildResponsiveModulesGrid(BuildContext context) {
    final items = _filteredItems;

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 12.h),
                Text(
                  'No astrology modules found',
                  style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.crossAxisExtent;

        if (_currentStyle == DashboardStyle.categorizedList) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                return StaggeredAnimatedItem(
                  index: index,
                  child: AstroDetailedListTile(
                    item: item,
                    onTap: () => _openItem(item),
                  ),
                );
              },
              childCount: items.length,
            ),
          );
        }

        // Adaptive Column calculation for all mobile sizes (narrow, standard, large, landscape)
        int crossAxisCount;
        double childAspectRatio;

        if (screenWidth < 340) {
          // Extra small phones (iPhone SE, Galaxy A01, etc.)
          crossAxisCount = 2;
          childAspectRatio = 1.05;
        } else if (screenWidth < 600) {
          // Standard modern smartphones (iPhone 14/15/16, Pixel, Galaxy S)
          crossAxisCount = 3;
          childAspectRatio = 0.94;
        } else if (screenWidth < 900) {
          // Large foldables unfolded or landscape mobile
          crossAxisCount = 4;
          childAspectRatio = 0.98;
        } else {
          // Tablets and large screens
          crossAxisCount = 6;
          childAspectRatio = 1.0;
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              Widget cardWidget;
              switch (_currentStyle) {
                case DashboardStyle.glassmorphicGrid:
                  cardWidget = AstroGlassmorphicCard(
                    item: item,
                    onTap: () => _openItem(item),
                  );
                  break;
                case DashboardStyle.sacredGoldMandala:
                  cardWidget = AstroTempleCard(
                    item: item,
                    onTap: () => _openItem(item),
                  );
                  break;
                case DashboardStyle.bentoModern:
                case DashboardStyle.classicVedicTiles:
                default:
                  cardWidget = AstroClassicTile(
                    item: item,
                    onTap: () => _openItem(item),
                  );
                  break;
              }
              return StaggeredAnimatedItem(
                index: index,
                child: cardWidget,
              );
            },
            childCount: items.length,
          ),
        );
      },
    );
  }

  // --- Style & Model Customizer Modal ---
  void _openStyleSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = widget.isDark;
            return Container(
              padding: EdgeInsets.all(22.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Design Styles & Themes',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text('1. Visual Dashboard Layout Style', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DashboardStyle.values.map((style) {
                        final isSelected = style == _currentStyle;
                        return ChoiceChip(
                          selected: isSelected,
                          avatar: Icon(style.icon, size: 16, color: isSelected ? Colors.white : null),
                          label: Text(style.title, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          selectedColor: const Color(0xFF4338CA),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _currentStyle = style);
                              setModalState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    Text('2. Default Kundli Chart Presentation Model', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8,
                      children: KundliChartStyle.values.map((chart) {
                        final isSelected = chart == _defaultChartStyle;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(chart.title, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          selectedColor: const Color(0xFF0D9488),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _defaultChartStyle = chart);
                              setModalState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    Text('3. Celestial Color Theme Palette', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildPaletteButton('Cosmic', AppColorPalette.midnightCosmic, const Color(0xFF6366F1), setModalState),
                        SizedBox(width: 8.w),
                        _buildPaletteButton('Saffron', AppColorPalette.sacredSaffron, const Color(0xFFFF9900), setModalState),
                        SizedBox(width: 8.w),
                        _buildPaletteButton('Royal', AppColorPalette.royalIndigo, const Color(0xFF2563EB), setModalState),
                        SizedBox(width: 8.w),
                        _buildPaletteButton('Emerald', AppColorPalette.emeraldDivine, const Color(0xFF059669), setModalState),
                      ],
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaletteButton(String name, AppColorPalette palette, Color color, StateSetter setModalState) {
    final isSelected = widget.currentPalette == palette;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onSelectPalette(palette);
          setModalState(() {});
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2.w),
          ),
          child: Column(
            children: [
              CircleAvatar(backgroundColor: color, radius: 8.r),
              SizedBox(height: 4.h),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Clipper with smooth curved rounded bottom corners and straight flat middle line (_)
class RoundedBottomHeaderClipper extends CustomClipper<Path> {
  final double radius;
  const RoundedBottomHeaderClipper({this.radius = 36.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    // Top-left to bottom-left before corner
    path.lineTo(0, size.height - radius);
    // Smooth rounded bottom-left corner
    path.quadraticBezierTo(0, size.height, radius, size.height);
    // Straight flat horizontal bottom line (_) in the middle
    path.lineTo(size.width - radius, size.height);
    // Smooth rounded bottom-right corner
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - radius);
    // Up to top-right corner
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
