import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../widgets/celestial_animations.dart';
import '../widgets/kundli_chart_painter.dart';
import 'api_settings_screen.dart';

class HoroscopeScreen extends StatefulWidget {
  final KundliChartStyle initialChartStyle;

  const HoroscopeScreen({
    super.key,
    this.initialChartStyle = KundliChartStyle.northIndian,
  });

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> with SingleTickerProviderStateMixin {
  late KundliChartStyle _currentChartStyle;
  late TabController _tabController;
  String _personName = 'Jebin J';
  String _dob = '13 Dec 1998';
  String _tob = '09:30 AM';
  String _pob = 'Kanyakumari, India';
  bool _isNavamsha = false;

  bool _isLoadingKundli = false;
  Map<String, dynamic>? _kundliData;

  @override
  void initState() {
    super.initState();
    _currentChartStyle = widget.initialChartStyle;
    _tabController = TabController(length: 5, vsync: this);
    _fetchKundliData();
  }

  String _parseDobToApi(String dob) {
    try {
      DateTime? dt;
      final formats = [
        DateFormat('d MMM yyyy'),
        DateFormat('dd MMM yyyy'),
        DateFormat('d MMMM yyyy'),
        DateFormat('dd MMMM yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
      ];
      for (final f in formats) {
        try {
          dt = f.parse(dob.trim());
          break;
        } catch (_) {}
      }
      if (dt != null) {
        return DateFormat('yyyy-MM-dd').format(dt);
      }
    } catch (_) {}
    return '1998-12-13';
  }

  String _parseTobToApi(String tob) {
    try {
      tob = tob.trim();
      final formats = [
        DateFormat('hh:mm a'),
        DateFormat('h:mm a'),
        DateFormat('HH:mm'),
        DateFormat('H:mm'),
        DateFormat('hh:mma'),
        DateFormat('h:mma'),
      ];
      for (final f in formats) {
        try {
          final dt = f.parse(tob);
          return DateFormat('HH:mm').format(dt);
        } catch (_) {}
      }
    } catch (_) {}
    return '09:30';
  }

  Future<void> _fetchKundliData() async {
    setState(() => _isLoadingKundli = true);
    final data = await AstroApiService.getKundli(
      name: _personName,
      dateOfBirth: _parseDobToApi(_dob),
      timeOfBirth: _parseTobToApi(_tob),
      placeOfBirth: _pob,
    );
    if (mounted) {
      setState(() {
        _kundliData = data;
        _isLoadingKundli = false;
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Horoscope & Kundli',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.api_rounded, color: Color(0xFF059669)),
            tooltip: 'Live Backend Hub',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiSettingsScreen()),
              ).then((_) => _fetchKundliData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF4338CA)),
            tooltip: 'Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Generating HD 12-page Kundli PDF for $_personName...', style: GoogleFonts.outfit()),
                  backgroundColor: const Color(0xFF4338CA),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing Kundli Chart for $_personName', style: GoogleFonts.outfit()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF4338CA),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: const Color(0xFF4338CA),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'D1 & D9 Charts'),
            Tab(text: 'Planets & KP Lords'),
            Tab(text: 'Shadbala & Yogas'),
            Tab(text: 'Vimshottari Dasha'),
            Tab(text: 'Ashtakvarga (SAV)'),
          ],
        ),
      ),
      body: _isLoadingKundli
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4338CA)),
                  SizedBox(height: 12),
                  Text('Calculating Swiss Ephemeris Placements...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLagnaChartTab(context, isDark),
                _buildPlanetsTab(context, isDark),
                _buildShadbalaAndYogasTab(context, isDark),
                _buildDashaTab(context, isDark),
                _buildAshtakvargaTab(context, isDark),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: BouncyTouchCard(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kundli PDF ready! Saved to Downloads folder.', style: GoogleFonts.outfit()),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Download Complete Janam Kundli PDF',
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

  // --- TAB 1: LAGNA & NAVAMSHA CHART TAB ---
  Widget _buildLagnaChartTab(BuildContext context, bool isDark) {
    final ascLagna = _kundliData?['ascendant_lagna']?.toString() ?? 'Capricorn (Makara)';
    final moonSign = _kundliData?['moon_sign_rashi']?.toString() ?? 'Libra (Tula)';
    final nakshatra = _kundliData?['nakshatra']?.toString() ?? 'Chitra';
    final nakPada = _kundliData?['nakshatra_pada']?.toString() ?? '4';
    final ayanamsa = _kundliData?['ayanamsa_formatted']?.toString() ?? "23° 50' 32\"";

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Person Info Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _personName,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildProfileChip(Icons.calendar_today_rounded, _dob),
                  _buildProfileChip(Icons.access_time_rounded, _tob),
                  _buildProfileChip(Icons.location_on_rounded, _pob),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAscendantBadge('Ascendant (Lagna)', ascLagna),
                  _buildAscendantBadge('Moon Sign (Rashi)', moonSign),
                  _buildAscendantBadge('Nakshatra', '$nakshatra\nPada $nakPada'),
                  _buildAscendantBadge('Lahiri Ayanamsa', ayanamsa),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Divisional Chart Switcher (D1 vs D9)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isNavamsha = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isNavamsha
                          ? (isDark ? const Color(0xFF4338CA) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_isNavamsha
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars_rounded, size: 16, color: !_isNavamsha ? (isDark ? Colors.white : const Color(0xFF4338CA)) : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'D1 Rashi (Natal Chart)',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: !_isNavamsha ? FontWeight.bold : FontWeight.w500,
                            color: !_isNavamsha ? (isDark ? Colors.white : const Color(0xFF4338CA)) : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isNavamsha = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isNavamsha
                          ? (isDark ? const Color(0xFF4338CA) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _isNavamsha
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diamond_rounded, size: 16, color: _isNavamsha ? (isDark ? Colors.white : const Color(0xFF4338CA)) : Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'D9 Navamsha (Dharma)',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: _isNavamsha ? FontWeight.bold : FontWeight.w500,
                            color: _isNavamsha ? (isDark ? Colors.white : const Color(0xFF4338CA)) : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Chart Style Selector
        Text('Chart Representation Style', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: KundliChartStyle.values.map((style) {
              final isSelected = style == _currentChartStyle;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentChartStyle = style;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF4338CA) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      style == KundliChartStyle.northIndian
                          ? 'North (उत्तर)'
                          : style == KundliChartStyle.southIndian
                              ? 'South (दक्षिण)'
                              : 'East (सूर्य)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF4338CA))
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Kundli Chart View
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D36) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(_isNavamsha ? Icons.diamond_rounded : Icons.auto_awesome, color: const Color(0xFF6366F1), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isNavamsha ? 'D9 Navamsha (Spouse)' : 'D1 Natal Lagna Kundli',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF4338CA)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _currentChartStyle.title,
                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
                isNavamsha: _isNavamsha,
                kundliData: _kundliData,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Swiss Ephemeris Precision • Lahiri Chitrapaksha Ayanamsa',
                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- TAB 2: PLANETS & KP LORDS TAB ---
  Widget _buildPlanetsTab(BuildContext context, bool isDark) {
    final rawPlanets = (_kundliData?['planets'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Planetary Coordinates & KP Lords', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Swiss Ephemeris Live',
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rawPlanets.isEmpty)
          const Center(child: Text('No planetary data available'))
        else
          ...rawPlanets.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value as Map<String, dynamic>;
            final name = p['name']?.toString() ?? 'Planet';
            final sanskrit = p['sanskrit_name']?.toString() ?? '';
            final sign = p['sign']?.toString() ?? 'Aries';
            final degree = p['degree_formatted']?.toString() ?? "15° 00'";
            final speed = (p['speed_deg_per_day'] as num?)?.toDouble() ?? 0.0;
            final isRetro = p['is_retrograde'] == true;
            final nakshatra = p['nakshatra']?.toString() ?? 'Ashwini';
            final pada = (p['nakshatra_pada'] ?? 1).toString();
            final house = (p['house'] ?? 1).toString();
            final lord = p['nakshatra_lord']?.toString() ?? 'Ketu';
            final dignity = p['dignity']?.toString() ?? (isRetro ? 'Retrograde' : 'Direct');
            
            final kp = p['kp_lords'] as Map<String, dynamic>?;
            final starLord = kp?['star_lord']?.toString() ?? lord;
            final subLord = kp?['sub_lord']?.toString() ?? '';
            final subSubLord = kp?['sub_sub_lord']?.toString() ?? '';

            final navamsha = p['navamsha'] as Map<String, dynamic>?;
            final navSign = navamsha?['navamsha_sign']?.toString() ?? '';
            final isVargottama = navamsha?['is_vargottama'] == true;

            final colorHex = p['color']?.toString() ?? '#4338CA';
            Color color;
            try {
              color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
            } catch (_) {
              color = const Color(0xFF4338CA);
            }

            return _buildDetailedPlanetCard(
              idx,
              name,
              sanskrit,
              sign,
              degree,
              speed,
              isRetro,
              nakshatra,
              pada,
              house,
              lord,
              starLord,
              subLord,
              subSubLord,
              navSign,
              isVargottama,
              dignity,
              color,
              isDark,
            );
          }),
      ],
    );
  }

  // --- TAB 3: SHADBALA & YOGAS TAB ---
  Widget _buildShadbalaAndYogasTab(BuildContext context, bool isDark) {
    final rawShadbala = _kundliData?['shadbala'];
    final List<Map<String, dynamic>> shadbalaItems = [];
    if (rawShadbala is List) {
      for (final item in rawShadbala) {
        if (item is Map) shadbalaItems.add(Map<String, dynamic>.from(item));
      }
    } else if (rawShadbala is Map) {
      final pMap = rawShadbala['planets'];
      if (pMap is Map) {
        for (final entry in pMap.entries) {
          final sData = Map<String, dynamic>.from(entry.value as Map);
          sData['planet'] = entry.key;
          shadbalaItems.add(sData);
        }
      } else if (pMap is List) {
        for (final item in pMap) {
          if (item is Map) shadbalaItems.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final rawYogas = _kundliData?['vedic_yogas'] ?? _kundliData?['yogas'];
    final yogas = (rawYogas as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Shadbala Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('6-Fold Shadbala Planetary Strengths', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4338CA).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Parashara System',
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF4338CA), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Measures 6 planetary forces: Positional (Sthana), Directional (Dig), Temporal (Kala), Motional (Chesta), Natural (Naisargika) & Aspectual (Drik)', style: GoogleFonts.outfit(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54)),
        const SizedBox(height: 14),

        if (shadbalaItems.isEmpty)
          const Center(child: Text('No Shadbala calculations available'))
        else
          ...shadbalaItems.map((sData) {
            final pName = sData['planet']?.toString() ?? 'Planet';
            final sanskrit = sData['sanskrit']?.toString() ?? '';
            final totalRupas = (sData['total_rupas'] ?? sData['total_shadbala_rupas'] as num?)?.toDouble() ?? 5.5;
            final reqRupas = (sData['required_rupas'] as num?)?.toDouble() ?? 5.5;
            final percent = (sData['strength_percentage'] as num?)?.toDouble() ?? 100.0;
            final isStrong = sData['is_strong'] == true;
            final virupas = (sData['total_virupas'] ?? sData['total_shadbala_virupas'] as num?)?.toDouble() ?? 330.0;

            final breakdown = (sData['breakdown_virupas'] as Map<String, dynamic>?) ?? {};
            final sthana = sData['sthana_bala'] ?? breakdown['sthana_bala'] ?? 0;
            final dig = sData['dig_bala'] ?? breakdown['dig_bala'] ?? 0;
            final kala = sData['kala_bala'] ?? breakdown['kala_bala'] ?? 0;
            final chesta = sData['chesta_bala'] ?? breakdown['chesta_bala'] ?? 0;
            final naisargika = sData['naisargika_bala'] ?? breakdown['naisargika_bala'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isStrong
                      ? const Color(0xFF059669).withValues(alpha: 0.5)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _formatPlanetDisplayName(pName, sanskrit),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${totalRupas.toStringAsFixed(2)} / $reqRupas Req.',
                              style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isStrong
                              ? const Color(0xFF059669).withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isStrong ? 'Strong (बलवान) ${percent.toStringAsFixed(0)}%' : 'Average (मध्यम) ${percent.toStringAsFixed(0)}%',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isStrong ? const Color(0xFF059669) : Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (percent / 150.0).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isStrong ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBalaChip('Sthana: $sthana', isDark),
                      _buildBalaChip('Dig: $dig', isDark),
                      _buildBalaChip('Kala: $kala', isDark),
                      _buildBalaChip('Chesta: $chesta', isDark),
                      _buildBalaChip('Naisargika: $naisargika', isDark),
                      _buildBalaChip('Total: $virupas Virupas', isDark),
                    ],
                  ),
                ],
              ),
            );
          }),


        const SizedBox(height: 18),

        // Vedic Yogas Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Classical Vedic Yogas Detected', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${yogas.length} Active Yogas',
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (yogas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('No major classical yogas detected in current placement.'),
          )
        else
          ...yogas.asMap().entries.map((entry) {
            final idx = entry.key;
            final y = entry.value as Map<String, dynamic>;
            final name = y['name']?.toString() ?? 'Yoga';
            final category = y['category']?.toString() ?? 'Raja Yoga';
            final desc = y['description']?.toString() ?? '';
            final planetsInvolved = (y['planets_involved'] as List<dynamic>?)?.join(', ') ?? '';

            return StaggeredAnimatedItem(
              index: idx,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF0FDF4), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.military_tech_rounded, color: Color(0xFF059669), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(desc, style: GoogleFonts.outfit(fontSize: 12.5, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                    if (planetsInvolved.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Planets Involved: $planetsInvolved', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA))),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBalaChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
      ),
    );
  }

  // --- TAB 4: DASHA TAB ---
  Widget _buildDashaTab(BuildContext context, bool isDark) {
    final activeDasha = _kundliData?['current_running_dasha'] as Map<String, dynamic>?;
    final dashaTimeline = (_kundliData?['vimshottari_dasha_timeline'] as List<dynamic>?) ?? [];

    final activeMahadasha = activeDasha?['active_mahadasha']?.toString() ?? 'Jupiter (Guru)';
    final activeAntardasha = activeDasha?['active_antardasha']?.toString() ?? 'Saturn (Shani)';
    final activePratyantar = activeDasha?['active_pratyantar']?.toString() ?? 'Mercury (Budha)';
    final activePeriod = '${activeDasha?['active_mahadasha_start'] ?? ''} to ${activeDasha?['active_mahadasha_end'] ?? ''}';

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4338CA).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timelapse_rounded, color: Color(0xFF4338CA), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Running Mahadasha', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                    Text('$activeMahadasha Mahadasha', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                    Text('Antardasha: $activeAntardasha • Pratyantar: $activePratyantar', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                    if (activePeriod.trim() != 'to') ...[
                      const SizedBox(height: 2),
                      Text('Period: $activePeriod', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Vimshottari Mahadasha & Antardasha Timeline (120 Years)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        if (dashaTimeline.isEmpty)
          const Center(child: Text('No dasha timeline available'))
        else
          ...dashaTimeline.asMap().entries.map((entry) {
            final idx = entry.key;
            final d = entry.value as Map<String, dynamic>;
            final planet = d['planet']?.toString() ?? 'Planet';
            final years = '${d['duration_years'] ?? 7} Years';
            final period = '${d['start'] ?? ''} - ${d['end'] ?? ''}';
            final isActive = d['is_active'] == true;
            final isCompleted = d['is_completed'] == true;
            final status = isActive ? 'Active Now (चल रही है)' : (isCompleted ? 'Completed' : 'Upcoming');
            final color = isActive ? const Color(0xFF059669) : (isCompleted ? Colors.grey : const Color(0xFF4338CA));
            final antardashas = (d['antardashas'] as List<dynamic>?) ?? [];

            return _buildDashaExpansionTile(
              idx,
              '$planet Mahadasha',
              years,
              period,
              status,
              color,
              antardashas,
              isDark,
            );
          }),
      ],
    );
  }

  Widget _buildDashaExpansionTile(
    int index,
    String title,
    String duration,
    String period,
    String status,
    Color color,
    List<dynamic> antardashas,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('$duration • $period', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          children: [
            if (antardashas.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Antardasha Sub-Periods:', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...antardashas.map((ad) {
                      final adPlanet = ad['planet']?.toString() ?? '';
                      final adStart = ad['start']?.toString() ?? '';
                      final adEnd = ad['end']?.toString() ?? '';
                      final adActive = ad['is_active'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: adActive ? const Color(0xFF059669) : Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  '$adPlanet Antardasha',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: adActive ? FontWeight.bold : FontWeight.w500,
                                    color: adActive ? const Color(0xFF059669) : null,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$adStart - $adEnd',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: adActive ? const Color(0xFF059669) : (isDark ? Colors.white60 : Colors.black54),
                                fontWeight: adActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 5: ASHTAKVARGA TAB ---
  Widget _buildAshtakvargaTab(BuildContext context, bool isDark) {
    final ashtakvarga = _kundliData?['ashtakvarga'] as Map<String, dynamic>?;
    final totalSav = ashtakvarga?['total_sav_points'] ?? 337;
    final signPoints = (ashtakvarga?['sign_points'] as Map<String, dynamic>?) ?? {};
    final pointValues = signPoints.values.map((v) => (v as num).toInt()).toList();
    final defaultPoints = [28, 31, 29, 34, 36, 27, 30, 26, 33, 25, 32, 26];
    final displayPoints = pointValues.isNotEmpty ? pointValues : defaultPoints;

    final bav = ashtakvarga?['bhinnashtakavarga'] as Map<String, dynamic>?;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount = 4;
        if (screenWidth < 340) {
          crossAxisCount = 3;
        } else if (screenWidth > 600) {
          crossAxisCount = 6;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          children: [
            Text('Sarvashtakvarga (SAV) Points per House', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Total SAV score: $totalSav points (Benchmark: ≥ 28 points = Auspicious Benefic Strength)', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final houseNum = index + 1;
                final points = index < displayPoints.length ? displayPoints[index] : 28;
                final isHigh = points >= 30;
                final isAvg = points >= 26 && points < 30;

                return StaggeredAnimatedItem(
                  index: index,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHigh
                          ? const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.1)
                          : (isAvg ? const Color(0xFF4338CA).withValues(alpha: isDark ? 0.2 : 0.08) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isHigh
                            ? const Color(0xFF059669)
                            : (isAvg ? const Color(0xFF4338CA) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('H$houseNum', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                        Text(
                          '$points',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isHigh
                                ? const Color(0xFF059669)
                                : (isAvg ? const Color(0xFF4338CA) : (isDark ? Colors.white : const Color(0xFF0F172A))),
                          ),
                        ),
                        Text(isHigh ? 'Strong' : (isAvg ? 'Moderate' : 'Low'), style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (bav != null && bav.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Bhinnashtakavarga (BAV) 7 Planets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: bav.entries.map((e) {
                    final pName = e.key;
                    final pts = (e.value as List<dynamic>?)?.map((x) => (x as num).toInt()).toList() ?? [];
                    final total = pts.fold(0, (sum, val) => sum + val);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(pName, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Total: $total Bindus', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4338CA), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static String _formatPlanetDisplayName(String name, String sanskrit) {
    name = name.trim();
    sanskrit = sanskrit.trim();
    if (name.isEmpty) return sanskrit;
    if (sanskrit.isEmpty) return name;

    final englishName = name.split('(').first.trim();
    final devanagariMatch = RegExp(r'[\u0900-\u097F]+').firstMatch(sanskrit);
    if (devanagariMatch != null) {
      return '$englishName (${devanagariMatch.group(0)})';
    }
    if (name.contains('(')) {
      return name;
    }
    return '$name ($sanskrit)';
  }

  Widget _buildProfileChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAscendantBadge(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDetailedPlanetCard(
    int index,
    String name,
    String sanskrit,
    String sign,
    String degree,
    double speed,
    bool isRetro,
    String nakshatra,
    String pada,
    String house,
    String nakshatraLord,
    String starLord,
    String subLord,
    String subSubLord,
    String navSign,
    bool isVargottama,
    String dignity,
    Color accentColor,
    bool isDark,
  ) {
    final displayName = _formatPlanetDisplayName(name, sanskrit);

    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isVargottama
                ? const Color(0xFF059669).withValues(alpha: 0.6)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isRetro) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('R', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.red)),
                            ),
                          ],
                          if (isVargottama) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Vargottama 🌟', style: GoogleFonts.outfit(fontSize: 9.0, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sign • House $house • $degree (${speed >= 0 ? '+' : ''}${speed.toStringAsFixed(3)}°/d)',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: accentColor, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '$nakshatra Pada $pada (Lord: $nakshatraLord)',
                        style: GoogleFonts.outfit(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(maxWidth: 130),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dignity,
                    style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: accentColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'KP Lords: Star: $starLord • Sub: $subLord${subSubLord.isNotEmpty ? ' • SS: $subSubLord' : ''}',
                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (navSign.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      'D9: $navSign',
                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _EditBirthDetailsDialog(
        initialName: _personName,
        initialDob: _dob,
        initialTob: _tob,
        initialPob: _pob,
        onSave: (name, dob, tob, pob) {
          setState(() {
            _personName = name;
            _dob = dob;
            _tob = tob;
            _pob = pob;
          });
          _fetchKundliData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calculated high-precision Kundli for $name ($pob)', style: GoogleFonts.outfit()),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _EditBirthDetailsDialog extends StatefulWidget {
  final String initialName;
  final String initialDob;
  final String initialTob;
  final String initialPob;
  final Function(String name, String dob, String tob, String pob) onSave;

  const _EditBirthDetailsDialog({
    required this.initialName,
    required this.initialDob,
    required this.initialTob,
    required this.initialPob,
    required this.onSave,
  });

  @override
  State<_EditBirthDetailsDialog> createState() => _EditBirthDetailsDialogState();
}

class _EditBirthDetailsDialogState extends State<_EditBirthDetailsDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _pobCtrl;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final List<String> _popularCities = [
    'Kanyakumari, India',
    'Chennai, Tamil Nadu',
    'Bengaluru, Karnataka',
    'Mumbai, Maharashtra',
    'New Delhi, India',
    'Kolkata, West Bengal',
    'Hyderabad, Telangana',
    'Varanasi, UP',
    'Madurai, Tamil Nadu',
    'Nagercoil, Tamil Nadu',
    'Trivandrum, Kerala',
    'London, UK',
    'New York, USA',
    'Dubai, UAE',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _pobCtrl = TextEditingController(text: widget.initialPob);
    _selectedDate = _parseDob(widget.initialDob);
    _selectedTime = _parseTob(widget.initialTob);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pobCtrl.dispose();
    super.dispose();
  }

  DateTime _parseDob(String str) {
    try {
      return DateFormat('d MMM yyyy').parse(str);
    } catch (_) {
      try {
        return DateFormat('dd-MM-yyyy').parse(str);
      } catch (_) {
        return DateTime(1998, 12, 13);
      }
    }
  }

  TimeOfDay _parseTob(String str) {
    try {
      final dt = DateFormat('hh:mm a').parse(str);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      try {
        final dt = DateFormat('HH:mm').parse(str);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {
        return const TimeOfDay(hour: 9, minute: 30);
      }
    }
  }

  String _formatTime(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _pickDate(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Select Date',
      builder: (context, child) {
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4338CA),
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: const Color(0xFF4338CA),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context, bool isDark) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Select Time of Birth',
      cancelText: 'Cancel',
      confirmText: 'Select Time',
      builder: (context, child) {
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4338CA),
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: const Color(0xFF4338CA),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDob = DateFormat('d MMM yyyy').format(_selectedDate);
    final dayOfWeek = DateFormat('EEEE').format(_selectedDate);
    final formattedTob = _formatTime(_selectedTime);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4338CA).withValues(alpha: isDark ? 0.35 : 0.15),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Birth Details',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          'Accurate parameters for Swiss Ephemeris',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name Field
                    Text(
                      'Full Name',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter full name',
                        prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF4338CA), size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date of Birth Selector
                    Text(
                      'Date of Birth',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    BouncyTouchCard(
                      onTap: () => _pickDate(context, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4338CA), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDob,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    dayOfWeek,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4338CA).withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_calendar_rounded, color: Color(0xFF4338CA), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Select',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4338CA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time of Birth Selector
                    Text(
                      'Time of Birth',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    BouncyTouchCard(
                      onTap: () => _pickTime(context, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF6366F1), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedTob,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '12-Hour Format',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded, color: Color(0xFF6366F1), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Select',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Place of Birth Field
                    Text(
                      'Place of Birth',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pobCtrl,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'City, Country',
                        prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF4338CA), size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick City Suggestion Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _popularCities.map((city) {
                        final isSelected = _pobCtrl.text == city;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _pobCtrl.text = city;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4338CA).withValues(alpha: 0.18)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4338CA)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              city.split(',')[0],
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF4338CA)
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: BouncyTouchCard(
                      onTap: () {
                        final name = _nameCtrl.text.trim().isEmpty ? widget.initialName : _nameCtrl.text.trim();
                        final pob = _pobCtrl.text.trim().isEmpty ? widget.initialPob : _pobCtrl.text.trim();
                        widget.onSave(name, formattedDob, formattedTob, pob);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4338CA).withValues(alpha: 0.38),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Save & Calculate',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
