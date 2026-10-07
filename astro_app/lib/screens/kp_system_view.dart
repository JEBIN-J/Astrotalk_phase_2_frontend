import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../widgets/kundli_chart_painter.dart';
import 'planetary_transit_view.dart';
class KpSystemView extends StatefulWidget {
  final String personName;
  final String dateOfBirth; // YYYY-MM-DD
  final String timeOfBirth; // HH:mm
  final String placeOfBirth;
  final double latitude;
  final double longitude;
  final double timezone;
  final KundliChartStyle chartStyle;
  final bool isDark;
  final VoidCallback? onEditProfile;
  final bool showUpagrahas;
  final bool showDegrees;

  const KpSystemView({
    super.key,
    required this.personName,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.chartStyle = KundliChartStyle.southIndian,
    this.isDark = false,
    this.onEditProfile,
    this.showUpagrahas = false,
    this.showDegrees = true,
  });

  @override
  State<KpSystemView> createState() => _KpSystemViewState();
}

class _KpSystemViewState extends State<KpSystemView> {
  String _formatDMS(double decimalDegrees) {
    if (decimalDegrees == 0.0) return '';
    int d = decimalDegrees.floor();
    double minDouble = (decimalDegrees - d) * 60;
    int m = minDouble.floor();
    double s = (minDouble - m) * 60;
    return '$d°$m\'${s.toStringAsFixed(2)}"';
  }

  static const Map<String, String> _ayanamsaNames = {
    'LAHIRI': 'Lahiri (Chitrapaksha)',
    'BV_RAMAN': 'B.V. Raman',
    'KP_OLD': 'Krishnamurti (KP Old)',
    'SRI_YUKTESWAR': 'Sri Yukteswar',
    'DE_LUCE': 'De Luce',
    'USHA_SHASHI': 'Usha-Shashi',
    'DJWHAL_KHOOL': 'Djwhal Khool',
    'JN_BHASIN': 'J.N. Bhasin',
    'FAGAN_BRADLEY': 'Fagan-Bradley',
    'TROPICAL': 'Tropical (Sayana)',
    'KP_NEW': 'Krishnamurti (KP New)',
    'KP_STRAIGHT_LINE': 'KP Straight Line',
    'KHULLAR': 'Khullar',
    'CHANDRA_HARI': 'Chandra Hari',
  };

  static const List<String> subSections = [
    'KP Chart',
    'Dasha',
    'Significators',
    'KP Aspects',
    'Nakshatra Nadi',
    '4-Step',
    'Angular Distance',
    'Planetary Transit',
  ];

  Map<String, double> _ayanamsaOptions = {
    'KP_NEW': 0.0,
    'LAHIRI': 0.0,
    'BV_RAMAN': 0.0,
    'KP_OLD': 0.0,
    'SRI_YUKTESWAR': 0.0,
    'DE_LUCE': 0.0,
    'USHA_SHASHI': 0.0,
    'DJWHAL_KHOOL': 0.0,
    'JN_BHASIN': 0.0,
    'FAGAN_BRADLEY': 0.0,
    'TROPICAL': 0.0,
    'KP_STRAIGHT_LINE': 0.0,
    'KHULLAR': 0.0,
    'CHANDRA_HARI': 0.0,
  };

  String _selectedAyanamsa = 'KP_NEW';
  int _activeSectionIndex = 0;

  // KP Chart specific state
  String _activeChartType = 'D-1'; // 'Bhava', 'D-1', 'D-9'
  late KundliChartStyle _activeChartStyle;

  // Significators specific state
  int _significatorSubTabIndex = 0; // 0: Planet, 1: House

  // KP Aspects specific state
  int _aspectSubTabIndex = 0; // 0: Planets, 1: KP Cusp

  // 4-Step specific state
  int _fourStepSubTabIndex = 0; // 0: Planets, 1: Cusps

  // Angular Distance specific state
  int _angularDistanceSubTabIndex = 0; // 0: Natal->Natal, 1: Natal->Transit

  // Expanded Dasha state
  final Set<String> _expandedMahadashas = {};
  final Set<String> _expandedAntardashas = {};

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _kpData;

  @override
  void initState() {
    super.initState();
    _activeChartStyle = widget.chartStyle;
    _fetchAyanamsas();
    _fetchKpData();
  }

  Future<void> _fetchAyanamsas() async {
    final opts = await AstroApiService.getAyanamsaDegrees(
      dateOfBirth: widget.dateOfBirth,
      timeOfBirth: widget.timeOfBirth,
      latitude: widget.latitude,
      longitude: widget.longitude,
      timezone: widget.timezone,
    );
    if (mounted && opts.isNotEmpty) {
      setState(() {
        _ayanamsaOptions = opts;
      });
    }
  }

  @override
  void didUpdateWidget(covariant KpSystemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsFetch = false;
    if (oldWidget.personName != widget.personName ||
        oldWidget.dateOfBirth != widget.dateOfBirth ||
        oldWidget.timeOfBirth != widget.timeOfBirth ||
        oldWidget.placeOfBirth != widget.placeOfBirth ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.timezone != widget.timezone) {
      needsFetch = true;
    }

    if (widget.showUpagrahas &&
        _kpData != null &&
        _kpData!['upagrahas'] == null) {
      needsFetch = true;
    }

    if (needsFetch) {
      _fetchKpData();
    }
  }

  Future<void> _fetchKpData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AstroApiService.getKpSystemData(
        name: widget.personName.isNotEmpty ? widget.personName : 'User',
        dateOfBirth: widget.dateOfBirth,
        timeOfBirth: widget.timeOfBirth,
        placeOfBirth: widget.placeOfBirth,
        latitude: widget.latitude,
        longitude: widget.longitude,
        timezone: widget.timezone,
        ayanamsa: _selectedAyanamsa,
      );

      if (mounted) {
        setState(() {
          _kpData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to calculate the chart for the selected birth details. Please verify the birth time and location.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return ListView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Sub-Sections Navigation Pills
        _buildSubSectionSelector(isDark),
        SizedBox(height: 16.h),

        // 2. Main Content based on active section
        if (_isLoading)
          _buildLoadingView(isDark)
        else if (_errorMessage != null)
          _buildErrorView(isDark)
        else if (_kpData == null)
          _buildEmptyView(isDark)
        else
          _buildActiveSectionContent(isDark),
      ],
    );
  }

