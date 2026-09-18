import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/astro_models.dart';
import '../services/astro_api_service.dart';
import '../widgets/kundli_chart_painter.dart';

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
  });

  @override
  State<KpSystemView> createState() => _KpSystemViewState();
}

class _KpSystemViewState extends State<KpSystemView> {
  static const List<String> ayanamsaOptions = [
    'Krishnamurti (KP New)',
    'Krishnamurti (KP Old)',
    'KP Straight Line',
    'Khullar',
    'Tropical (Sayana)',
    'Lahiri (Chitapaksha)',
    'B.V. Raman',
    'Sri Yukteswar',
  ];

  static const List<String> subSections = [
    'KP Chart',
    'Dasha',
    'Significators',
    'KP Aspects',
    'Nakshatra Nadi',
    '4-Step',
  ];

  String _selectedAyanamsa = 'Krishnamurti (KP New)';
  int _activeSectionIndex = 0;

  // KP Chart specific state
  String _activeChartType = 'Bhava'; // 'Bhava', 'D-1', 'D-9'

  // Significators specific state
  int _significatorSubTabIndex = 0; // 0: Planet, 1: House

  // KP Aspects specific state
  int _aspectSubTabIndex = 0; // 0: Planets, 1: KP Cusp

  // 4-Step specific state
  int _fourStepSubTabIndex = 0; // 0: Planets, 1: Cusps

  // Expanded Dasha state
  final Set<String> _expandedMahadashas = {};
  final Set<String> _expandedAntardashas = {};

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _kpData;

  @override
  void initState() {
    super.initState();
    _fetchKpData();
  }

