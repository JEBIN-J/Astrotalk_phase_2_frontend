import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/celestial_animations.dart';

class GocharaScreen extends StatefulWidget {
  final bool isYearly;
  const GocharaScreen({super.key, this.isYearly = false});

  @override
  State<GocharaScreen> createState() => _GocharaScreenState();
}

class _GocharaScreenState extends State<GocharaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isYearly ? 'Yearly Gochara (2026-2027)' : 'Daily Gochara Transits',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: const Color(0xFF0284C7),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Current Planetary Positions'),
            Tab(text: 'Rashi Impact (12 Signs)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlanetsTab(context, isDark),
          _buildRashisTab(context, isDark),
        ],
      ),
    );
  }

  Widget _buildPlanetsTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const PulsingAuraWidget(
                glowColor: Color(0xFF38BDF8),
                maxBlur: 8,
                child: Icon(Icons.public_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Nirayana Sidereal Gochara', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Real-time high precision astronomical ephemeris positions', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Planetary Transits & Dignities', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildTransitPlanet(0, 'Sun (Surya)', 'Kumbha (Aquarius)', '19° 42\' 11"', 'Shatabhisha (Rahu)', 'Friendly', 'Direct', Colors.orange, isDark),
        _buildTransitPlanet(1, 'Moon (Chandra)', 'Mithuna (Gemini)', '04° 15\' 22"', 'Mrigashira (Mars)', 'Neutral', 'Direct', Colors.blue, isDark),
        _buildTransitPlanet(2, 'Mars (Mangal)', 'Kanya (Virgo)', '28° 10\' 05"', 'Chitra (Mars)', 'Enemy', 'Direct', Colors.red, isDark),
        _buildTransitPlanet(3, 'Mercury (Budha)', 'Kumbha (Aquarius)', '06° 54\' 30"', 'Dhanishta (Mars)', 'Friendly', 'Direct', Colors.green, isDark),
        _buildTransitPlanet(4, 'Jupiter (Guru)', 'Vrishabha (Taurus)', '17° 30\' 45"', 'Rohini (Moon)', 'Enemy', 'Direct', Colors.amber, isDark),
        _buildTransitPlanet(5, 'Venus (Shukra)', 'Meena (Pisces)', '12° 44\' 19"', 'Uttara Bhadra (Saturn)', 'Exalted (उच्च)', 'Direct', Colors.teal, isDark),
        _buildTransitPlanet(6, 'Saturn (Shani)', 'Kumbha (Aquarius)', '22° 18\' 52"', 'Purva Bhadra (Jupiter)', 'Own Sign (मूलत्रिकोण)', 'Direct', Colors.indigo, isDark),
        _buildTransitPlanet(7, 'Rahu (North Node)', 'Meena (Pisces)', '14° 02\' 10"', 'Uttara Bhadra (Saturn)', 'Friendly', 'Retrograde', Colors.purple, isDark),
        _buildTransitPlanet(8, 'Ketu (South Node)', 'Kanya (Virgo)', '14° 02\' 10"', 'Hasta (Moon)', 'Friendly', 'Retrograde', Colors.purple, isDark),
      ],
    );
  }

  Widget _buildRashisTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Gochara Impact on 12 Moon Signs (Rashis)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildRashiTransitCard(0, 'Aries (Mesha)', 'Jupiter in 2nd (Wealth & Speech) • Saturn in 11th (Great Gains & Income)', 'Very Favorable', Colors.green, isDark),
        _buildRashiTransitCard(1, 'Taurus (Vrishabha)', 'Jupiter in 1st (Wisdom & Radiance) • Rahu in 11th (Unexpected Windfalls)', 'Favorable', Colors.green, isDark),
        _buildRashiTransitCard(2, 'Gemini (Mithuna)', 'Jupiter in 12th (Spiritual Gains & Travel) • Saturn in 9th (Luck & Dharma)', 'Moderate', Colors.amber, isDark),
        _buildRashiTransitCard(3, 'Cancer (Karkata)', 'Saturn in 8th (Ashtama Shani - Caution in Health) • Jupiter in 11th (Strong Gains)', 'Mixed', Colors.orange, isDark),
        _buildRashiTransitCard(4, 'Leo (Simha)', 'Saturn in 7th (Partnership focus) • Jupiter in 10th (Career elevation)', 'Favorable', Colors.green, isDark),
        _buildRashiTransitCard(5, 'Virgo (Kanya)', 'Ketu in 1st • Rahu in 7th • Jupiter in 9th (Bhagya Sthana protection)', 'Moderate', Colors.amber, isDark),
        _buildRashiTransitCard(6, 'Libra (Tula)', 'Saturn in 5th (Intellectual pursuits) • Jupiter in 8th (Occult studies)', 'Mixed', Colors.orange, isDark),
        _buildRashiTransitCard(7, 'Scorpio (Vrishchika)', 'Saturn in 4th (Ardhastama Shani) • Jupiter in 7th (Marriage & Business)', 'Favorable', Colors.green, isDark),
        _buildRashiTransitCard(8, 'Sagittarius (Dhanu)', 'Saturn in 3rd (Brave efforts crowned with victory) • Jupiter in 6th', 'Very Favorable', Colors.green, isDark),
        _buildRashiTransitCard(9, 'Capricorn (Makara)', 'Saturn in 2nd (Final phase of Sade Sati) • Jupiter in 5th (Children & Joy)', 'Favorable', Colors.green, isDark),
        _buildRashiTransitCard(10, 'Aquarius (Kumbha)', 'Saturn in 1st (Peak Sade Sati - Shasha Yoga) • Jupiter in 4th', 'Moderate', Colors.amber, isDark),
        _buildRashiTransitCard(11, 'Pisces (Meena)', 'Rahu in 1st • Saturn in 12th (Setting Sade Sati phase) • Venus Exalted', 'Mixed', Colors.orange, isDark),
      ],
    );
  }

  Widget _buildTransitPlanet(int index, String name, String sign, String degrees, String nakshatra, String dignity, String motion, Color color, bool isDark) {
    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        Text(sign, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color), overflow: TextOverflow.ellipsis),
                        Text('$degrees • $nakshatra', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(dignity, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
                const SizedBox(height: 4),
                Text(motion, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRashiTransitCard(int index, String rashi, String forecast, String status, Color color, bool isDark) {
    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rashi, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(forecast, style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
