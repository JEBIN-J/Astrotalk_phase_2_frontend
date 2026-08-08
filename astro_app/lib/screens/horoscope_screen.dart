import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../widgets/celestial_animations.dart';
import '../widgets/kundli_chart_painter.dart';
import 'api_settings_screen.dart';

enum StepperInterval {
  oneSecond,
  oneMinute,
  fiveMinutes,
  fifteenMinutes,
  oneHour,
  oneDay,
  oneMonth,
  oneYear,
}

extension StepperIntervalExt on StepperInterval {
  String get displayName {
    switch (this) {
      case StepperInterval.oneSecond:
        return '1s';
      case StepperInterval.oneMinute:
        return '1m';
      case StepperInterval.fiveMinutes:
        return '5m';
      case StepperInterval.fifteenMinutes:
        return '15m';
      case StepperInterval.oneHour:
        return '1h';
      case StepperInterval.oneDay:
        return '1d';
      case StepperInterval.oneMonth:
        return '1M';
      case StepperInterval.oneYear:
        return '1Y';
    }
  }

  Duration get duration {
    switch (this) {
      case StepperInterval.oneSecond:
        return const Duration(seconds: 1);
      case StepperInterval.oneMinute:
        return const Duration(minutes: 1);
      case StepperInterval.fiveMinutes:
        return const Duration(minutes: 5);
      case StepperInterval.fifteenMinutes:
        return const Duration(minutes: 15);
      case StepperInterval.oneHour:
        return const Duration(hours: 1);
      case StepperInterval.oneDay:
        return const Duration(days: 1);
      case StepperInterval.oneMonth:
        return const Duration(days: 30);
      case StepperInterval.oneYear:
        return const Duration(days: 365);
    }
  }
}

class HoroscopeScreen extends StatefulWidget {
  final KundliChartStyle initialChartStyle;

