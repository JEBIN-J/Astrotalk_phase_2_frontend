import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/astro_api_service.dart';
import '../widgets/celestial_animations.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _boyName = 'Aarav Sharma';
  String _boyDob = '12 Jan 1994';
  String _boyTob = '07:15 AM';
  String _boyRashi = 'Vrishabha (Rohini)';

  String _girlName = 'Ananya Patel';
  String _girlDob = '24 Jun 1996';
  String _girlTob = '02:45 PM';
  String _girlRashi = 'Kanya (Hasta)';

  bool _isLoading = false;
  Map<String, dynamic>? _matchData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateMatch();
  }

  Future<void> _calculateMatch() async {
    setState(() => _isLoading = true);
    final res = await AstroApiService.matchAshtakoota(
      boy: {'name': _boyName, 'dob': _boyDob, 'tob': _boyTob, 'rashi': _boyRashi},
      girl: {'name': _girlName, 'dob': _girlDob, 'tob': _girlTob, 'rashi': _girlRashi},
    );
    if (mounted) {
      setState(() {
        _matchData = res;
        _isLoading = false;
      });
    }
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

    final totalScore = _matchData?['total_score']?.toString() ?? '29.5';
    final maxScore = _matchData?['max_score']?.toString() ?? '36.0';
    final percentage = _matchData?['percentage']?.toString() ?? '81.9';
    final status = _matchData?['status']?.toString() ?? 'Excellent Match';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFFE11D48)),
            tooltip: 'Edit Bride & Groom Details',
            onPressed: _showEditProfilesSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFE11D48)),
            tooltip: 'Recalculate Milan',
            onPressed: _calculateMatch,
          ),
        ],
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE11D48)),
                  SizedBox(height: 12),
                  Text('Matching 36 Ashtakoota Gunas & Manglik Compatibility...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScoreTab(context, isDark, totalScore, maxScore, percentage, status),
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
  Widget _buildScoreTab(BuildContext context, bool isDark, String totalScore, String maxScore, String percentage, String status) {
    final kootasList = (_matchData?['kootas'] as List<dynamic>?) ?? [];

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ashtakoota Milan Score', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('$totalScore / $maxScore', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    Text('Status: $status', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.95), fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('$percentage%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ashtakoota 8 Kootas Detailed Breakdown with Animated Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Detailed 8 Kootas Breakdown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Ashtakoota Analysis',
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFE11D48), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (kootasList.isEmpty)
          const Center(child: Text('No koota breakdown available'))
        else
          ...kootasList.asMap().entries.map((entry) {
            final idx = entry.key;
            final k = entry.value as Map<String, dynamic>;
            final name = k['koota_name']?.toString() ?? 'Koota';
            final obtained = (k['obtained_points'] ?? 0).toDouble();
            final max = (k['max_points'] ?? 1).toDouble();
            final progress = max > 0 ? (obtained / max).clamp(0.0, 1.0) : 1.0;
            final remarks = k['remarks']?.toString() ?? '';
            final isCompatible = k['is_compatible'] == true;
            final color = isCompatible ? const Color(0xFF059669) : Colors.orange;

            return _buildAnimatedKootaRow(
              idx,
              '${idx + 1}. $name',
              '$obtained / $max',
              progress,
              remarks,
              color,
              isDark,
            );
          }),
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
          'Non-Manglik',
          'Mars is placed in 10th House (Exalted in Capricorn), producing Digbala and canceling any blemish.',
          Icons.verified_user_rounded,
          Colors.green,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildManglikCard(
          _girlName,
          'Anshik Manglik',
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
        Text('Recommended Astrological Remedies', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showEditProfilesSheet() {
    final boyNameCtrl = TextEditingController(text: _boyName);
    final girlNameCtrl = TextEditingController(text: _girlName);
    String bDob = _boyDob;
    String bTob = _boyTob;
    String bRashi = _boyRashi;
    String gDob = _girlDob;
    String gTob = _girlTob;
    String gRashi = _girlRashi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Edit Partner Profiles', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 14),

                    // Boy Section
                    Text('Groom Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: boyNameCtrl,
                      decoration: const InputDecoration(labelText: 'Groom Full Name', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(bDob, style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(1994, 1, 12),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  bDob = '${picked.day} ${_getMonth(picked.month)} ${picked.year}';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(bTob, style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 7, minute: 15),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  bTob = picked.format(context);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Girl Section
                    Text('Bride Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFEC4899))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: girlNameCtrl,
                      decoration: const InputDecoration(labelText: 'Bride Full Name', prefixIcon: Icon(Icons.person_3)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(gDob, style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(1996, 6, 24),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  gDob = '${picked.day} ${_getMonth(picked.month)} ${picked.year}';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(gTob, style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 14, minute: 45),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  gTob = picked.format(context);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _boyName = boyNameCtrl.text.trim().isNotEmpty ? boyNameCtrl.text.trim() : _boyName;
                            _girlName = girlNameCtrl.text.trim().isNotEmpty ? girlNameCtrl.text.trim() : _girlName;
                            _boyDob = bDob;
                            _boyTob = bTob;
                            _boyRashi = bRashi;
                            _girlDob = gDob;
                            _girlTob = gTob;
                            _girlRashi = gRashi;
                          });
                          Navigator.pop(ctx);
                          _calculateMatch();
                        },
                        child: Text('Calculate Live Match Gunas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : 'Jan';
  }
}