  // =========================================================================
  // 1. PROFILE HEADER
  // =========================================================================
  Widget _buildProfileHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFF4338CA).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.calculate_rounded,
              color: isDark ? Colors.white : const Color(0xFF713F12),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.personName.isNotEmpty
                      ? widget.personName
                      : 'User Horoscope',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${widget.dateOfBirth} | ${widget.timeOfBirth} | ${widget.placeOfBirth}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onEditProfile != null)
            IconButton(
              icon: Icon(
                Icons.edit_calendar_rounded,
                color: const Color(0xFF4338CA),
                size: 20.sp,
              ),
              tooltip: 'Edit Birth Details',
              onPressed: widget.onEditProfile,
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. SUB-SECTION SELECTOR PILLS
  // =========================================================================
  Widget _buildSubSectionSelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: subSections.asMap().entries.map((entry) {
          final idx = entry.key;
          final title = entry.value;
          final isSelected = _activeSectionIndex == idx;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () => setState(() => _activeSectionIndex = idx),
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4338CA)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF4338CA,
                            ).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================================
  // 3. ACTIVE SECTION ROUTER
  // =========================================================================
  Widget _buildActiveSectionContent(bool isDark) {
    switch (_activeSectionIndex) {
      case 0:
        return _buildKpChartSection(isDark);
      case 1:
        return _buildDashaSection(isDark);
      case 2:
        return _buildSignificatorsSection(isDark);
      case 3:
        return _buildAspectsSection(isDark);
      case 4:
        return _buildNakshatraNadiSection(isDark);
      case 5:
        return _buildFourStepSection(isDark);
      case 6:
        return _buildAngularDistanceSection(isDark);
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanetaryTransitSection(isDark),
            SizedBox(height: 24.h),
            _buildKpChartSection(isDark),
          ],
        );
      default:
        return _buildKpChartSection(isDark);
    }
  }

  Widget _buildPlanetaryTransitSection(bool isDark) {
    return KpPlanetaryTransitSection(
      isDark: isDark,
      originalDateOfBirth: widget.dateOfBirth,
      originalTimeOfBirth: widget.timeOfBirth,
      originalPlaceOfBirth: widget.placeOfBirth,
      originalLatitude: widget.latitude,
      originalLongitude: widget.longitude,
      originalTimezone: widget.timezone,
      selectedAyanamsa: _selectedAyanamsa,
      onKpDataChanged: (newData) {
        if (mounted) {
          setState(() {
            _kpData = newData;
          });
        }
      },
      onResetKpData: () {
        _fetchKpData();
      },
    );
  }

  // =========================================================================
  // SECTION 1: KP CHART
  // =========================================================================
  Widget _buildKpChartSection(bool isDark) {
    final planets = (_kpData?['planets'] as List<dynamic>?) ?? [];
    final cusps = (_kpData?['bhava_cusps'] as List<dynamic>?) ?? [];
    final ayanFormatted = _kpData?['ayanamsa_formatted']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ayanamsa Dropdown Card
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18.sp,
                color: const Color(0xFF4338CA),
              ),
              SizedBox(width: 8.w),
              Text(
                'Ayanamsa:',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAyanamsa,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF4338CA),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    items: _ayanamsaOptions.keys.map((ayanKey) {
                      final name = _ayanamsaNames[ayanKey] ?? ayanKey;
                      final val = _ayanamsaOptions[ayanKey] ?? 0.0;
                      final valStr = val > 0.0 || val < 0.0
                          ? ' (${_formatDMS(val)})'
                          : '';
                      return DropdownMenuItem<String>(
                        value: ayanKey,
                        child: Text(
                          '$name$valStr',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newAyan) {
                      if (newAyan != null && newAyan != _selectedAyanamsa) {
                        setState(() => _selectedAyanamsa = newAyan);
                        _fetchKpData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (ayanFormatted.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            'Active Offset: $ayanFormatted',
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
        SizedBox(height: 14.h),

        // Chart System Model Dropdown Card
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dashboard_customize_rounded,
                size: 18.sp,
                color: const Color(0xFF4338CA),
              ),
              SizedBox(width: 8.w),
              Text(
                'Chart System Model:',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<KundliChartStyle>(
                    value: _activeChartStyle,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF4338CA),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    items: KundliChartStyle.values.map((style) {
                      return DropdownMenuItem<KundliChartStyle>(
                        value: style,
                        child: Text(
                          style.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newStyle) {
                      if (newStyle != null && newStyle != _activeChartStyle) {
                        setState(() => _activeChartStyle = newStyle);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Chart Type Selector: Rashi, Navamsa, Bhava
        Row(
          children: [
            _buildChartTypeTab('Rashi', 'D-1', isDark),
            SizedBox(width: 8.w),
            _buildChartTypeTab('Navamsa', 'D-9', isDark),
            SizedBox(width: 8.w),
            _buildChartTypeTab('Bhava', 'Bhava', isDark),
          ],
        ),
        SizedBox(height: 14.h),

        // Interactive Chart Canvas
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFF4338CA).withValues(alpha: 0.25),
            ),
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
              Text(
                _activeChartType == 'Bhava'
                    ? 'KP Bhava Chalit Chart (Placidus Cusps)'
                    : _activeChartType == 'D-9'
                    ? 'Navamsa Chart (D9)'
                    : (_kpData?['is_transit'] == true ? 'Rashi Transit Chart (D1)' : 'Rashi Natal Chart (D1)'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : const Color(0xFF713F12),
                ),
              ),
              SizedBox(height: 12.h),
              KundliInteractiveChart(
                chartStyle: _activeChartStyle,
                isDark: isDark,
                chartTypeKey: _activeChartType,
                showUpagrahas: widget.showUpagrahas,
                showDegrees: widget.showDegrees,
                showKpCusps: _activeChartType != 'D-9',
                kundliData: _kpData,
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Lower Table: Switches between Bhava Table and Planetary Table
        Builder(
          builder: (context) {
            if (_activeChartType == 'Bhava') {
              return _buildBhavaTable(cusps, isDark);
            } else {
              List<dynamic> activePlanets = planets;
              if (_activeChartType == 'D-9' &&
                  _kpData?['divisional_charts']?['D-9']?['planets'] != null) {
                activePlanets =
                    _kpData!['divisional_charts']['D-9']['planets']
                        as List<dynamic>;
              }
              return _buildPlanetaryTable(activePlanets, isDark);
            }
          },
        ),
        SizedBox(height: 24.h),

        // 5. RULING PLANETS
        if (_kpData?['ruling_planets'] != null)
          _buildRulingPlanetsSection(_kpData!['ruling_planets'], isDark),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildChartTypeTab(String label, String key, bool isDark) {
    final isSelected = _activeChartType == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeChartType = key),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4338CA)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 5. RULING PLANETS
  Widget _buildRulingPlanetsSection(Map<String, dynamic> rp, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ruling Planets (Calculated)',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            children: [
              _buildRpItem(
                'Lagna Rashi Lord',
                rp['lagna_rashi_lord']?.toString() ?? '-',
                isDark,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _buildRpItem(
                'Lagna Nakshatra Lord',
                rp['lagna_nakshatra_lord']?.toString() ?? '-',
                isDark,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _buildRpItem(
                'Moon Rashi Lord',
                rp['moon_rashi_lord']?.toString() ?? '-',
                isDark,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _buildRpItem(
                'Moon Nakshatra Lord',
                rp['moon_nakshatra_lord']?.toString() ?? '-',
                isDark,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _buildRpItem(
                'Vedic Day Lord',
                rp['day_lord']?.toString() ?? '-',
                isDark,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRpItem(
    String label,
    String value,
    bool isDark, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  // 4. PLANETARY TABLE
  Widget _buildPlanetaryTable(List<dynamic> planets, bool isDark) {
    String title = 'Planetary Coordinates & KP Lords';
    if (_activeChartType == 'D-1') {
      title = _kpData?['is_transit'] == true 
          ? 'Planetary Positions for Transit (D-1)' 
          : 'Planetary Positions for Rashi (D-1)';
    } else if (_activeChartType == 'D-9') {
      title = 'Planetary Positions for Navamsha (D-9)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF4338CA).withValues(alpha: 0.1),
              ),
              columnSpacing: 16.w,
              horizontalMargin: 12.w,
              columns: [
                DataColumn(label: Text('Planet', style: _headerStyle(isDark))),
                DataColumn(label: Text('RL', style: _headerStyle(isDark))),
                DataColumn(label: Text('NL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SSL', style: _headerStyle(isDark))),
                if (widget.showDegrees)
                  DataColumn(
                    label: Text('Degree', style: _headerStyle(isDark)),
                  ),
                DataColumn(label: Text('Rashi', style: _headerStyle(isDark))),
                DataColumn(
                  label: Text('Nakshatra', style: _headerStyle(isDark)),
                ),
                DataColumn(label: Text('Paada', style: _headerStyle(isDark))),
              ],
              rows: planets.map((p) {
                final isLagna =
                    p['name'] == 'Ascendant' || p['name'] == 'Lagna';
                final displayName = isLagna
                    ? 'Lagna'
                    : (p['table_display_name'] ?? p['name'] ?? '');
                return DataRow(
                  color: isLagna
                      ? WidgetStateProperty.all(
                          const Color(
                            0xFF4338CA,
                          ).withValues(alpha: isDark ? 0.2 : 0.08),
                        )
                      : null,
                  cells: [
                    DataCell(Text(displayName, style: _cellBoldStyle(isDark))),
                    DataCell(Text(p['rl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(Text(p['nl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(
                      Text(
                        p['sl'] ?? '-',
                        style: _cellBadgeStyle(const Color(0xFF059669)),
                      ),
                    ),
                    DataCell(
                      Text(
                        p['ssl'] ?? '-',
                        style: _cellBadgeStyle(const Color(0xFF7C3AED)),
                      ),
                    ),
                    if (widget.showDegrees)
                      DataCell(
                        Text(
                          p['degree_formatted'] ?? '',
                          style: _cellStyle(isDark),
                        ),
                      ),
                    DataCell(Text(p['sign'] ?? '', style: _cellStyle(isDark))),
                    DataCell(
                      Text(p['nakshatra'] ?? '', style: _cellStyle(isDark)),
                    ),
                    DataCell(
                      Text(
                        p['pada']?.toString() ?? '',
                        style: _cellStyle(isDark),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 5. BHAVA TABLE
  Widget _buildBhavaTable(List<dynamic> cusps, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Placidus (KP) Bhava Details',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF4338CA).withValues(alpha: 0.1),
              ),
              columnSpacing: 14.w,
              horizontalMargin: 12.w,
              columns: [
                DataColumn(label: Text('House', style: _headerStyle(isDark))),
                if (widget.showDegrees)
                  DataColumn(
                    label: Text('Cusp Deg', style: _headerStyle(isDark)),
                  ),
                DataColumn(label: Text('Rashi', style: _headerStyle(isDark))),
                DataColumn(
                  label: Text('Nakshatra', style: _headerStyle(isDark)),
                ),
                DataColumn(label: Text('Pada', style: _headerStyle(isDark))),
                DataColumn(label: Text('RL', style: _headerStyle(isDark))),
                DataColumn(label: Text('NL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SSL', style: _headerStyle(isDark))),
                DataColumn(
                  label: Text('Occupants', style: _headerStyle(isDark)),
                ),
              ],
              rows: cusps.map((c) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text('H${c['house']}', style: _cellBoldStyle(isDark)),
                    ),
                    if (widget.showDegrees)
                      DataCell(
                        Text(
                          c['degree_formatted'] ?? '',
                          style: _cellStyle(isDark),
                        ),
                      ),
                    DataCell(Text(c['sign'] ?? '', style: _cellStyle(isDark))),
                    DataCell(
                      Text(c['nakshatra'] ?? '', style: _cellStyle(isDark)),
                    ),
                    DataCell(
                      Text(
                        c['pada']?.toString() ?? '',
                        style: _cellStyle(isDark),
                      ),
                    ),
                    DataCell(Text(c['rl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(Text(c['nl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(
                      Text(
                        c['sl'] ?? '-',
                        style: _cellBadgeStyle(const Color(0xFF059669)),
                      ),
                    ),
                    DataCell(
                      Text(
                        c['ssl'] ?? '-',
                        style: _cellBadgeStyle(const Color(0xFF7C3AED)),
                      ),
                    ),
                    DataCell(
                      Text(
                        c['occupants_str'] ?? 'None',
                        style: _cellStyle(isDark),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SECTION 2: DASHA (Vimshottari Expandable Table)
  // =========================================================================
  Widget _buildDashaSection(bool isDark) {
    final dasha = _kpData?['dashas'] as Map<String, dynamic>?;
    final mahadashas = (dasha?['mahadashas'] as List<dynamic>?) ?? [];
    final birthNak = dasha?['birth_nakshatra']?.toString() ?? '';
    final birthLord = dasha?['birth_nakshatra_lord']?.toString() ?? '';
    final balance = dasha?['balance_formatted']?.toString() ?? '';

    List<DataRow> tableRows = [];
    for (var maha in mahadashas) {
      final mPlanet = maha['planet']?.toString() ?? '';
      final mStart = maha['start']?.toString() ?? '';
      final mEnd = maha['end']?.toString() ?? '';
      final isActive = maha['is_active'] == true;
      final isExpanded = _expandedMahadashas.contains(mPlanet);
      final antaras = (maha['antardashas'] as List<dynamic>?) ?? [];

      final mColor = isActive
          ? const Color(0xFF059669)
          : (isDark ? Colors.white : const Color(0xFF1E293B));

      tableRows.add(
        DataRow(
          color: WidgetStateProperty.all(
            isActive
                ? const Color(0xFF059669).withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12.r,
                    backgroundColor: isActive
                        ? const Color(0xFF059669)
                        : const Color(0xFF4338CA),
                    child: Text(
                      _getLordShort(mPlanet),
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : const Color(0xFF713F12),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$mPlanet MD',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: mColor,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(mStart, style: _cellStyle(isDark))),
            DataCell(Text(mEnd, style: _cellStyle(isDark))),
            DataCell(
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedMahadashas.remove(mPlanet);
                    } else {
                      _expandedMahadashas.add(mPlanet);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded ? 'Hide AD' : 'View AD',
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      if (isExpanded) {
        for (var anta in antaras) {
          final aPlanet = anta['planet']?.toString() ?? '';
          final aStart = anta['start']?.toString() ?? '';
          final aEnd = anta['end']?.toString() ?? '';
          final aActive = anta['is_active'] == true;

          tableRows.add(
            DataRow(
              color: WidgetStateProperty.all(
                aActive
                    ? const Color(0xFF059669).withValues(alpha: 0.05)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.black.withValues(alpha: 0.02)),
              ),
              cells: [
                DataCell(
                  Padding(
                    padding: EdgeInsets.only(left: 24.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right,
                          size: 14.sp,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '$aPlanet AD',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: aActive
                                ? const Color(0xFF059669)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    aStart,
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    aEnd,
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                DataCell(
                  aActive
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'RUNNING',
                            style: GoogleFonts.outfit(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF713F12),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(
              0xFF4338CA,
            ).withValues(alpha: isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF4338CA).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                color: const Color(0xFF4338CA),
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Birth Nakshatra: $birthNak ($birthLord) | Balance: $balance',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        Text(
          'Vimshottari Dasha Timeline',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12.h),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF4338CA).withValues(alpha: 0.1),
              ),
              dividerThickness: 0.3,
              dataRowMinHeight: 45.h,
              dataRowMaxHeight: 45.h,
              headingTextStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              columnSpacing: 24.w,
              horizontalMargin: 16.w,
              columns: [
                DataColumn(
                  label: Text('Dasha Lord', style: _headerStyle(isDark)),
                ),
                DataColumn(
                  label: Text('Start Date', style: _headerStyle(isDark)),
                ),
                DataColumn(
                  label: Text('End Date', style: _headerStyle(isDark)),
                ),
                DataColumn(label: Text('Action', style: _headerStyle(isDark))),
              ],
              rows: tableRows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignificatorsSection(bool isDark) {
    final sigs = _kpData?['significators'] as Map<String, dynamic>?;
    final planetSigs = (sigs?['planet_significators'] as List<dynamic>?) ?? [];
    final houseSigs = (sigs?['house_significators'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPillTab(
                title: 'Planet Significators',
                isSelected: _significatorSubTabIndex == 0,
                onTap: () => setState(() => _significatorSubTabIndex = 0),
                isDark: isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPillTab(
                title: 'House Significators',
                isSelected: _significatorSubTabIndex == 1,
                onTap: () => setState(() => _significatorSubTabIndex = 1),
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        if (_significatorSubTabIndex == 0) ...[
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF4338CA).withValues(alpha: 0.1),
                ),
                columnSpacing: 18.w,
                horizontalMargin: 12.w,
                columns: [
                  DataColumn(
                    label: Text('Planet', style: _headerStyle(isDark)),
                  ),
                  DataColumn(
                    label: Text(
                      'Level-A (NL Occ)',
                      style: _headerStyle(isDark),
                    ),
                  ),
                  DataColumn(
                    label: Text('Level-B (Occ)', style: _headerStyle(isDark)),
                  ),
                  DataColumn(
                    label: Text(
                      'Level-C (NL Own)',
                      style: _headerStyle(isDark),
                    ),
                  ),
                  DataColumn(
                    label: Text('Level-D (Own)', style: _headerStyle(isDark)),
                  ),
                  DataColumn(
                    label: Text('All Houses', style: _headerStyle(isDark)),
                  ),
                ],
                rows: planetSigs.map((ps) {
                  final a =
                      (ps['level_a'] as List<dynamic>?)?.join(', ') ?? '-';
                  final b =
                      (ps['level_b'] as List<dynamic>?)?.join(', ') ?? '-';
                  final c =
                      (ps['level_c'] as List<dynamic>?)?.join(', ') ?? '-';
                  final d =
                      (ps['level_d'] as List<dynamic>?)?.join(', ') ?? '-';
                  final all =
                      (ps['all_significators'] as List<dynamic>?)?.join(', ') ??
                      '-';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(ps['planet'] ?? '', style: _cellBoldStyle(isDark)),
                      ),
                      DataCell(
                        Text(a.isEmpty ? '-' : a, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(b.isEmpty ? '-' : b, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(c.isEmpty ? '-' : c, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(d.isEmpty ? '-' : d, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(
                          all,
                          style: _cellBadgeStyle(const Color(0xFF4338CA)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ] else ...[
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF4338CA).withValues(alpha: 0.1),
                ),
                columnSpacing: 18.w,
                horizontalMargin: 12.w,
                columns: [
                  DataColumn(label: Text('House', style: _headerStyle(isDark))),
                  DataColumn(
                    label: Text(
                      'Level-1 (In Star of Occ)',
                      style: _headerStyle(isDark),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Level-2 (Occupants)',
                      style: _headerStyle(isDark),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Level-3 (In Star of Lord)',
                      style: _headerStyle(isDark),
                    ),
                  ),
                  DataColumn(
                    label: Text('Level-4 (Lord)', style: _headerStyle(isDark)),
                  ),
                  DataColumn(
                    label: Text(
                      'All Significators',
                      style: _headerStyle(isDark),
                    ),
                  ),
                ],
                rows: houseSigs.map((hs) {
                  final l1 =
                      (hs['level_1'] as List<dynamic>?)?.join(', ') ?? '-';
                  final l2 =
                      (hs['level_2'] as List<dynamic>?)?.join(', ') ?? '-';
                  final l3 =
                      (hs['level_3'] as List<dynamic>?)?.join(', ') ?? '-';
                  final l4 =
                      (hs['level_4'] as List<dynamic>?)?.join(', ') ?? '-';
                  final all =
                      (hs['all_planets'] as List<dynamic>?)?.join(', ') ?? '-';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          'House ${hs['house']}',
                          style: _cellBoldStyle(isDark),
                        ),
                      ),
                      DataCell(
                        Text(l1.isEmpty ? '-' : l1, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(l2.isEmpty ? '-' : l2, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(l3.isEmpty ? '-' : l3, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(l4.isEmpty ? '-' : l4, style: _cellStyle(isDark)),
                      ),
                      DataCell(
                        Text(
                          all,
                          style: _cellBadgeStyle(const Color(0xFF059669)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // SECTION 4: KP ASPECTS (Planets & KP Cusp)
  // =========================================================================

  Widget _buildPlanetAspectsTable(
    List<dynamic> planets,
    List<dynamic> aspects,
    bool isDark,
  ) {
    if (planets.isEmpty) return _buildInfoCard('No planets available.', isDark);
    if (aspects.isEmpty)
      return _buildInfoCard('No major planetary aspects within orb.', isDark);

    final planetNames = planets.map((p) => p['name'].toString()).toList();

    // Create a matrix: Map<RowPlanet, Map<ColPlanet, aspectData>>
    Map<String, Map<String, dynamic>> aspectMatrix = {};
    for (var p in planetNames) {
      aspectMatrix[p] = {};
    }

    for (var asp in aspects) {
      String p1 = asp['p1_name'].toString();
      String p2 = asp['p2_name'].toString();
      if (planetNames.contains(p1) && planetNames.contains(p2)) {
        aspectMatrix[p1]![p2] = asp;
        aspectMatrix[p2]![p1] = asp; // Mirror
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky First Column
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 1.w,
                ),
              ),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF4338CA).withValues(alpha: 0.1),
              ),
              dividerThickness: 0.3,
              dataRowMinHeight: 50.h,
              dataRowMaxHeight: 50.h,
              columnSpacing: 10.w,
              horizontalMargin: 12.w,
              columns: [
                DataColumn(label: Text('Planet', style: _headerStyle(isDark))),
              ],
              rows: planetNames.map((pName) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(_getLordShort(pName), style: _cellBoldStyle(isDark)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Scrollable Matrix Body
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF4338CA).withValues(alpha: 0.1),
                ),
                dividerThickness: 0.3,
                dataRowMinHeight: 50.h,
                dataRowMaxHeight: 50.h,
                columnSpacing: 20.w,
                horizontalMargin: 12.w,
                columns: planetNames.map((pName) {
                  return DataColumn(
                    label: Center(
                      child: Text(
                        _getLordShort(pName),
                        style: _headerStyle(isDark),
                      ),
                    ),
                  );
                }).toList(),
                rows: planetNames.map((rowP) {
                  return DataRow(
                    cells: planetNames.map((colP) {
                      if (rowP == colP) {
                        return DataCell(
                          Center(child: Text('-', style: _cellStyle(isDark))),
                        );
                      }
                      final asp = aspectMatrix[rowP]?[colP];
                      if (asp == null) {
                        return DataCell(
                          Center(child: Text('', style: _cellStyle(isDark))),
                        );
                      }

                      String shortAsp =
                          asp['short_name']?.toString() ??
                          asp['aspect_name']?.toString() ??
                          '';
                      if (shortAsp.length > 4)
                        shortAsp = shortAsp.substring(0, 4);

                      String orbText = asp['strength'] != null
                          ? '(${asp['orb']} | ${asp['strength']})'
                          : '(${asp['orb']}°)';

                      final isHarmonious =
                          asp['nature']?.toString().toLowerCase().contains(
                            'harmonious',
                          ) ??
                          false;
                      final color = isHarmonious
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626);

                      return DataCell(
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                shortAsp,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                orbText,
                                style: GoogleFonts.outfit(
                                  fontSize: 9.sp,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectsSection(bool isDark) {
    final planets = (_kpData?['planets'] as List<dynamic>?) ?? [];
    final cusps = (_kpData?['bhava_cusps'] as List<dynamic>?) ?? [];

    final transitPlanets =
        (_kpData?['transit_planets'] as List<dynamic>?) ?? [];
    final transitPlanetAspectsList =
        (_kpData?['transit_planet_aspects'] as List<dynamic>?) ?? [];
    final transitCuspAspectsList =
        (_kpData?['transit_cusp_aspects'] as List<dynamic>?) ?? [];

    Map<String, double> longitudes = {};
    for (var p in planets) {
      String pName = p['name']?.toString() ?? '';
      longitudes[pName] = (p['longitude'] as num?)?.toDouble() ?? 0.0;
    }
    for (var c in cusps) {
      String cName = c['house']?.toString() ?? c['cusp']?.toString() ?? '';
      longitudes[cName] = (c['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    Map<String, double> transitLongitudes = {};
    for (var tp in transitPlanets) {
      String pName = tp['name']?.toString() ?? '';
      transitLongitudes[pName] = (tp['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    final colNamesPlanet = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Uranus',
      'Neptune',
      'Pluto',
    ];
    final rowNamesPlanet = [
      'Ascendant',
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Rahu',
      'Ketu',
      'Uranus',
      'Neptune',
      'Pluto',
    ];
    final rowNamesTransitPlanet = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Rahu',
      'Ketu',
      'Uranus',
      'Neptune',
      'Pluto',
    ];
    final colNamesCusp = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
    ];
    final rowNamesCusp = rowNamesPlanet.where((p) => p != 'Ascendant').toList();

    final planetAspects =
        (_kpData?['aspects']?['planet_aspects'] as List<dynamic>?) ?? [];
    final cuspAspects =
        (_kpData?['aspects']?['cusp_aspects'] as List<dynamic>?) ?? [];

    Map<String, Map<String, dynamic>> planetAspectMatrix = {};
    for (var asp in planetAspects) {
      String p1 = asp['planet_1']?.toString() ?? '';
      String p2 = asp['planet_2']?.toString() ?? '';
      if (!planetAspectMatrix.containsKey(p1)) planetAspectMatrix[p1] = {};
      if (!planetAspectMatrix.containsKey(p2)) planetAspectMatrix[p2] = {};
      planetAspectMatrix[p1]![p2] = asp;
      planetAspectMatrix[p2]![p1] = asp;
    }

    Map<String, Map<String, dynamic>> cuspAspectMatrix = {};
    for (var asp in cuspAspects) {
      String p = asp['planet']?.toString() ?? '';
      String c = asp['cusp_house']?.toString() ?? '';
      if (!cuspAspectMatrix.containsKey(p)) cuspAspectMatrix[p] = {};
      cuspAspectMatrix[p]![c] = asp;
    }

    Map<String, Map<String, dynamic>> transitPlanetMatrix = {};
    for (var asp in transitPlanetAspectsList) {
      String tp = asp['transit_planet']?.toString() ?? '';
      String np = asp['natal_planet']?.toString() ?? '';
      if (!transitPlanetMatrix.containsKey(tp)) transitPlanetMatrix[tp] = {};
      transitPlanetMatrix[tp]![np] = asp;
    }

    Map<String, Map<String, dynamic>> transitCuspMatrix = {};
    for (var asp in transitCuspAspectsList) {
      String tp = asp['transit_planet']?.toString() ?? '';
      String c = asp['natal_cusp']?.toString() ?? '';
      if (!transitCuspMatrix.containsKey(tp)) transitCuspMatrix[tp] = {};
      transitCuspMatrix[tp]![c] = asp;
    }

    Color headerBgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);
    Color borderColor = isDark ? Colors.white24 : Colors.black12;

    String _getCuspLabel(String c) {
      switch (c) {
        case '1':
          return 'ASC';
        case '2':
          return 'II';
        case '3':
          return 'III';
        case '4':
          return 'IV';
        case '5':
          return 'V';
        case '6':
          return 'VI';
        case '7':
          return 'VII';
        case '8':
          return 'VIII';
        case '9':
          return 'IX';
        case '10':
          return 'X';
        case '11':
          return 'XI';
        case '12':
          return 'XII';
        default:
          return c;
      }
    }

    Widget buildMatrix(
      List<String> rNames,
      List<String> cNames,
      Map<String, Map<String, dynamic>> matrix,
      bool isCusp,
      int mode,
    ) {
      // mode 0 = Natal Pl -> Natal Pl
      // mode 1 = Natal Pl -> Natal Cusp
      // mode 2 = Transit Pl -> Natal Cusp
      // mode 3 = Natal Pl -> Transit Pl

      return Container(
        margin: EdgeInsets.only(top: 14.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 60.w,
                  height: 48.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                          ? const Color(0xFF78350F)
                          : const Color(0xFFFEF08A),
                    border: Border(
                      right: BorderSide(color: borderColor),
                      bottom: BorderSide(color: borderColor),
                    ),
                  ),
                  child: Text(
                    mode == 2 ? 'Tr.Planet' : 'Planet',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                      color: isDark ? Colors.white : const Color(0xFF713F12),
                    ),
                  ),
                ),
                ...rNames.map((rName) {
                  return Container(
                    width: 60.w,
                    height: 48.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF78350F)
                          : const Color(0xFFFEF08A),
                      border: Border(
                        right: BorderSide(color: borderColor),
                        bottom: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Text(
                      rName == 'Ascendant' ? 'Lagna' : _getLordShort(rName),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: isDark ? Colors.white : const Color(0xFF713F12),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cNames.map((cName) {
                    return Column(
                      children: [
                        Container(
                          width: 60.w,
                          height: 48.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                          ? const Color(0xFF78350F)
                          : const Color(0xFFFEF08A),
                            border: Border(
                              right: BorderSide(color: borderColor),
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Text(
                            isCusp
                                ? _getCuspLabel(cName)
                                : (cName == 'Ascendant' ? 'Lagna' : _getLordShort(cName)),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        ...rNames.map((rName) {
                          if (cName == rName && !isCusp && mode != 3) {
                            return Container(
                              width: 60.w,
                              height: 48.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark
                          ? const Color(0xFF78350F)
                          : const Color(0xFFFEF08A),
                                border: Border(
                                  right: BorderSide(color: borderColor),
                                  bottom: BorderSide(color: borderColor),
                                ),
                              ),
                              child: Text(
                                '0',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          bool shouldDisplay = false;
                          String shortAsp = '';
                          Color bgColor = isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white;
                          Color textColor = isDark
                              ? Colors.white54
                              : Colors.black45;

                          double colLon = 0.0;
                          double rowLon = 0.0;
                          bool hasData = false;

                          if (mode == 0) {
                            if (longitudes.containsKey(cName) &&
                                longitudes.containsKey(rName)) {
                              colLon = longitudes[cName]!;
                              rowLon = longitudes[rName]!;
                              hasData = true;
                            }
                          } else if (mode == 1) {
                            if (longitudes.containsKey(cName) &&
                                longitudes.containsKey(rName)) {
                              colLon = longitudes[cName]!;
                              rowLon = longitudes[rName]!;
                              hasData = true;
                            }
                          } else if (mode == 2) {
                            // Transit Pl -> Natal Cusp
                            if (longitudes.containsKey(cName) &&
                                transitLongitudes.containsKey(rName)) {
                              colLon = longitudes[cName]!;
                              rowLon = transitLongitudes[rName]!;
                              hasData = true;
                            }
                          } else if (mode == 3) {
                            // Natal Pl -> Transit Pl (swapped)
                            if (longitudes.containsKey(rName) &&
                                transitLongitudes.containsKey(cName)) {
                              rowLon = longitudes[rName]!;
                              colLon = transitLongitudes[cName]!;
                              hasData = true;
                            }
                          }

                          double forwardAngle = 0.0;
                          if (hasData) {
                            // mode 0: rowLon - colLon
                            // mode 1: colLon - rowLon
                            // mode 2: colLon - rowLon
                            // mode 3: colLon - rowLon
                            forwardAngle = (mode == 0 || mode == 3)
                                ? (rowLon - colLon) % 360.0
                                : (colLon - rowLon) % 360.0;
                            if (forwardAngle < 0) forwardAngle += 360.0;

                            Map<String, dynamic>? asp;
                            if (mode == 3) {
                              asp = matrix[cName]?[rName];
                            } else {
                              asp = matrix[rName]?[cName];
                            }
                            if (asp != null) {
                              String nature = asp['nature']?.toString() ?? '';
                              String aspName =
                                  asp['aspect_name']?.toString() ?? '';
                              shouldDisplay = true;

                              if (aspName == 'Conjunction')
                                shortAsp = 'Conjunction';
                              else if (aspName == 'Vigintile')
                                shortAsp = 'Vigintile';
                              else if (aspName == 'Quin-decile')
                                shortAsp = 'Quin-decile';
                              else if (aspName == 'Semi-Sextile')
                                shortAsp = 'Semi-sextile';
                              else if (aspName == 'Semi-quintile')
                                shortAsp = 'Semi-quintile';
                              else if (aspName == 'Semi-Square')
                                shortAsp = 'Semi-Square';
                              else if (aspName == 'Degrees 54')
                                shortAsp = 'Degrees 54';
                              else if (aspName == 'Sextile')
                                shortAsp = 'Sextile';
                              else if (aspName == 'Quintile')
                                shortAsp = 'Quintile';
                              else if (aspName == 'Square')
                                shortAsp = 'Square';
                              else if (aspName == 'Tredecile')
                                shortAsp = 'Tredecile';
                              else if (aspName == 'Trine')
                                shortAsp = 'Trine';
                              else if (aspName == 'Degrees 126')
                                shortAsp = 'Degrees 126';
                              else if (aspName == 'Sesquiquadrate')
                                shortAsp = 'Sesquiquadrate';
                              else if (aspName == 'Bi-quintile')
                                shortAsp = 'Bi-quintile';
                              else if (aspName == 'Quincunx')
                                shortAsp = 'Quincunx';
                              else if (aspName == 'Degree 162')
                                shortAsp = 'Degree 162';
                              else if (aspName == 'Opposition')
                                shortAsp = 'Opposition';

                              if (nature == 'Yellow') {
                                bgColor = const Color(0xFFFDE047);
                                textColor = Colors.blue[800]!;
                              } else if (nature == 'Green') {
                                bgColor = const Color(0xFF86EFAC);
                                textColor = Colors.black87;
                              } else if (nature == 'LightRed') {
                                bgColor = const Color(0xFFFCA5A5);
                                textColor = Colors.black87;
                              } else if (nature == 'Red') {
                                bgColor = const Color(0xFFEF4444);
                                textColor = Colors.white;
                              } else if (nature == 'DarkGreen') {
                                bgColor = const Color(0xFF22C55E);
                                textColor = Colors.white;
                              }
                            }
                          }

                          return Container(
                            width: 60.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border(
                                right: BorderSide(color: borderColor),
                                bottom: BorderSide(color: borderColor),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  hasData
                                      ? forwardAngle.toStringAsFixed(2)
                                      : '-',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: textColor.withOpacity(0.8),
                                    fontWeight: shouldDisplay
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (shouldDisplay)
                                  Text(
                                    shortAsp,
                                    style: GoogleFonts.inter(
                                      fontSize: 7.sp,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _aspectSubTabIndex,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white70 : Colors.indigo,
              ),
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(
                    'Aspect Planet -> Planet',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(
                    'Aspect Planet -> Cusp',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(
                    'Aspect Transit Pl. -> Natal Cusp',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(
                    'Aspect Natal Vs Transit Pl.',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _aspectSubTabIndex = val);
              },
            ),
          ),
        ),
        if (_aspectSubTabIndex == 0) ...[
          if (planetAspects.isEmpty)
            _buildInfoCard('No major planetary aspects within orb.', isDark)
          else
            buildMatrix(
              rowNamesPlanet,
              colNamesPlanet,
              planetAspectMatrix,
              false,
              0,
            ),
        ] else if (_aspectSubTabIndex == 1) ...[
          if (cuspAspects.isEmpty)
            _buildInfoCard('No cusp aspects within orb.', isDark)
          else
            buildMatrix(rowNamesCusp, colNamesCusp, cuspAspectMatrix, true, 1),
        ] else if (_aspectSubTabIndex == 2) ...[
          if (transitCuspAspectsList.isEmpty)
            _buildInfoCard('No transit cusp aspects found.', isDark)
          else
            buildMatrix(
              rowNamesTransitPlanet,
              colNamesCusp,
              transitCuspMatrix,
              true,
              2,
            ),
        ] else if (_aspectSubTabIndex == 3) ...[
          if (transitPlanetAspectsList.isEmpty)
            _buildInfoCard('No transit planet aspects found.', isDark)
          else
            buildMatrix(
              rowNamesPlanet,
              rowNamesTransitPlanet,
              transitPlanetMatrix,
              false,
              3,
            ),
        ],

        // Color Legend
        if (true) ...[
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(
                'Very Good',
                const Color(0xFF22C55E),
                Colors.white,
              ),
              _buildLegendItem('Good', const Color(0xFF86EFAC), Colors.black87),
              _buildLegendItem(
                'Mild Good',
                const Color(0xFFD1FAE5),
                Colors.black87,
              ),
              _buildLegendItem(
                'Conjunction',
                const Color(0xFFFDE047),
                Colors.blue[800]!,
              ),
              _buildLegendItem(
                'Very Evil',
                const Color(0xFFEF4444),
                Colors.white,
              ),
              _buildLegendItem(
                'Mild Evil',
                const Color(0xFFFCA5A5),
                Colors.black87,
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String text, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNakshatraNadiSection(bool isDark) {
    final nadiList = (_kpData?['nakshatra_nadi'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nakshatra Nadi Coordinates & Linkages',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Source of Truth: Real-time calculated planetary coordinates, star lords, and sub-lords.',
          style: GoogleFonts.outfit(
            fontSize: 11.sp,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        SizedBox(height: 12.h),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF4338CA).withValues(alpha: 0.1),
              ),
              dividerThickness: 0.3,
              dataRowMinHeight: 60.h,
              dataRowMaxHeight: 120.h,
              headingTextStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              columnSpacing: 24.w,
              horizontalMargin: 16.w,
              columns: [
                DataColumn(label: Text('Planet', style: _headerStyle(isDark))),
                DataColumn(
                  label: Text('Position', style: _headerStyle(isDark)),
                ),
                DataColumn(
                  label: Text('Planet (Source)', style: _headerStyle(isDark)),
                ),
                DataColumn(
                  label: Text('Nakshatra Lord', style: _headerStyle(isDark)),
                ),
                DataColumn(
                  label: Text('Sub Lord', style: _headerStyle(isDark)),
                ),
                DataColumn(
                  label: Text('Active Links', style: _headerStyle(isDark)),
                ),
              ],
              rows: nadiList.map((nadi) {
                final pName = nadi['planet'] ?? '';
                final script = nadi['nadi_script'] ?? '';
                final links = (nadi['nadi_links'] as List<dynamic>?) ?? [];

                final scriptParts = script.split(RegExp(r'\s*(?:->|→|➔)\s*'));
                final source = scriptParts.isNotEmpty ? scriptParts[0] : '--';
                final nLord = scriptParts.length > 1 ? scriptParts[1] : '--';
                final sLord = scriptParts.length > 2 ? scriptParts[2] : '--';

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12.r,
                            backgroundColor: const Color(0xFF4338CA),
                            child: Text(
                              _getLordShort(pName),
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : const Color(0xFF713F12),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(pName, style: _cellBoldStyle(isDark)),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nadi['rashi'] ?? '', style: _cellStyle(isDark)),
                          Text(
                            '${nadi['nakshatra']} (P${nadi['pada']})',
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        source,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF312E81),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        nLord,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF312E81),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        sLord,
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF312E81),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        width: 250.w,
                        child: links.isEmpty
                            ? Text('--', style: _cellStyle(isDark))
                            : Wrap(
                                spacing: 4.w,
                                runSpacing: 4.h,
                                children: links.map((link) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF059669,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      '${link['type']}: ${link['nature']}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF059669),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4338CA)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SECTION 6: 4-STEP KP
  // =========================================================================
  Widget _buildFourStepSection(bool isDark) {
    final fourStep = _kpData?['four_step'] as Map<String, dynamic>?;
    final planets = (fourStep?['planets'] as List<dynamic>?) ?? [];
    final cusps = (fourStep?['cusps'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPillTab(
                title: 'Planets (4-Step)',
                isSelected: _fourStepSubTabIndex == 0,
                onTap: () => setState(() => _fourStepSubTabIndex = 0),
                isDark: isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPillTab(
                title: 'Cusps (4-Step)',
                isSelected: _fourStepSubTabIndex == 1,
                onTap: () => setState(() => _fourStepSubTabIndex = 1),
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        if (_fourStepSubTabIndex == 0) ...[
          if (planets.isEmpty)
            _buildInfoCard('No 4-step planet data available.', isDark)
          else
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF4338CA).withValues(alpha: 0.1),
                  ),
                  dividerThickness: 0.3,
                  dataRowMinHeight: 60.h,
                  dataRowMaxHeight: 90.h,
                  headingTextStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  columnSpacing: 16.w,
                  horizontalMargin: 12.w,
                  columns: [
                    DataColumn(
                      label: Text('Planet', style: _headerStyle(isDark)),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 1 (Source)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 2 (Execution)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 3 (Decider)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 4 (Result)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                  ],
                  rows: planets.map((p) {
                    final s1 =
                        p['step_1']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';
                    final s2 =
                        p['step_2']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';
                    final s3 =
                        p['step_3']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';
                    final s4 =
                        p['step_4']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            p['subject']?.toString() ?? '',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: const Color(0xFF4338CA),
                            ),
                          ),
                        ),
                        DataCell(Text(s1, style: _cellStyle(isDark))),
                        DataCell(Text(s2, style: _cellStyle(isDark))),
                        DataCell(Text(s3, style: _cellStyle(isDark))),
                        DataCell(Text(s4, style: _cellStyle(isDark))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],

        if (_fourStepSubTabIndex == 1) ...[
          if (cusps.isEmpty)
            _buildInfoCard('No 4-step cusp data available.', isDark)
          else
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF4338CA).withValues(alpha: 0.1),
                  ),
                  dividerThickness: 0.3,
                  dataRowMinHeight: 60.h,
                  dataRowMaxHeight: 90.h,
                  headingTextStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  columnSpacing: 16.w,
                  horizontalMargin: 12.w,
                  columns: [
                    DataColumn(
                      label: Text('Cusp', style: _headerStyle(isDark)),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 1 (Source)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 2 (Execution)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 3 (Decider)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Step 4 (Result)',
                        style: _headerStyle(isDark),
                      ),
                    ),
                  ],
                  rows: cusps.map((c) {
                    final s1 =
                        c['step_1']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';
                    final s2 =
                        c['step_2']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';
                    final s3 =
                        c['step_3']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';
                    final s4 =
                        c['step_4']?['summary']
                            ?.toString()
                            .replaceAll(' occupies ', '\nOcc: ')
                            .replaceAll(', rules ', '\nRules: ') ??
                        '';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            c['subject']?.toString() ?? '',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: const Color(0xFF4338CA),
                            ),
                          ),
                        ),
                        DataCell(Text(s1, style: _cellStyle(isDark))),
                        DataCell(Text(s2, style: _cellStyle(isDark))),
                        DataCell(Text(s3, style: _cellStyle(isDark))),
                        DataCell(Text(s4, style: _cellStyle(isDark))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF4338CA)),
          SizedBox(height: 16.h),
          Text(
            'Computing Real-Time KP Placements with Swiss Ephemeris...',
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Recalculating Ayanamsa, Placidus Cusps, and Sub-Lord Divisions...',
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFDC2626),
            size: 40.sp,
          ),
          SizedBox(height: 10.h),
          Text(
            _errorMessage ?? 'Calculation Error',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
            ),
          ),
          SizedBox(height: 14.h),
          ElevatedButton(
            onPressed: _fetchKpData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: Text(
              'Retry Calculation',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : const Color(0xFF713F12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Text(
          'No chart data available.',
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String msg, bool isDark) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ),
    );
  }

  TextStyle _headerStyle(bool isDark) => GoogleFonts.outfit(
    fontSize: 11.5.sp,
    fontWeight: FontWeight.bold,
    color: isDark ? Colors.white70 : const Color(0xFF334155),
  );

  TextStyle _cellStyle(bool isDark) => GoogleFonts.outfit(
    fontSize: 11.5.sp,
    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
  );

  TextStyle _cellBoldStyle(bool isDark) => GoogleFonts.outfit(
    fontSize: 11.5.sp,
    fontWeight: FontWeight.bold,
    color: isDark ? Colors.white : const Color(0xFF1E293B),
  );

  TextStyle _cellBadgeStyle(Color color) => GoogleFonts.outfit(
    fontSize: 11.5.sp,
    fontWeight: FontWeight.bold,
    color: color,
  );

  String _getLordShort(String lord) {
    final l = lord.toLowerCase();
    if (l.contains('sun') || l.contains('surya')) return 'Su';
    if (l.contains('moon') || l.contains('chandra')) return 'Mo';
    if (l.contains('mars') || l.contains('mangal')) return 'Ma';
    if (l.contains('mercury') || l.contains('budha')) return 'Me';
    if (l.contains('jupiter') || l.contains('guru')) return 'Ju';
    if (l.contains('venus') || l.contains('shukra')) return 'Ve';
    if (l.contains('saturn') || l.contains('shani')) return 'Sa';
    if (l.contains('rahu')) return 'Ra';
    if (l.contains('ketu')) return 'Ke';
    return lord.isNotEmpty ? lord.substring(0, 2.clamp(0, lord.length)) : '';
  }

  // =========================================================================
  // SECTION 7: ANGULAR DISTANCE
  // =========================================================================
  Widget _buildAngularDistanceSection(bool isDark) {
    final planets = (_kpData?['planets'] as List<dynamic>?) ?? [];
    final transitPlanets = (_kpData?['transit_planets'] as List<dynamic>?) ?? [];
    
    Map<String, double> longitudes = {};
    for (var p in planets) {
      String pName = p['name']?.toString() ?? '';
      longitudes[pName] = (p['longitude'] as num?)?.toDouble() ?? 0.0;
    }
    
    Map<String, double> transitLongitudes = {};
    for (var tp in transitPlanets) {
      String pName = tp['name']?.toString() ?? '';
      transitLongitudes[pName] = (tp['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    final rowNamesPlanet = [
      'Ascendant',
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Rahu',
      'Ketu',
      'Uranus',
      'Neptune',
      'Pluto',
    ];

    final rowNamesTransitPlanet = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Rahu',
      'Ketu',
      'Uranus',
      'Neptune',
      'Pluto',
    ];

    double _getDistance(double l1, double l2) {
      double diff = (l1 - l2).abs();
      if (diff > 180.0) diff = 360.0 - diff;
      return diff;
    }

    String _getShort(String n) {
      if (n == 'Ascendant') return 'ASC';
      if (n.length >= 3) return n.substring(0, 3).toUpperCase();
      return n.toUpperCase();
    }

    Widget buildAngMatrix(
      List<String> rNames,
      List<String> cNames,
      Map<String, double> rLons,
      Map<String, double> cLons,
      bool isNatalNatal,
    ) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 70.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isNatalNatal ? 'Natal\nPlanets' : 'Transit\nPlanets',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.sp,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  ...cNames.map((cName) => Container(
                        width: 65.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getShort(cName),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11.sp,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      )),
                ],
              ),
              // Data Rows
              ...rNames.map((rName) {
                return Row(
                  children: [
                    Container(
                      width: 70.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getShort(rName),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.sp,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    ...cNames.map((cName) {
                      bool hasData = rLons.containsKey(rName) && cLons.containsKey(cName);
                      double dist = 0.0;
                      if (hasData) {
                        dist = _getDistance(rLons[rName]!, cLons[cName]!);
                      }
                      
                      int rIdx = rNames.indexOf(rName);
                      int cIdx = cNames.indexOf(cName);
                      bool isEmpty = (isNatalNatal && cIdx > rIdx);

                      return Container(
                        width: 65.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: (hasData && !isEmpty)
                            ? Text(
                                dist.toStringAsFixed(4),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.sp,
                                  color: Colors.blue[600],
                                ),
                              )
                            : (isEmpty ? const SizedBox() : Text('-', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _angularDistanceSubTabIndex = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: _angularDistanceSubTabIndex == 0
                          ? (isDark ? const Color(0xFF334155) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: _angularDistanceSubTabIndex == 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Natal -> Natal',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: _angularDistanceSubTabIndex == 0
                            ? const Color(0xFF4338CA)
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _angularDistanceSubTabIndex = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: _angularDistanceSubTabIndex == 1
                          ? (isDark ? const Color(0xFF334155) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: _angularDistanceSubTabIndex == 1
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Natal -> Transit',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: _angularDistanceSubTabIndex == 1
                            ? const Color(0xFF4338CA)
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Matrix
        if (_angularDistanceSubTabIndex == 0)
          buildAngMatrix(rowNamesPlanet, rowNamesPlanet, longitudes, longitudes, true)
        else
          buildAngMatrix(rowNamesTransitPlanet, rowNamesPlanet, transitLongitudes, longitudes, false),
      ],
    );
  }
}