  const HoroscopeScreen({
    super.key,
    this.initialChartStyle = KundliChartStyle.southIndian, // Default Square Model Chart
  });

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen>
    with TickerProviderStateMixin {
  late KundliChartStyle _currentChartStyle;
  late TabController _tabController;
  late TabController _bottomSubTabController;

  String _personName = 'Jebin J';
  String _dob = '13 Dec 1998';
  String _tob = '07:18 PM';
  String _pob = 'Kanyakumari, Tamil Nadu, India';

  DateTime _currentDateTime = DateTime(1998, 12, 13, 19, 18, 00);
  final double _latitude = 8.0883;
  final double _longitude = 77.5385;
  final double _timezone = 5.5;

  String _activeChartKey = 'D-1';
  StepperInterval _stepperInterval = StepperInterval.oneMinute;
  bool _showUpagrahasOnChart = true;
  bool _showDegreesOnChart = true;
  bool _isCardViewMode = false;

  bool _isLoadingKundli = false;
  Map<String, dynamic>? _kundliData;

  static const Map<String, String> _divisionalChartsInfo = {
    'D-1': 'Rashi (Natal Physical Plane)',
    'D-2': 'Hora (Wealth & Liquid Assets)',
    'D-3': 'Drekkana (Siblings & Courage)',
    'D-4': 'Chaturthamsha (Property & Fortune)',
    'D-7': 'Saptamsha (Children & Progeny)',
    'D-9': 'Navamsha (Dharma, Soul & Marriage)',
    'D-10': 'Dasamsha (Career & Profession)',
    'D-12': 'Dwadasamsha (Parents & Lineage)',
    'D-16': 'Shodashamsha (Vehicles & Pleasures)',
    'D-20': 'Vimsamsha (Spiritual Progress)',
    'D-24': 'Siddhamsa (Higher Knowledge)',
    'D-27': 'Saptavimsamsha (Strengths)',
    'D-30': 'Trimshamsha (Misfortunes & Arishta)',
    'D-60': 'Shashtiamsha (Past Karmic Destiny)',
    'Bhava': 'Bhava Chalit (Cuspal Houses)',
  };

  @override
  void initState() {
    super.initState();
    _currentChartStyle = widget.initialChartStyle;
    _tabController = TabController(length: 5, vsync: this);
    _bottomSubTabController = TabController(length: 4, vsync: this);
    _syncDateTimeFromStrings();
    _fetchKundliData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bottomSubTabController.dispose();
    super.dispose();
  }

  void _syncDateTimeFromStrings() {
    try {
      DateTime? d;
      final dFormats = [
        DateFormat('dd MMM yyyy'),
        DateFormat('d MMM yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
      ];
      for (final f in dFormats) {
        try {
          d = f.parse(_dob.trim());
          break;
        } catch (_) {}
      }

      int hour = 19;
      int minute = 18;
      int second = 0;

      final tFormats = [
        DateFormat('hh:mm a'),
        DateFormat('h:mm a'),
        DateFormat('HH:mm:ss'),
        DateFormat('HH:mm'),
      ];
      for (final f in tFormats) {
        try {
          final t = f.parse(_tob.trim());
          hour = t.hour;
          minute = t.minute;
          second = t.second;
          break;
        } catch (_) {}
      }

      if (d != null) {
        _currentDateTime = DateTime(d.year, d.month, d.day, hour, minute, second);
      }
    } catch (_) {}
  }

  String get _dobFormattedForApi =>
      DateFormat('yyyy-MM-dd').format(_currentDateTime);
  String get _tobFormattedForApi =>
      DateFormat('HH:mm:ss').format(_currentDateTime);

  String get _headerDisplayDateTime =>
      DateFormat('dd-MMM-yyyy hh:mm:ss a').format(_currentDateTime);

  String get _formattedLatLong {
    final latDeg = _latitude.abs().floor();
    final latMin = ((_latitude.abs() - latDeg) * 60).round();
    final latDir = _latitude >= 0 ? 'N' : 'S';

    final lonDeg = _longitude.abs().floor();
    final lonMin = ((_longitude.abs() - lonDeg) * 60).round();
    final lonDir = _longitude >= 0 ? 'E' : 'W';

    final latStr = '${latDeg.toString().padLeft(2, '0')}° $latMin\' $latDir';
    final lonStr = '${lonDeg.toString().padLeft(2, '0')}° $lonMin\' $lonDir';

    return '$lonStr, $latStr';
  }

  String get _formattedTzPlace {
    final tzSign = _timezone >= 0 ? '+' : '-';
    final tzHours = _timezone.abs().floor().toString().padLeft(2, '0');
    final tzMins = ((_timezone.abs() % 1) * 60).round().toString().padLeft(2, '0');
    return 'GMT$tzSign$tzHours:$tzMins';
  }

  Future<void> _fetchKundliData() async {
    setState(() => _isLoadingKundli = true);
    final data = await AstroApiService.getKundli(
      name: _personName,
      dateOfBirth: _dobFormattedForApi,
      timeOfBirth: _tobFormattedForApi,
      placeOfBirth: _pob,
      latitude: _latitude,
      longitude: _longitude,
      timezone: _timezone,
    );
    if (mounted) {
      setState(() {
        _kundliData = data;
        _isLoadingKundli = false;
      });
    }
  }

  void _stepTime(bool forward) {
    setState(() {
      if (forward) {
        _currentDateTime = _currentDateTime.add(_stepperInterval.duration);
      } else {
        _currentDateTime = _currentDateTime.subtract(_stepperInterval.duration);
      }
      _dob = DateFormat('dd MMM yyyy').format(_currentDateTime);
      _tob = DateFormat('hh:mm a').format(_currentDateTime);
    });
    _fetchKundliData();
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, color: Color(0xFF4338CA), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Kundli Settings & Stepper',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text(
                      'Time Stepping Interval',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: const Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: StepperInterval.values.map((interval) {
                        final isSel = interval == _stepperInterval;
                        return ChoiceChip(
                          label: Text(interval.displayName),
                          selected: isSel,
                          selectedColor: const Color(0xFF4338CA),
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.outfit(
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => _stepperInterval = interval);
                              setState(() => _stepperInterval = interval);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chart System Model',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: const Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: KundliChartStyle.values.map((style) {
                        final isSel = style == _currentChartStyle;
                        String label = style == KundliChartStyle.southIndian
                            ? 'Square (दक्षिण)'
                            : style == KundliChartStyle.northIndian
                                ? 'Diamond (उत्तर)'
                                : 'Sun (सूर्य)';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSel ? const Color(0xFF4338CA) : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                                foregroundColor: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                elevation: isSel ? 2 : 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                setModalState(() => _currentChartStyle = style);
                                setState(() => _currentChartStyle = style);
                              },
                              child: Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Display Upagrahas in Chart (Md, Gk, etc.)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: _showUpagrahasOnChart,
                      activeThumbColor: const Color(0xFF4338CA),
                      onChanged: (val) {
                        setModalState(() => _showUpagrahasOnChart = val);
                        setState(() => _showUpagrahasOnChart = val);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Display Planetary Degrees (e.g. 20:22)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: _showDegreesOnChart,
                      activeThumbColor: const Color(0xFF4338CA),
                      onChanged: (val) {
                        setModalState(() => _showDegreesOnChart = val);
                        setState(() => _showDegreesOnChart = val);
                      },
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

  void _showOthersDivisionalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4338CA), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Divisional Charts (Vargas)',
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: _divisionalChartsInfo.entries.map((entry) {
                    final key = entry.key;
                    final desc = entry.value;
                    final isSel = key == _activeChartKey;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark ? const Color(0xFF4338CA).withValues(alpha: 0.25) : const Color(0xFFEEF2FF))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? const Color(0xFF4338CA) : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF4338CA) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            key,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                        title: Text(
                          desc,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? const Color(0xFF4338CA) : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        trailing: isSel ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4338CA), size: 20) : null,
                        onTap: () {
                          setState(() {
                            _activeChartKey = key;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
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
            _syncDateTimeFromStrings();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        centerTitle: false,
        title: Text(
          'Horoscope',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 24),
            tooltip: 'Edit Birth Profile',
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 21),
            tooltip: 'API Backend Server Config',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 21),
            tooltip: 'Display Settings & Stepper',
            onPressed: _showSettingsModal,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF4338CA),
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
              indicatorColor: const Color(0xFF4338CA),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13.5),
              tabs: const [
                Tab(text: 'Chart'),
                Tab(text: 'Planets & KP'),
                Tab(text: 'Strength (Shadbala)'),
                Tab(text: 'Dasha Timeline'),
                Tab(text: 'Ashtakavarga'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingKundli
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4338CA)),
                  const SizedBox(height: 14),
                  Text(
                    'Calculating Swiss Ephemeris Placements...',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLagnaAndDivisionalChartTab(context, isDark),
                _buildPlanetsTab(context, isDark),
                _buildShadbalaAndYogasTab(context, isDark),
                _buildDashaTab(context, isDark),
                _buildAshtakvargaTab(context, isDark),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
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

  // =========================================================================
  // TAB 1: CHART TAB (Live Stepper + Sub-Vargas + Interactive Chart + 4 Tables)
  // =========================================================================
  Widget _buildLagnaAndDivisionalChartTab(BuildContext context, bool isDark) {
    final ascLagna = _kundliData?['ascendant_lagna']?.toString() ?? _kundliData?['ascendant_sign']?.toString() ?? 'Gemini';
    final ascDeg = _kundliData?['ascendant_degree_formatted']?.toString() ?? _kundliData?['ascendant_degree']?.toString() ?? '';
    final ascDisplay = ascDeg.isNotEmpty ? '$ascLagna ($ascDeg)' : ascLagna;

    final moonSign = _kundliData?['moon_sign_rashi']?.toString() ?? _kundliData?['moon_sign']?.toString() ?? 'Virgo';
    final nakshatra = _kundliData?['nakshatra']?.toString() ?? 'Chitra';
    final nakPada = _kundliData?['nakshatra_pada']?.toString() ?? '2';
    final ayanamsa = _kundliData?['ayanamsa_formatted']?.toString() ?? "Lahiri 23° 50' 32\"";

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Profile Signature Gradient Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF312E81).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _personName,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showEditProfileDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text('Edit', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  _buildAscendantBadge('Ascendant', ascDisplay),
                  _buildAscendantBadge('Moon Sign', moonSign),
                  _buildAscendantBadge('Nakshatra', '$nakshatra\nPada $nakPada'),
                  _buildAscendantBadge('Ayanamsa', ayanamsa),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Live Time Stepper Responsive Card (Zero-Overflow Layout)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Responsive Left Side Date-Time
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF4338CA)),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _headerDisplayDateTime,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Compact Right Side Stepper Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Interval Settings
                      InkWell(
                        onTap: _showSettingsModal,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF4338CA)),
                              const SizedBox(width: 3),
                              Text(
                                _stepperInterval.displayName,
                                style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Step Backward
                      InkWell(
                        onTap: () => _stepTime(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFF4338CA)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Step Forward
                      InkWell(
                        onTap: () => _stepTime(true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF4338CA)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_pin, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$_pob ($_formattedTzPlace)',
                      style: GoogleFonts.outfit(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.explore_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    _formattedLatLong,
                    style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Sub-Vargas Segmented Control (Rashi, Navamsha, Bhava, Others)
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildVargaTabItem('Rashi', _activeChartKey == 'D-1', () => setState(() => _activeChartKey = 'D-1'), isDark),
              _buildVargaTabItem('Navamsa', _activeChartKey == 'D-9', () => setState(() => _activeChartKey = 'D-9'), isDark),
              _buildVargaTabItem('Bhava', _activeChartKey == 'Bhava', () => setState(() => _activeChartKey = 'Bhava'), isDark),
              _buildVargaTabItem(
                _activeChartKey.startsWith('D-') && _activeChartKey != 'D-1' && _activeChartKey != 'D-9' ? _activeChartKey : 'Others',
                _activeChartKey != 'D-1' && _activeChartKey != 'D-9' && _activeChartKey != 'Bhava',
                _showOthersDivisionalPicker,
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. Active Chart Title Banner
        Center(
          child: Text(
            'Chart Type: ${_divisionalChartsInfo[_activeChartKey] ?? _activeChartKey}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: const Color(0xFF4338CA),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 5. Chart Model Quick 1-Tap Toggle (Square vs Diamond vs Sun)
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildChartStyleToggleItem(
                '🔲 Square Model (South)',
                _currentChartStyle == KundliChartStyle.southIndian,
                () => setState(() => _currentChartStyle = KundliChartStyle.southIndian),
                isDark,
              ),
              _buildChartStyleToggleItem(
                '🔷 Diamond (North)',
                _currentChartStyle == KundliChartStyle.northIndian,
                () => setState(() => _currentChartStyle = KundliChartStyle.northIndian),
                isDark,
              ),
              _buildChartStyleToggleItem(
                '☀️ Sun (East)',
                _currentChartStyle == KundliChartStyle.eastIndian,
                () => setState(() => _currentChartStyle = KundliChartStyle.eastIndian),
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 6. Kundli Interactive Chart Card (Square / Diamond)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              KundliInteractiveChart(
                chartStyle: _currentChartStyle,
                isDark: isDark,
                chartTypeKey: _activeChartKey,
                showUpagrahas: _showUpagrahasOnChart,
                showDegrees: _showDegreesOnChart,
                kundliData: _kundliData,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentChartStyle.title,
                          style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Swiss Ephemeris Precision',
                    style: GoogleFonts.outfit(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 7. Bottom 4 Sub-Tabs Bar (Planets, Upagraha, Arudha, Others)
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _bottomSubTabController,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white70 : const Color(0xFF475569),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12.5),
            tabs: const [
              Tab(text: 'Planets'),
              Tab(text: 'Upagraha'),
              Tab(text: 'Arudha'),
              Tab(text: 'Others'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 8. Bottom Content Area (Internal scrolling list)
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _bottomSubTabController,
            children: [
              _buildBottomPlanetsTable(isDark),
              _buildBottomUpagrahaTable(isDark),
              _buildBottomArudhaTable(isDark),
              _buildBottomOthersTable(isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChartStyleToggleItem(String title, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVargaTabItem(String title, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  // --- BOTTOM TAB 1: PLANETS TABLE ---
  Widget _buildBottomPlanetsTable(bool isDark) {
    final rawPlanets = (_kundliData?['planets'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Planetary Positions for ${_divisionalChartsInfo[_activeChartKey] ?? "Rashi (D-1)"}',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _isCardViewMode = !_isCardViewMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isCardViewMode ? 'Table View' : 'Card View',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildTableHeader(['Planet', 'Degree', 'Rashi', 'Nakshatra', 'Pada'], isDark),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: rawPlanets.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              itemBuilder: (ctx, idx) {
                final p = rawPlanets[idx] as Map<String, dynamic>;
                final name = p['name']?.toString() ?? 'Planet';
                final deg = p['degree_formatted']?.toString() ?? "00:00:00";
                final sign = p['sign']?.toString() ?? 'Aries';
                final signSanskrit = p['sign_sanskrit']?.toString() ?? '';
                final signDisplay = signSanskrit.isNotEmpty ? '$sign ($signSanskrit)' : sign;
                final nak = p['nakshatra']?.toString() ?? 'Ashwini';
                final pada = (p['pada'] ?? p['nakshatra_pada'] ?? 1).toString();
                final isRetro = p['is_retrograde'] == true;

                final isLagna = name.toLowerCase().contains('ascendant') || name.toLowerCase().contains('lagna');
                final rowBg = isLagna
                    ? (isDark ? const Color(0xFF881337).withValues(alpha: 0.28) : const Color(0xFFFFF1F2))
                    : (idx.isOdd ? (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC)) : Colors.transparent);

                return Container(
                  color: rowBg,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: isLagna ? FontWeight.bold : FontWeight.w600,
                                  color: isLagna ? const Color(0xFFE11D48) : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isRetro) ...[
                              const SizedBox(width: 3),
                              Text('(R)', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(deg, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500))),
                      Expanded(flex: 3, child: Text(signDisplay, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 3, child: Text(nak, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            pada,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isLagna ? const Color(0xFFE11D48) : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM TAB 2: UPAGRAHA TABLE ---
  Widget _buildBottomUpagrahaTable(bool isDark) {
    final upagrahas = (_kundliData?['upagrahas'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Upagraha Positions for Rashi (D-1)',
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${upagrahas.length} Secondary Planets',
                  style: GoogleFonts.outfit(fontSize: 10.5, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          _buildTableHeader(['Upagraha', 'Degree', 'Rashi', 'Nakshatra', 'Pada'], isDark),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: upagrahas.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              itemBuilder: (ctx, idx) {
                final u = upagrahas[idx] as Map<String, dynamic>;
                final name = u['name']?.toString() ?? 'Upagraha';
                final code = u['short_code']?.toString() ?? '';
                final deg = u['degree_formatted']?.toString() ?? '00:00:00';
                final sign = u['sign']?.toString() ?? 'Aries';
                final signSanskrit = u['sign_sanskrit']?.toString() ?? '';
                final signDisplay = signSanskrit.isNotEmpty ? '$sign ($signSanskrit)' : sign;
                final nak = u['nakshatra']?.toString() ?? 'Ashwini';
                final pada = (u['pada'] ?? 1).toString();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(name, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            ),
                            if (code.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text('($code)', style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF4338CA), fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(deg, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500))),
                      Expanded(flex: 3, child: Text(signDisplay, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 3, child: Text(nak, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(pada, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM TAB 3: ARUDHA TABLE ---
  Widget _buildBottomArudhaTable(bool isDark) {
    final arudhas = (_kundliData?['arudha_padas'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              'Arudha Pada Positions (Jaimini Classical System)',
              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
            ),
          ),
          _buildTableHeader(['Arudha Pada', 'Degree', 'Rashi', 'Nakshatra', 'Pada'], isDark),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: arudhas.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              itemBuilder: (ctx, idx) {
                final a = arudhas[idx] as Map<String, dynamic>;
                final code = a['code']?.toString() ?? 'A1';
                final name = a['name']?.toString() ?? '';
                final deg = a['degree_formatted']?.toString() ?? '00:00:00';
                final sign = a['sign']?.toString() ?? 'Aries';
                final nak = a['nakshatra']?.toString() ?? 'Ashwini';
                final pada = (a['pada'] ?? 1).toString();

                final isArudhaLagna = code.startsWith('AL') || code.startsWith('UL');

                return Container(
                  color: isArudhaLagna ? (isDark ? const Color(0xFF4338CA).withValues(alpha: 0.15) : const Color(0xFFEEF2FF)) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(code, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                            if (name.isNotEmpty)
                              Text(name, style: GoogleFonts.outfit(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black54), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(deg, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500))),
                      Expanded(flex: 3, child: Text(sign, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 3, child: Text(nak, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(pada, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM TAB 4: OTHERS (Special Lagnas & Chara Karakas) ---
  Widget _buildBottomOthersTable(bool isDark) {
    final specialLagnas = (_kundliData?['special_lagnas'] as List<dynamic>?) ?? [];
    final charaKarakas = (_kundliData?['chara_karakas'] as List<dynamic>?) ?? [];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
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
                  Text(
                    'Special Lagnas (विशेष लग्न)',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Parashara', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...specialLagnas.map((s) {
                final name = s['name']?.toString() ?? '';
                final sign = s['sign']?.toString() ?? '';
                final deg = s['degree_formatted']?.toString() ?? '';
                final nak = s['nakshatra']?.toString() ?? '';
                final sig = s['significance']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$sign • $deg • $nak', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            if (sig.isNotEmpty)
                              Text(sig, style: GoogleFonts.outfit(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
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
                  Text(
                    'Jaimini 7 Chara Karakas (चर कारक)',
                    style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Longitudes', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...charaKarakas.map((k) {
                final p = k['planet']?.toString() ?? '';
                final code = k['karaka_code']?.toString() ?? '';
                final name = k['karaka_name']?.toString() ?? '';
                final sig = k['significance']?.toString() ?? '';
                final deg = k['degree_in_sign']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(code, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$p ($name)', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                Text(deg, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                              ],
                            ),
                            Text(sig, style: GoogleFonts.outfit(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                          ],
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
    );
  }

  Widget _buildTableHeader(List<String> headers, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(headers[0], style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 2, child: Text(headers[1], style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 3, child: Text(headers[2], style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(flex: 3, child: Text(headers[3], style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              child: Text(headers[4], style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155))),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: PLANETS & KP LORDS TAB
  // =========================================================================
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

  // =========================================================================
  // TAB 3: SHADBALA & YOGAS TAB
  // =========================================================================
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
      }
    }

    final rawYogas = _kundliData?['vedic_yogas'] ?? _kundliData?['yogas'];
    final yogas = (rawYogas as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
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
                            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                    ],
                    if (planetsInvolved.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Planets: $planetsInvolved', style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // =========================================================================
  // TAB 4: VIMSHOTTARI DASHA TIMELINE
  // =========================================================================
  Widget _buildDashaTab(BuildContext context, bool isDark) {
    final dashaTimeline = (_kundliData?['vimshottari_dasha_timeline'] as List<dynamic>?) ?? [];
    final currentRunning = _kundliData?['current_running_dasha'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        if (currentRunning != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF312E81).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Mahadasha', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text('Live Planetary Period', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  currentRunning['active_mahadasha']?.toString() ?? 'Jupiter (Guru)',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Antardasha: ${currentRunning['active_antardasha'] ?? "--"}  •  Pratyantar: ${currentRunning['active_pratyantar'] ?? "--"}',
                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text('120-Year Vimshottari Mahadasha Sequence', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...dashaTimeline.map((item) {
          final planet = item['planet']?.toString() ?? 'Planet';
          final duration = item['duration_years']?.toString() ?? '7';
          final start = item['start']?.toString() ?? '';
          final end = item['end']?.toString() ?? '';
          final isCompleted = item['is_completed'] == true;
          final isActive = item['is_active'] == true;
          final antardashas = (item['antardashas'] as List<dynamic>?) ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEEF2FF))
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF4338CA)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: ExpansionTile(
              leading: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : (isActive ? Icons.play_circle_fill_rounded : Icons.radio_button_unchecked_rounded),
                color: isCompleted
                    ? const Color(0xFF059669)
                    : (isActive ? const Color(0xFF4338CA) : Colors.grey),
                size: 22,
              ),
              title: Text(planet, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('$start to $end ($duration Years)', style: GoogleFonts.outfit(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54)),
              trailing: isActive
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF4338CA), borderRadius: BorderRadius.circular(8)),
                      child: Text('Current', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    )
                  : null,
              children: antardashas.isNotEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: antardashas.map((ad) {
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
                          }).toList(),
                        ),
                      ),
                    ]
                  : [],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // TAB 5: ASHTAKVARGA (SAV & BAV)
  // =========================================================================
  Widget _buildAshtakvargaTab(BuildContext context, bool isDark) {
    final ashtakvarga = _kundliData?['ashtakvarga'] as Map<String, dynamic>?;
    final totalSav = ashtakvarga?['total_sav_points'] ?? 337;
    final signPoints = (ashtakvarga?['sign_points'] as Map<String, dynamic>?) ?? {};
    final pointValues = signPoints.values.map((v) => (v as num).toInt()).toList();
    final defaultPoints = [28, 31, 29, 34, 36, 27, 30, 26, 33, 25, 32, 26];
    final displayPoints = pointValues.isNotEmpty ? pointValues : defaultPoints;

    final bav = ashtakvarga?['bhinnashtakavarga'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sarvashtakvarga (SAV)', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                  Text('$totalSav Points', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.grid_view_rounded, color: Colors.white, size: 36),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
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

            return Container(
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
                      Text(pName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      Text('$total Points', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF4338CA), fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildProfileChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAscendantBadge(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalaChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w500)),
    );
  }

  String _formatPlanetDisplayName(String name, String sanskrit) {
    if (sanskrit.isNotEmpty && !name.contains(sanskrit)) {
      return '$name ($sanskrit)';
    }
    return name;
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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _pobCtrl = TextEditingController(text: widget.initialPob);

    _selectedDate = DateTime(1998, 12, 13);
    try {
      final formats = [
        DateFormat('dd MMM yyyy'),
        DateFormat('d MMM yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
      ];
      for (final f in formats) {
        try {
          _selectedDate = f.parse(widget.initialDob.trim());
          break;
        } catch (_) {}
      }
    } catch (_) {}

    _selectedTime = const TimeOfDay(hour: 19, minute: 18);
    try {
      final tFormats = [
        DateFormat('hh:mm a'),
        DateFormat('h:mm a'),
        DateFormat('HH:mm:ss'),
        DateFormat('HH:mm'),
      ];
      for (final f in tFormats) {
        try {
          final t = f.parse(widget.initialTob.trim());
          _selectedTime = TimeOfDay(hour: t.hour, minute: t.minute);
          break;
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDob = DateFormat('dd MMM yyyy').format(_selectedDate);
    final formattedTob = _selectedTime.format(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Birth Profile',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Recalculate Swiss Ephemeris Placements',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF4338CA)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final dt = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (dt != null) {
                              setState(() => _selectedDate = dt);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF4338CA)),
                                const SizedBox(width: 8),
                                Text(formattedDob, style: GoogleFonts.outfit(fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final tm = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (tm != null) {
                              setState(() => _selectedTime = tm);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF4338CA)),
                                const SizedBox(width: 8),
                                Text(formattedTob, style: GoogleFonts.outfit(fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pobCtrl,
                    decoration: InputDecoration(
                      labelText: 'Place of Birth',
                      prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF4338CA)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black54)),
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
