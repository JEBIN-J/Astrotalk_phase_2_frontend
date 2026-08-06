import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/astro_models.dart';
import '../widgets/celestial_animations.dart';
import '../widgets/kundli_chart_painter.dart';

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
  String _personName = 'Rahul Sharma';
  String _dob = '15 Aug 1995';
  String _tob = '06:30 AM';
  String _pob = 'New Delhi, India';

  @override
  void initState() {
    super.initState();
    _currentChartStyle = widget.initialChartStyle;
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: 'D1 Lagna Chart'),
            Tab(text: 'Planets & Dignities'),
            Tab(text: 'Vimshottari Dasha'),
            Tab(text: 'Ashtakvarga'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLagnaChartTab(context, isDark),
          _buildPlanetsTab(context, isDark),
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

  // --- TAB 1: LAGNA CHART TAB ---
  Widget _buildLagnaChartTab(BuildContext context, bool isDark) {
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
                  _buildAscendantBadge('Ascendant (Lagna)', 'Mesha (Aries)'),
                  _buildAscendantBadge('Moon Sign (Rashi)', 'Vrishabha (Taurus)'),
                  _buildAscendantBadge('Nakshatra', 'Rohini Pada 3'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'D1 Natal Kundli',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF4338CA)),
                      ),
                    ],
                  ),
                  Text(
                    _currentChartStyle.title,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- TAB 2: PLANETS TAB ---
  Widget _buildPlanetsTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Planetary Positions & States', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildDetailedPlanetCard(0, 'Lagna (Ascendant)', 'Mesha (Aries)', '14° 22\' 18"', 'Ashwini', '1', 'Ketu', 'Normal', Colors.purple, isDark),
        _buildDetailedPlanetCard(1, 'Sun (Surya)', 'Kanya (Virgo)', '08° 14\' 02"', 'Uttara Phalguni', '6', 'Sun', 'Friendly', Colors.orange, isDark),
        _buildDetailedPlanetCard(2, 'Moon (Chandra)', 'Vrishabha (Taurus)', '21° 45\' 50"', 'Rohini', '2', 'Moon', 'Exalted (उच्च)', Colors.blue, isDark),
        _buildDetailedPlanetCard(3, 'Mars (Mangal)', 'Makara (Capricorn)', '11° 02\' 44"', 'Shravana', '10', 'Moon', 'Exalted (उच्च)', Colors.red, isDark),
        _buildDetailedPlanetCard(4, 'Mercury (Budha)', 'Kanya (Virgo)', '17° 55\' 12"', 'Hasta', '6', 'Moon', 'Exalted / Moolatrikona', Colors.green, isDark),
        _buildDetailedPlanetCard(5, 'Jupiter (Guru)', 'Karkata (Cancer)', '05° 33\' 09"', 'Pushya', '4', 'Saturn', 'Exalted (उच्च)', Colors.amber, isDark),
        _buildDetailedPlanetCard(6, 'Venus (Shukra)', 'Meena (Pisces)', '19° 12\' 30"', 'Revati', '12', 'Mercury', 'Exalted (उच्च)', Colors.teal, isDark),
        _buildDetailedPlanetCard(7, 'Saturn (Shani)', 'Kumbha (Aquarius)', '22° 40\' 18"', 'Purva Bhadra', '11', 'Jupiter', 'Own Sign (स्वक्षेत्री)', Colors.indigo, isDark),
        _buildDetailedPlanetCard(8, 'Rahu (North Node)', 'Meena (Pisces)', '14° 02\' 09"', 'Uttara Bhadra', '12', 'Saturn', 'Retrograde', Colors.blueGrey, isDark),
        _buildDetailedPlanetCard(9, 'Ketu (South Node)', 'Kanya (Virgo)', '14° 02\' 09"', 'Hasta', '6', 'Moon', 'Retrograde', Colors.blueGrey, isDark),
      ],
    );
  }

  // --- TAB 3: DASHA TAB ---
  Widget _buildDashaTab(BuildContext context, bool isDark) {
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
                    Text('Jupiter (Guru) Mahadasha', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                    Text('Antardasha: Saturn • Pratyantar: Venus', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Vimshottari Mahadasha Timeline (120 Years)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        _buildDashaTile(0, 'Moon Mahadasha', '10 Years', '1995 - 2005', 'Completed', Colors.grey, isDark),
        _buildDashaTile(1, 'Mars Mahadasha', '7 Years', '2005 - 2012', 'Completed', Colors.grey, isDark),
        _buildDashaTile(2, 'Rahu Mahadasha', '18 Years', '2012 - 2030', 'Completed', Colors.grey, isDark),
        _buildDashaTile(3, 'Jupiter Mahadasha', '16 Years', '2030 - 2046', 'Active Now (चल रही है)', const Color(0xFF059669), isDark),
        _buildDashaTile(4, 'Saturn Mahadasha', '19 Years', '2046 - 2065', 'Upcoming', Colors.indigo, isDark),
        _buildDashaTile(5, 'Mercury Mahadasha', '17 Years', '2065 - 2082', 'Upcoming', Colors.teal, isDark),
      ],
    );
  }

  // --- TAB 4: ASHTAKVARGA TAB ---
  Widget _buildAshtakvargaTab(BuildContext context, bool isDark) {
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
            Text('Total SAV score: 337 points (Ideal > 28 points per house)', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
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
                final points = [31, 28, 34, 29, 36, 25, 30, 24, 33, 38, 35, 24][index];
                final isHigh = points >= 30;

                return StaggeredAnimatedItem(
                  index: index,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHigh
                          ? const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.1)
                          : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isHigh ? const Color(0xFF059669) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
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
                            color: isHigh ? const Color(0xFF059669) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        Text('Points', style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
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
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailedPlanetCard(
    int index,
    String name,
    String sign,
    String degree,
    String nakshatra,
    String house,
    String nakshatraLord,
    String dignity,
    Color accentColor,
    bool isDark,
  ) {
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
                    decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        Text('$sign • House $house', style: GoogleFonts.outfit(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        Text('$degree • $nakshatra ($nakshatraLord)', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dignity,
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashaTile(int index, String title, String duration, String period, String status, Color color, bool isDark) {
    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$duration • $period', style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
            Container(
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
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _personName);
    final dobCtrl = TextEditingController(text: _dob);
    final tobCtrl = TextEditingController(text: _tob);
    final pobCtrl = TextEditingController(text: _pob);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Birth Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: dobCtrl, decoration: const InputDecoration(labelText: 'Date of Birth (DD MMM YYYY)')),
              TextField(controller: tobCtrl, decoration: const InputDecoration(labelText: 'Time of Birth (HH:MM AM/PM)')),
              TextField(controller: pobCtrl, decoration: const InputDecoration(labelText: 'Place of Birth (City, Country)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _personName = nameCtrl.text;
                _dob = dobCtrl.text;
                _tob = tobCtrl.text;
                _pob = pobCtrl.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save & Calculate'),
          ),
        ],
      ),
    );
  }
}
