import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/astro_item.dart';
import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/astro_cards.dart';
import '../widgets/celestial_animations.dart';
import 'feature_sheets.dart';

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
      backgroundColor: isDark ? const Color(0xFF080D1A) : const Color(0xFFF1F5F9),
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
                clipper: RoundedBottomHeaderClipper(radius: 36.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: headerGradient,
                  ),
                  child: CosmicStarfieldBackground(
                    isDark: isDark,
                    starCount: 36,
                    child: Stack(
                      children: [
                        // Subtle Golden Rotating Mandala Watermark
                        Positioned(
                          right: -40,
                          top: -30,
                          child: RepaintBoundary(
                            child: RotationTransition(
                              turns: _mandalaController,
                              child: Opacity(
                                opacity: isDark ? 0.12 : 0.16,
                                child: const Icon(
                                  Icons.all_inclusive_rounded,
                                  size: 260,
                                  color: Color(0xFFFFD54F),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Ambient celestial glow overlay
                        Positioned(
                          left: -50,
                          bottom: -20,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.08 : 0.15),
                            ),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
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
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
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
                                                    fontSize: 21,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  width: 7,
                                                  height: 7,
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
                                                fontSize: 11.5,
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
                                        const SizedBox(width: 6),
                                        _buildHeaderIconButton(
                                          icon: Icons.dashboard_customize_rounded,
                                          color: Colors.white,
                                          onTap: _openStyleSettingsModal,
                                          tooltip: 'Dashboard Customizer',
                                        ),
                                        const SizedBox(width: 6),
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
                                const SizedBox(height: 14),

                                // Glassmorphic Search Bar
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.22),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                          cursorColor: const Color(0xFFFFD54F),
                                          decoration: InputDecoration(
                                            hintText: 'Search Kundli, Matching, Gochara, Ephemeris...',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.72),
                                              fontSize: 12.5,
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
                                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Live Planetary Transit Ticker (Horizontal Pills)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: (_liveTransits != null && _liveTransits!.isNotEmpty)
                                        ? _liveTransits!.map((t) {
                                            final title = t['title'] ?? '';
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: _buildHeaderPill('✨ $title', const Color(0xFFD97706)),
                                            );
                                          }).toList()
                                        : [
                                            _buildHeaderPill('☀️ Sun in Aquarius', const Color(0xFFD97706)),
                                            const SizedBox(width: 8),
                                            _buildHeaderPill('🌙 Moon in Rohini', const Color(0xFF3B82F6)),
                                            const SizedBox(width: 8),
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: _buildLivePanchangCard(context, dateStr, isDark),
            ),
          ),

          // 3. Featured Daily Insights Carousel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildDailyInsightsCarousel(isDark),
            ),
          ),

          // 4. Category Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCategoryChips(context, isDark),
            ),
          ),

          // 5. Layout Style Status & Quick Look Switcher Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  BouncyTouchCard(
                    onTap: _openStyleSettingsModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 6),
                          Text(
                            _currentStyle.title,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, size: 16),
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
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                child: StaggeredAnimatedItem(
                  index: 0,
                  child: BentoHeroCard(
                    isDark: isDark,
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

          // 7. Responsive Dynamic Grid of Modules (with safe bottom padding)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 64),
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
        padding: const EdgeInsets.all(7.5),
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
                right: 0,
                top: 0,
                child: Container(
                  width: 6.5,
                  height: 6.5,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D36) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF1E3A8A).withValues(alpha: 0.09),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
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
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFD97706)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;
                return Row(
                  children: [
                    _buildPanchangPill('Sunrise', sunrise, Icons.brightness_high_rounded, const Color(0xFF6366F1), isDark, isNarrow),
                    const SizedBox(width: 8),
                    _buildPanchangPill('Sunset', sunset, Icons.brightness_4_rounded, const Color(0xFF0D9488), isDark, isNarrow),
                    const SizedBox(width: 8),
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
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 4),
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
            const SizedBox(height: 4),
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
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = insights[index];
          return BouncyTouchCard(
            child: Container(
              width: 254,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D36) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.color.withValues(alpha: isDark ? 0.4 : 0.2),
                  width: 1.2,
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
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
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AstroCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? const Color(0xFF131D36) : Colors.white),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? const Color(0xFF1E2E56) : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
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
                  const SizedBox(width: 7),
                  Text(
                    cat.title,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
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

  // --- Dynamic Responsive Grid/List of Modules ---
  Widget _buildResponsiveModulesGrid(BuildContext context) {
    final items = _filteredItems;

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No astrology modules found',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Design Styles & Themes',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('1. Visual Dashboard Layout Style', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DashboardStyle.values.map((style) {
                        final isSelected = style == _currentStyle;
                        return ChoiceChip(
                          selected: isSelected,
                          avatar: Icon(style.icon, size: 16, color: isSelected ? Colors.white : null),
                          label: Text(style.title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
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
                    const SizedBox(height: 16),
                    Text('2. Default Kundli Chart Presentation Model', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: KundliChartStyle.values.map((chart) {
                        final isSelected = chart == _defaultChartStyle;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(chart.title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
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
                    const SizedBox(height: 16),
                    Text('3. Celestial Color Theme Palette', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPaletteButton('Cosmic', AppColorPalette.midnightCosmic, const Color(0xFF6366F1), setModalState),
                        const SizedBox(width: 8),
                        _buildPaletteButton('Saffron', AppColorPalette.sacredSaffron, const Color(0xFFFF9900), setModalState),
                        const SizedBox(width: 8),
                        _buildPaletteButton('Royal', AppColorPalette.royalIndigo, const Color(0xFF2563EB), setModalState),
                        const SizedBox(width: 8),
                        _buildPaletteButton('Emerald', AppColorPalette.emeraldDivine, const Color(0xFF059669), setModalState),
                      ],
                    ),
                    const SizedBox(height: 24),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              CircleAvatar(backgroundColor: color, radius: 8),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 11,
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
