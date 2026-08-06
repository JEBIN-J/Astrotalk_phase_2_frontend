import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/celestial_animations.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String _boyName = 'Aarav Sharma';
  final String _boyDob = '12 Jan 1994';
  final String _boyTob = '07:15 AM';
  final String _boyRashi = 'Vrishabha (Rohini)';

  final String _girlName = 'Ananya Patel';
  final String _girlDob = '24 Jun 1996';
  final String _girlTob = '02:45 PM';
  final String _girlRashi = 'Kanya (Hasta)';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'Kundli Matching (36 Guna)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE11D48),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: const Color(0xFFE11D48),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Ashtakoota Score'),
            Tab(text: 'Manglik Dosh'),
            Tab(text: 'Remedies & Advice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScoreTab(context, isDark),
          _buildManglikTab(context, isDark),
          _buildRemediesTab(context, isDark),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: BouncyTouchCard(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Milan matching report ready! Generated 8-page PDF.', style: GoogleFonts.outfit()),
                  backgroundColor: const Color(0xFFE11D48),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Download Ashtakoota Milan PDF Report',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: ASHTAKOOTA SCORE TAB ---
  Widget _buildScoreTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Boy & Girl Couple Card with Adaptive Responsiveness
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      child: const Icon(Icons.face_rounded, color: Color(0xFF3B82F6), size: 28),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_boyName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                    ),
                    Text('$_boyDob ($_boyTob)\n$_boyRashi', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54), textAlign: TextAlign.center),
                  ],
                ),
              ),
              PulsingAuraWidget(
                glowColor: const Color(0xFFE11D48),
                maxBlur: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE11D48),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.15),
                      child: const Icon(Icons.face_3_rounded, color: Color(0xFFEC4899), size: 28),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_girlName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                    ),
                    Text('$_girlDob ($_girlTob)\n$_girlRashi', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Overall Score Highlight Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ashtakoota Milan Score', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('28.5 / 36', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  Text('Status: Highly Auspicious Match (उत्तम मिलान)', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.95), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('79.2%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ashtakoota 8 Kootas Detailed Breakdown with Animated Progress
        Text('Detailed 8 Kootas Breakdown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildAnimatedKootaRow(0, '1. Varna Koota (Work temperament)', '1.0 / 1.0', 1.0, 'Both possess mutually respectful intellectual alignments', Colors.green, isDark),
        _buildAnimatedKootaRow(1, '2. Vashya Koota (Dominance & control)', '2.0 / 2.0', 1.0, 'Equal authority and healthy mutual respect in marriage', Colors.green, isDark),
        _buildAnimatedKootaRow(2, '3. Tara Koota (Destiny & longevity)', '3.0 / 3.0', 1.0, 'Sampat Tara - brings wealth, joy, and good fortunes', Colors.green, isDark),
        _buildAnimatedKootaRow(3, '4. Yoni Koota (Physical compatibility)', '3.5 / 4.0', 0.87, 'Cow (Gau) and Elephant (Gaja) - Friendly intimacy', Colors.green, isDark),
        _buildAnimatedKootaRow(4, '5. Graha Maitri (Mental harmony)', '4.0 / 5.0', 0.80, 'Venus and Mercury are natural friendly planetary lords', Colors.green, isDark),
        _buildAnimatedKootaRow(5, '6. Gana Koota (Behavioral nature)', '5.0 / 6.0', 0.83, 'Deva Gana and Manushya Gana - Harmonious coexistence', Colors.green, isDark),
        _buildAnimatedKootaRow(6, '7. Bhakoot Koota (Family & finance)', '7.0 / 7.0', 1.0, '9/5 Navapancham angle - Auspicious prosperity and progeny', Colors.green, isDark),
        _buildAnimatedKootaRow(7, '8. Nadi Koota (Genetic health)', '3.0 / 8.0', 0.37, 'Antya vs Madhya Nadi - Minor dosha with cancellation present', Colors.orange, isDark),
      ],
    );
  }

  // --- TAB 2: MANGLIK DOSH TAB ---
  Widget _buildManglikTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildManglikCard(
          _boyName,
          'Non-Manglik (मंगल दोष रहित)',
          'Mars is placed in 10th House (Exalted in Capricorn), producing Digbala and canceling any blemish.',
          Icons.verified_user_rounded,
          Colors.green,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildManglikCard(
          _girlName,
          'Anshik Manglik (आंशिक मंगल)',
          'Mars is situated in 12th House, but Jupiter aspect mitigates the intensity after age 28.',
          Icons.info_outline_rounded,
          Colors.orange,
          isDark,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                  const SizedBox(width: 8),
                  Text('Manglik Compatibility Verdict', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF059669))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Because the Ashtakoota score exceeds 28 points and Mars is favorably placed in the boy\'s 10th house, this alliance is astrologically approved with standard Kumbh Vivah / Puja blessings.',
                style: GoogleFonts.outfit(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 3: REMEDIES TAB ---
  Widget _buildRemediesTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Recommended Astrological Remedies (उपाय)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildRemedyCard('1. Shiva-Parvati Puja', 'Perform Rudrabhishek on Mondays for marital bliss, mutual love and long life.', Icons.temple_hindu_rounded, Colors.purple, isDark),
        _buildRemedyCard('2. Yellow Sapphire or Opal', 'Strengthen benefic Jupiter and Venus for prosperity and peaceful domestic life.', Icons.diamond_rounded, Colors.amber, isDark),
        _buildRemedyCard('3. Mahamrityunjaya Mantra', 'Chant 108 times on Shukla Paksha Saturdays to neutralize minor Nadi dosha.', Icons.record_voice_over_rounded, Colors.teal, isDark),
      ],
    );
  }

  Widget _buildAnimatedKootaRow(int index, String title, String score, double progress, String desc, Color color, bool isDark) {
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
                Expanded(
                  child: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                Text(score, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: val,
                    backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildManglikCard(String name, String status, String desc, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(status, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemedyCard(String title, String desc, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
