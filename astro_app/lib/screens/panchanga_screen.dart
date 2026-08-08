import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';
import '../widgets/celestial_animations.dart';

class PanchangaScreen extends StatefulWidget {
  const PanchangaScreen({super.key});

  @override
  State<PanchangaScreen> createState() => _PanchangaScreenState();
}

class _PanchangaScreenState extends State<PanchangaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  Map<String, dynamic>? _panchangData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPanchangData();
  }

  Future<void> _fetchPanchangData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final data = await AstroApiService.getDailyPanchang(date: dateStr);
    if (mounted) {
      setState(() {
        _panchangData = data;
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
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Panchanga & Muhurta',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706)),
            tooltip: 'Pick Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2040),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
                _fetchPanchangData();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD97706),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: const Color(0xFFD97706),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: '5 Angas of Panchang'),
            Tab(text: 'Shubh Muhurtas'),
            Tab(text: 'Choghadiya'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF131D36) : const Color(0xFFFEF3C7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                    _fetchPanchangData();
                  },
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      dateFormatted,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _fetchPanchangData();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFD97706)),
                        SizedBox(height: 12),
                        Text('Computing Ephemeris & Five Panchanga Angas...'),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _build5AngasTab(context, isDark),
                      _buildMuhurtaTab(context, isDark),
                      _buildChoghadiyaTab(context, isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: 5 ANGAS OF PANCHANG ---
  Widget _build5AngasTab(BuildContext context, bool isDark) {
    final sunrise = _panchangData?['sunrise']?.toString() ?? '06:41 AM';
    final sunset = _panchangData?['sunset']?.toString() ?? '06:22 PM';
    final moonrise = _panchangData?['moonrise']?.toString() ?? '08:14 PM';
    final moonset = _panchangData?['moonset']?.toString() ?? '07:30 AM';
    final vikram = _panchangData?['vikram_samvat']?.toString() ?? '2083 (कालयुक्त)';
    final shaka = _panchangData?['shaka_samvat']?.toString() ?? '1948';

    final tithi = _panchangData?['tithi']?.toString() ?? 'Shukla Paksha Dwitiya upto 04:18 PM';
    final nakshatra = _panchangData?['nakshatra']?.toString() ?? 'Rohini (रोहिणी) upto 08:42 PM';
    final yoga = _panchangData?['yoga']?.toString() ?? 'Shubha (शुभ) upto 11:30 AM';
    final karana = _panchangData?['karana']?.toString() ?? 'Balava (बालव) upto 04:18 PM';
    final vara = _panchangData?['vara']?.toString() ?? 'Budhavara (बुधवार - Wednesday)';

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Solar & Lunar Timing Card with Rotating Celestial Icons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSunMoonTime('Sunrise', sunrise, Icons.wb_sunny_rounded, true),
                  _buildSunMoonTime('Sunset', sunset, Icons.nights_stay_rounded, false),
                  _buildSunMoonTime('Moonrise', moonrise, Icons.brightness_2_rounded, false),
                  _buildSunMoonTime('Moonset', moonset, Icons.bedtime_rounded, false),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text('Vikram Samvat: $vikram', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text('Shaka: $shaka', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('The 5 Essential Elements (पंचांग)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Vedic Panchanga',
                style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFD97706), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAngaCard(
          0,
          '1. Tithi (Lunar Day)',
          tithi,
          'Next: Tritiya (तीज) • Auspicious for all religious rituals & buying assets',
          Icons.brightness_6_rounded,
          const Color(0xFFD97706),
          'Lord: Brahma',
          isDark,
        ),
        _buildAngaCard(
          1,
          '2. Nakshatra (Lunar Mansion)',
          nakshatra,
          'Next: Mrigashira • Fixed (Dhruva) nature, highly auspicious for starting construction & weddings',
          Icons.star_rounded,
          const Color(0xFF6366F1),
          'Lord: Chandra (Moon)',
          isDark,
        ),
        _buildAngaCard(
          2,
          '3. Yoga (Solar-Lunar Angle)',
          yoga,
          'Next: Shukla Yoga • Promotes peace, prosperity, wealth, and wellness',
          Icons.self_improvement_rounded,
          const Color(0xFF059669),
          'Deity: Lakshmi',
          isDark,
        ),
        _buildAngaCard(
          3,
          '4. Karana (Half-Tithi)',
          karana,
          'Next: Kaulava • Excellent for holy deeds, study, and learning sacred sciences',
          Icons.bubble_chart_rounded,
          const Color(0xFF0284C7),
          'Lord: Brahma',
          isDark,
        ),
        _buildAngaCard(
          4,
          '5. Vara (Weekday)',
          vara,
          'Day of Mercury (Budha) • Auspicious for business transactions, logic, calculations, and travel',
          Icons.calendar_today_rounded,
          const Color(0xFF7C3AED),
          'Lord: Budha (Mercury)',
          isDark,
        ),
      ],
    );
  }

  // --- TAB 2: MUHURTAS TAB ---
  Widget _buildMuhurtaTab(BuildContext context, bool isDark) {
    final abhijit = _panchangData?['muhurtas']?['abhijit']?.toString() ?? '11:58 AM - 12:49 PM';
    final brahma = _panchangData?['muhurtas']?['brahma']?.toString() ?? '05:04 AM - 05:52 AM';
    final amrit = _panchangData?['muhurtas']?['amrit_kaal']?.toString() ?? '02:15 PM - 03:48 PM';
    final godhuli = _panchangData?['muhurtas']?['godhuli']?.toString() ?? '06:18 PM - 06:42 PM';
    final vijay = _panchangData?['muhurtas']?['vijay']?.toString() ?? '02:26 PM - 03:14 PM';

    final rahu = _panchangData?['inauspicious']?['rahu_kaal']?.toString() ?? '12:28 PM - 02:04 PM';
    final yamaganda = _panchangData?['inauspicious']?['yamaganda']?.toString() ?? '07:41 AM - 09:16 AM';
    final gulika = _panchangData?['inauspicious']?['gulika']?.toString() ?? '10:52 AM - 12:28 PM';
    final dur = _panchangData?['inauspicious']?['dur_muhurtam']?.toString() ?? '11:58 AM - 12:49 PM';

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Auspicious Timings (शुभ मुहूर्त)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF059669))),
        const SizedBox(height: 10),
        _buildMuhurtaTile(0, 'Abhijit Muhurta (सर्वश्रेष्ठ)', abhijit, 'Most auspicious period of the day', Colors.green, isDark),
        _buildMuhurtaTile(1, 'Brahma Muhurta (अमृत काल)', brahma, 'Best for meditation, prayers and studies', Colors.green, isDark),
        _buildMuhurtaTile(2, 'Amrit Kaal', amrit, 'Favorable for important meetings and deals', Colors.green, isDark),
        _buildMuhurtaTile(3, 'Godhuli Muhurta', godhuli, 'Auspicious evening twilight period', Colors.green, isDark),
        _buildMuhurtaTile(4, 'Vijay Muhurta', vijay, 'Victorious time for starting new ventures', Colors.green, isDark),
        const SizedBox(height: 20),
        Text('Inauspicious Timings (अशुभ काल - Avoid)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFE11D48))),
        const SizedBox(height: 10),
        _buildMuhurtaTile(5, 'Rahu Kaal (राहुकाल)', rahu, 'Do NOT start new initiatives or travel', Colors.redAccent, isDark),
        _buildMuhurtaTile(6, 'Yamaganda Kaal', yamaganda, 'Avoid financial contracts and signing', Colors.redAccent, isDark),
        _buildMuhurtaTile(7, 'Gulika Kaal', gulika, 'Actions repeat under this influence', Colors.orange, isDark),
        _buildMuhurtaTile(8, 'Dur Muhurtam', dur, 'Inauspicious planetary alignment', Colors.orange, isDark),
      ],
    );
  }

  // --- TAB 3: CHOGHADIYA TAB ---
  Widget _buildChoghadiyaTab(BuildContext context, bool isDark) {
    final choghadiyaList = (_panchangData?['choghadiya'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Day Choghadiya (दिन का चौघड़िया)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        if (choghadiyaList.isEmpty) ...[
          _buildChoghadiyaRow(0, '06:41 AM - 08:08 AM', 'Labh (लाभ)', 'Profit & Gain', Colors.green, isDark),
          _buildChoghadiyaRow(1, '08:08 AM - 09:35 AM', 'Amrit (अमृत)', 'Best Auspicious', Colors.teal, isDark),
          _buildChoghadiyaRow(2, '09:35 AM - 11:02 AM', 'Kaal (काल)', 'Inauspicious (Loss)', Colors.red, isDark),
          _buildChoghadiyaRow(3, '11:02 AM - 12:28 PM', 'Shubh (शुभ)', 'Good & Holy', Colors.green, isDark),
          _buildChoghadiyaRow(4, '12:28 PM - 01:55 PM', 'Rog (रोग)', 'Sickness (Avoid)', Colors.red, isDark),
          _buildChoghadiyaRow(5, '01:55 PM - 03:22 PM', 'Udveg (उद्वेग)', 'Worry & Anxiety', Colors.orange, isDark),
          _buildChoghadiyaRow(6, '03:22 PM - 04:49 PM', 'Char (चर)', 'Neutral / Travel', Colors.blue, isDark),
          _buildChoghadiyaRow(7, '04:49 PM - 06:22 PM', 'Labh (लाभ)', 'Profit & Gain', Colors.green, isDark),
        ] else
          ...choghadiyaList.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value as Map<String, dynamic>;
            final time = c['time']?.toString() ?? '';
            final name = c['name']?.toString() ?? '';
            final meaning = c['meaning']?.toString() ?? '';
            final isGood = c['is_good'] == true;
            final color = isGood ? Colors.green : Colors.red;

            return _buildChoghadiyaRow(idx, time, name, meaning, color, isDark);
          }),
      ],
    );
  }

  Widget _buildSunMoonTime(String title, String time, IconData icon, bool rotate) {
    return Column(
      children: [
        if (rotate)
          SmoothRotatingWidget(
            duration: const Duration(seconds: 24),
            child: Icon(icon, color: Colors.white, size: 20),
          )
        else
          Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
        Text(time, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAngaCard(int index, String title, String mainVal, String subtitle, IconData icon, Color color, String lord, bool isDark) {
    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(lord, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(mainVal, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuhurtaTile(int index, String name, String timing, String desc, Color color, bool isDark) {
    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(timing, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChoghadiyaRow(int index, String timing, String name, String nature, Color color, bool isDark) {
    return StaggeredAnimatedItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(timing, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(nature, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