  @override
  void didUpdateWidget(covariant KpSystemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personName != widget.personName ||
        oldWidget.dateOfBirth != widget.dateOfBirth ||
        oldWidget.timeOfBirth != widget.timeOfBirth ||
        oldWidget.placeOfBirth != widget.placeOfBirth ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.timezone != widget.timezone) {
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
        border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
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
            child: Icon(Icons.calculate_rounded, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.personName.isNotEmpty ? widget.personName : 'User Horoscope',
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
              icon: Icon(Icons.edit_calendar_rounded, color: const Color(0xFF4338CA), size: 20.sp),
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
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4338CA)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4338CA).withValues(alpha: 0.3),
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
      default:
        return _buildKpChartSection(isDark);
    }
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
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18.sp, color: const Color(0xFF4338CA)),
              SizedBox(width: 8.w),
              Text(
                'Ayanamsa:',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAyanamsa,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4338CA)),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    items: ayanamsaOptions.map((ayan) {
                      return DropdownMenuItem<String>(
                        value: ayan,
                        child: Text(ayan, overflow: TextOverflow.ellipsis),
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
            style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black45),
          ),
        ],
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
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.25)),
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
                        : 'Rashi Natal Chart (D1)',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : const Color(0xFF4338CA),
                ),
              ),
              SizedBox(height: 12.h),
              KundliInteractiveChart(
                chartStyle: widget.chartStyle,
                isDark: isDark,
                chartTypeKey: _activeChartType,
                showUpagrahas: false,
                showDegrees: true,
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
              if (_activeChartType == 'D-9' && _kpData?['divisional_charts']?['D-9']?['planets'] != null) {
                activePlanets = _kpData!['divisional_charts']['D-9']['planets'] as List<dynamic>;
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
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
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
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
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
              _buildRpItem('Lagna Rashi Lord', rp['lagna_rashi_lord']?.toString() ?? '-', isDark),
              Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.black12),
              _buildRpItem('Lagna Nakshatra Lord', rp['lagna_nakshatra_lord']?.toString() ?? '-', isDark),
              Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.black12),
              _buildRpItem('Moon Rashi Lord', rp['moon_rashi_lord']?.toString() ?? '-', isDark),
              Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.black12),
              _buildRpItem('Moon Nakshatra Lord', rp['moon_nakshatra_lord']?.toString() ?? '-', isDark),
              Divider(height: 1, thickness: 1, color: isDark ? Colors.white12 : Colors.black12),
              _buildRpItem('Vedic Day Lord', rp['day_lord']?.toString() ?? '-', isDark, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRpItem(String label, String value, bool isDark, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
          ),
          Text(
            value.toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  // 4. PLANETARY TABLE
  Widget _buildPlanetaryTable(List<dynamic> planets, bool isDark) {
    String title = 'Planetary Coordinates & KP Lords';
    if (_activeChartType == 'D-1') {
      title = 'Planetary Positions for Rashi (D-1)';
    } else if (_activeChartType == 'D-9') {
      title = 'Planetary Positions for Navamsha (D-9)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
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
              headingRowColor: WidgetStateProperty.all(const Color(0xFF4338CA).withValues(alpha: 0.1)),
              columnSpacing: 16.w,
              horizontalMargin: 12.w,
              columns: [
                DataColumn(label: Text('Planet', style: _headerStyle(isDark))),
                DataColumn(label: Text('RL', style: _headerStyle(isDark))),
                DataColumn(label: Text('NL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SSL', style: _headerStyle(isDark))),
                DataColumn(label: Text('Degree', style: _headerStyle(isDark))),
                DataColumn(label: Text('Rashi', style: _headerStyle(isDark))),
                DataColumn(label: Text('Nakshatra', style: _headerStyle(isDark))),
                DataColumn(label: Text('Paada', style: _headerStyle(isDark))),
              ],
              rows: planets.map((p) {
                final isLagna = p['name'] == 'Ascendant' || p['name'] == 'Lagna';
                return DataRow(
                  color: isLagna
                      ? WidgetStateProperty.all(const Color(0xFF4338CA).withValues(alpha: isDark ? 0.2 : 0.08))
                      : null,
                  cells: [
                    DataCell(Text(p['table_display_name'] ?? p['name'] ?? '', style: _cellBoldStyle(isDark))),
                    DataCell(Text(p['rl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(Text(p['nl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(Text(p['sl'] ?? '-', style: _cellBadgeStyle(const Color(0xFF059669)))),
                    DataCell(Text(p['ssl'] ?? '-', style: _cellBadgeStyle(const Color(0xFF7C3AED)))),
                    DataCell(Text(p['degree_formatted'] ?? '', style: _cellStyle(isDark))),
                    DataCell(Text(p['sign'] ?? '', style: _cellStyle(isDark))),
                    DataCell(Text(p['nakshatra'] ?? '', style: _cellStyle(isDark))),
                    DataCell(Text(p['pada']?.toString() ?? '', style: _cellStyle(isDark))),
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
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
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
              headingRowColor: WidgetStateProperty.all(const Color(0xFF4338CA).withValues(alpha: 0.1)),
              columnSpacing: 14.w,
              horizontalMargin: 12.w,
              columns: [
                DataColumn(label: Text('House', style: _headerStyle(isDark))),
                DataColumn(label: Text('Cusp Deg', style: _headerStyle(isDark))),
                DataColumn(label: Text('Rashi', style: _headerStyle(isDark))),
                DataColumn(label: Text('Nakshatra', style: _headerStyle(isDark))),
                DataColumn(label: Text('Pada', style: _headerStyle(isDark))),
                DataColumn(label: Text('RL', style: _headerStyle(isDark))),
                DataColumn(label: Text('NL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SL', style: _headerStyle(isDark))),
                DataColumn(label: Text('SSL', style: _headerStyle(isDark))),
                DataColumn(label: Text('Occupants', style: _headerStyle(isDark))),
              ],
              rows: cusps.map((c) {
                return DataRow(
                  cells: [
                    DataCell(Text('H${c['house']}', style: _cellBoldStyle(isDark))),
                    DataCell(Text(c['degree_formatted'] ?? '', style: _cellStyle(isDark))),
                    DataCell(Text(c['sign'] ?? '', style: _cellStyle(isDark))),
                    DataCell(Text(c['nakshatra'] ?? '', style: _cellStyle(isDark))),
                    DataCell(Text(c['pada']?.toString() ?? '', style: _cellStyle(isDark))),
                    DataCell(Text(c['rl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(Text(c['nl'] ?? '-', style: _cellStyle(isDark))),
                    DataCell(Text(c['sl'] ?? '-', style: _cellBadgeStyle(const Color(0xFF059669)))),
                    DataCell(Text(c['ssl'] ?? '-', style: _cellBadgeStyle(const Color(0xFF7C3AED)))),
                    DataCell(Text(c['occupants_str'] ?? 'None', style: _cellStyle(isDark))),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance info banner
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF4338CA).withValues(alpha: isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: const Color(0xFF4338CA), size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Birth Nakshatra: $birthNak ($birthLord) | Balance: $balance',
                  style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        Text(
          'Vimshottari Dasha Timeline',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 8.h),

        ...mahadashas.map((maha) {
          final mPlanet = maha['planet']?.toString() ?? '';
          final mStart = maha['start']?.toString() ?? '';
          final mEnd = maha['end']?.toString() ?? '';
          final isActive = maha['is_active'] == true;
          final isExpanded = _expandedMahadashas.contains(mPlanet);
          final antaras = (maha['antardashas'] as List<dynamic>?) ?? [];

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isActive ? const Color(0xFF059669) : (isDark ? Colors.white12 : Colors.black12),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedMahadashas.remove(mPlanet);
                      } else {
                        _expandedMahadashas.add(mPlanet);
                      }
                    });
                  },
                  leading: CircleAvatar(
                    radius: 14.r,
                    backgroundColor: isActive ? const Color(0xFF059669) : const Color(0xFF4338CA),
                    child: Text(
                      _getLordShort(mPlanet),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        '$mPlanet Mahadasha',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      if (isActive) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(6.r)),
                          child: Text('RUNNING', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '$mStart - $mEnd',
                    style: GoogleFonts.outfit(fontSize: 11.5.sp, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (isExpanded)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                    child: Column(
                      children: antaras.map((ad) {
                        final aPlanet = ad['planet']?.toString() ?? '';
                        final aStart = ad['start']?.toString() ?? '';
                        final aEnd = ad['end']?.toString() ?? '';
                        final isAdActive = ad['is_active'] == true;
                        final adKey = '$mPlanet-$aPlanet';
                        final isAdExpanded = _expandedAntardashas.contains(adKey);
                        final pratis = (ad['pratyantardashas'] as List<dynamic>?) ?? [];

                        return Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: isAdActive ? const Color(0xFF059669) : Colors.transparent),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                dense: true,
                                onTap: () {
                                  setState(() {
                                    if (isAdExpanded) {
                                      _expandedAntardashas.remove(adKey);
                                    } else {
                                      _expandedAntardashas.add(adKey);
                                    }
                                  });
                                },
                                title: Text(
                                  '$mPlanet - $aPlanet',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                                subtitle: Text('$aStart - $aEnd', style: GoogleFonts.outfit(fontSize: 10.5.sp, color: isDark ? Colors.white60 : Colors.black54)),
                                trailing: Icon(isAdExpanded ? Icons.remove : Icons.add, size: 16.sp, color: isDark ? Colors.white54 : Colors.black45),
                              ),
                              if (isAdExpanded)
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  child: Column(
                                    children: pratis.map((pd) {
                                      final isPdActive = pd['is_active'] == true;
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: 2.h),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$mPlanet - $aPlanet - ${pd['planet']}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10.5.sp,
                                                fontWeight: isPdActive ? FontWeight.bold : FontWeight.normal,
                                                color: isPdActive ? const Color(0xFF059669) : (isDark ? Colors.white70 : Colors.black87),
                                              ),
                                            ),
                                            Text(
                                              '${pd['start']} - ${pd['end']}',
                                              style: GoogleFonts.outfit(fontSize: 10.sp, color: isDark ? Colors.white54 : Colors.black54),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // SECTION 3: SIGNIFICATORS (Planet & House)
  // =========================================================================
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
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF4338CA).withValues(alpha: 0.1)),
                columnSpacing: 18.w,
                horizontalMargin: 12.w,
                columns: [
                  DataColumn(label: Text('Planet', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-A (NL Occ)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-B (Occ)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-C (NL Own)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-D (Own)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('All Houses', style: _headerStyle(isDark))),
                ],
                rows: planetSigs.map((ps) {
                  final a = (ps['level_a'] as List<dynamic>?)?.join(', ') ?? '-';
                  final b = (ps['level_b'] as List<dynamic>?)?.join(', ') ?? '-';
                  final c = (ps['level_c'] as List<dynamic>?)?.join(', ') ?? '-';
                  final d = (ps['level_d'] as List<dynamic>?)?.join(', ') ?? '-';
                  final all = (ps['all_significators'] as List<dynamic>?)?.join(', ') ?? '-';

                  return DataRow(
                    cells: [
                      DataCell(Text(ps['planet'] ?? '', style: _cellBoldStyle(isDark))),
                      DataCell(Text(a.isEmpty ? '-' : a, style: _cellStyle(isDark))),
                      DataCell(Text(b.isEmpty ? '-' : b, style: _cellStyle(isDark))),
                      DataCell(Text(c.isEmpty ? '-' : c, style: _cellStyle(isDark))),
                      DataCell(Text(d.isEmpty ? '-' : d, style: _cellStyle(isDark))),
                      DataCell(Text(all, style: _cellBadgeStyle(const Color(0xFF4338CA)))),
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
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF4338CA).withValues(alpha: 0.1)),
                columnSpacing: 18.w,
                horizontalMargin: 12.w,
                columns: [
                  DataColumn(label: Text('House', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-1 (In Star of Occ)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-2 (Occupants)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-3 (In Star of Lord)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('Level-4 (Lord)', style: _headerStyle(isDark))),
                  DataColumn(label: Text('All Significators', style: _headerStyle(isDark))),
                ],
                rows: houseSigs.map((hs) {
                  final l1 = (hs['level_1'] as List<dynamic>?)?.join(', ') ?? '-';
                  final l2 = (hs['level_2'] as List<dynamic>?)?.join(', ') ?? '-';
                  final l3 = (hs['level_3'] as List<dynamic>?)?.join(', ') ?? '-';
                  final l4 = (hs['level_4'] as List<dynamic>?)?.join(', ') ?? '-';
                  final all = (hs['all_planets'] as List<dynamic>?)?.join(', ') ?? '-';

                  return DataRow(
                    cells: [
                      DataCell(Text('House ${hs['house']}', style: _cellBoldStyle(isDark))),
                      DataCell(Text(l1.isEmpty ? '-' : l1, style: _cellStyle(isDark))),
                      DataCell(Text(l2.isEmpty ? '-' : l2, style: _cellStyle(isDark))),
                      DataCell(Text(l3.isEmpty ? '-' : l3, style: _cellStyle(isDark))),
                      DataCell(Text(l4.isEmpty ? '-' : l4, style: _cellStyle(isDark))),
                      DataCell(Text(all, style: _cellBadgeStyle(const Color(0xFF059669)))),
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
  Widget _buildAspectsSection(bool isDark) {
    final aspects = _kpData?['aspects'] as Map<String, dynamic>?;
    final planetAspects = (aspects?['planet_aspects'] as List<dynamic>?) ?? [];
    final cuspAspects = (aspects?['cusp_aspects'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPillTab(
                title: 'Planets Aspects',
                isSelected: _aspectSubTabIndex == 0,
                onTap: () => setState(() => _aspectSubTabIndex = 0),
                isDark: isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPillTab(
                title: 'KP Cusp Aspects',
                isSelected: _aspectSubTabIndex == 1,
                onTap: () => setState(() => _aspectSubTabIndex = 1),
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        if (_aspectSubTabIndex == 0) ...[
          if (planetAspects.isEmpty)
            _buildInfoCard('No major planetary aspects within orb.', isDark)
          else
            ...planetAspects.map((asp) {
              final isHarmonious = asp['nature']?.toString().toLowerCase().contains('harmonious') ?? false;
              final natureColor = isHarmonious ? const Color(0xFF059669) : const Color(0xFFDC2626);

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: natureColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: natureColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        asp['aspect_name'] ?? '',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.sp, color: natureColor),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${asp['planet_1']} \u2194 ${asp['planet_2']}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Exact: ${asp['actual_angle']}° (Orb ${asp['orb']}°) | ${asp['nature']}',
                            style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ] else ...[
          if (cuspAspects.isEmpty)
            _buildInfoCard('No cusp aspects within orb.', isDark)
          else
            ...cuspAspects.map((asp) {
              final isHarmonious = asp['nature']?.toString().toLowerCase().contains('harmonious') ?? false;
              final natureColor = isHarmonious ? const Color(0xFF059669) : const Color(0xFF4338CA);

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: natureColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: natureColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        asp['aspect_name'] ?? '',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.sp, color: natureColor),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${asp['planet']} \u2192 Cusp ${asp['cusp_house']}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Distance: ${asp['actual_angle']}° (Orb ${asp['orb']}°)',
                            style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }

  // =========================================================================
  // SECTION 5: NAKSHATRA NADI
  // =========================================================================
  Widget _buildNakshatraNadiSection(bool isDark) {
    final nadiList = (_kpData?['nakshatra_nadi'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nakshatra Nadi Coordinates & Linkages',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        SizedBox(height: 4.h),
        Text(
          'Source of Truth: Real-time calculated planetary coordinates, star lords, and sub-lords.',
          style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white60 : Colors.black54),
        ),
        SizedBox(height: 12.h),

        ...nadiList.map((nadi) {
          final pName = nadi['planet'] ?? '';
          final script = nadi['nadi_script'] ?? '';
          final links = (nadi['nadi_links'] as List<dynamic>?) ?? [];

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12.r,
                          backgroundColor: const Color(0xFF4338CA),
                          child: Text(
                            _getLordShort(pName),
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '$pName in ${nadi['rashi']}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Text(
                      '${nadi['nakshatra']} (Pada ${nadi['pada']})',
                      style: GoogleFonts.outfit(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF4338CA)),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4338CA).withValues(alpha: isDark ? 0.2 : 0.06),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    script,
                    style: GoogleFonts.outfit(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF312E81)),
                  ),
                ),
                SizedBox(height: 8.h),

                if (links.isNotEmpty)
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: links.map((link) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${link['type']}: ${link['nature']}',
                          style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }),
      ],
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

        ...(_fourStepSubTabIndex == 0 ? planets : cusps).map((item) {
          final subject = item['subject'] ?? '';
          final flow = item['flow'] ?? '';
          final s1 = item['step_1'] ?? {};
          final s2 = item['step_2'] ?? {};
          final s3 = item['step_3'] ?? {};
          final s4 = item['step_4'] ?? {};

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.sp, color: const Color(0xFF4338CA)),
                    ),
                    Text(
                      '4-Step Chain',
                      style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                _buildStepRow('Step 1 (Source)', s1['summary'] ?? '', isDark),
                _buildStepRow('Step 2 (Execution)', s2['summary'] ?? '', isDark),
                _buildStepRow('Step 3 (Decider Sub)', s3['summary'] ?? '', isDark, isHighlight: true),
                _buildStepRow('Step 4 (End Result)', s4['summary'] ?? '', isDark),

                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    flow,
                    style: GoogleFonts.outfit(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepRow(String title, String summary, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? const Color(0xFF059669) : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
          Expanded(
            child: Text(
              summary,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? (isDark ? Colors.white : const Color(0xFF059669)) : (isDark ? Colors.white60 : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4338CA) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
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
            style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
          SizedBox(height: 4.h),
          Text(
            'Recalculating Ayanamsa, Placidus Cusps, and Sub-Lord Divisions...',
            style: GoogleFonts.outfit(fontSize: 11.sp, color: isDark ? Colors.white54 : Colors.black45),
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
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: const Color(0xFFDC2626), size: 40.sp),
          SizedBox(height: 10.h),
          Text(
            _errorMessage ?? 'Calculation Error',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
          ),
          SizedBox(height: 14.h),
          ElevatedButton(
            onPressed: _fetchKpData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: Text('Retry Calculation', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
          style: GoogleFonts.outfit(fontSize: 14.sp, color: isDark ? Colors.white60 : Colors.black54),
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
        child: Text(msg, style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white60 : Colors.black54)),
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
}
