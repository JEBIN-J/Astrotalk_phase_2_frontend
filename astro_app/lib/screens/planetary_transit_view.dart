import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';
import '../services/astrologer_location_service.dart';

class KpPlanetaryTransitSection extends StatefulWidget {
  final bool isDark;
  final String originalDateOfBirth;
  final String originalTimeOfBirth;
  final String originalPlaceOfBirth;
  final double originalLatitude;
  final double originalLongitude;
  final double originalTimezone;
  final String selectedAyanamsa;
  final ValueChanged<Map<String, dynamic>> onKpDataChanged;
  final VoidCallback onResetKpData;
  final ValueChanged<String>? onCuspsTypeChanged;
  final ValueChanged<DateTime>? onTransitDateChanged;
  final ValueChanged<String>? onTransitLocationChanged;
  final ValueChanged<bool>? onRealTimeToggled;
  final Widget? chartChild;
  final Widget Function(BuildContext context, Widget stepIntervalWidget)? chartChildBuilder;

  const KpPlanetaryTransitSection({
    super.key,
    required this.isDark,
    required this.originalDateOfBirth,
    required this.originalTimeOfBirth,
    required this.originalPlaceOfBirth,
    required this.originalLatitude,
    required this.originalLongitude,
    required this.originalTimezone,
    required this.selectedAyanamsa,
    required this.onKpDataChanged,
    required this.onResetKpData,
    this.onCuspsTypeChanged,
    this.onTransitDateChanged,
    this.onTransitLocationChanged,
    this.onRealTimeToggled,
    this.chartChild,
    this.chartChildBuilder,
  });

  @override
  State<KpPlanetaryTransitSection> createState() => _KpPlanetaryTransitSectionState();
}

class _KpPlanetaryTransitSectionState extends State<KpPlanetaryTransitSection> with SingleTickerProviderStateMixin {
  late DateTime _currentTransitDate;
  String _transitLocation = '';
  double? _transitLat;
  double? _transitLon;
  double? _transitTz;
  
  bool _isRealTimeEnabled = false;
  Timer? _realTimeTimer;
  DateTime? _lastTransitFetchTime;
  bool _isBackgroundRefreshing = false;

  int _stepValue = 1;
  String _stepUnit = 'Min.'; 
  final List<String> _units = ['Sec.', 'Min.', 'Hour', 'Day', 'Month', 'Year'];
  final List<int> _stepValues = [1, 2, 3, 5, 10, 15, 30];

  String _cuspsType = 'Use Transit Cusps'; 
  
  bool _isLoading = false;
  bool _isSwapped = false;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentTransitDate = DateTime.now();
    _transitLocation = widget.originalPlaceOfBirth;
    _transitLat = widget.originalLatitude;
    _transitLon = widget.originalLongitude;
    _transitTz = widget.originalTimezone;
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _loadTransitLocation();
    AstrologerLocationService.locationNotifier.addListener(_onGlobalLocationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onTransitDateChanged?.call(_currentTransitDate);
        widget.onTransitLocationChanged?.call(_transitLocation);
        widget.onCuspsTypeChanged?.call(_cuspsType);
      }
    });
  }

  Future<void> _loadTransitLocation() async {
    final loc = await AstrologerLocationService.getLocation();
    if (mounted) {
      setState(() {
        _transitLocation = loc.city;
        _transitLat = loc.latitude;
        _transitLon = loc.longitude;
        _transitTz = loc.timezone;
      });
      widget.onTransitLocationChanged?.call(_transitLocation);
    }
  }

  void _onGlobalLocationChanged() {
    final loc = AstrologerLocationService.locationNotifier.value;
    if (loc != null && mounted) {
      setState(() {
        _transitLocation = loc.city;
        _transitLat = loc.latitude;
        _transitLon = loc.longitude;
        _transitTz = loc.timezone;
      });
      widget.onTransitLocationChanged?.call(_transitLocation);
      if (_cuspsType == 'Use Transit Cusps' && (_isSwapped || _isRealTimeEnabled)) {
        _fetchTransitData(isSilent: true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant KpPlanetaryTransitSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAyanamsa != widget.selectedAyanamsa) {
      if (_isSwapped || _isRealTimeEnabled) {
        _fetchTransitData(isSilent: _isRealTimeEnabled);
      }
    }
  }

  @override
  void dispose() {
    AstrologerLocationService.locationNotifier.removeListener(_onGlobalLocationChanged);
    _realTimeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _fetchTransitData({bool isSilent = false}) async {
    if (_isLoading) return;

    if (isSilent) {
      _isBackgroundRefreshing = true;
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final String formattedTransitDt = DateFormat('yyyy-MM-dd HH:mm:ss').format(_currentTransitDate);
      final double targetLat = (_transitLat ?? widget.originalLatitude);
      final double targetLon = (_transitLon ?? widget.originalLongitude);
      final double targetTz = (_transitTz ?? widget.originalTimezone);

      final res = await AstroApiService.getKpSystemData(
        name: 'User',
        dateOfBirth: widget.originalDateOfBirth,
        timeOfBirth: widget.originalTimeOfBirth,
        placeOfBirth: widget.originalPlaceOfBirth,
        latitude: widget.originalLatitude,
        longitude: widget.originalLongitude,
        timezone: widget.originalTimezone,
        transitDatetime: formattedTransitDt,
        transitLatitude: targetLat,
        transitLongitude: targetLon,
        transitTimezone: targetTz,
        ayanamsa: widget.selectedAyanamsa,
      );

      _lastTransitFetchTime = DateTime.now();

      if (mounted) {
        final Map<String, dynamic> transitRes = Map<String, dynamic>.from(res);
        transitRes['is_transit'] = true;
        widget.onKpDataChanged(transitRes);
        widget.onTransitDateChanged?.call(_currentTransitDate);
        setState(() {
          _isSwapped = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching transit data: $e');
      if (mounted && !isSilent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update chart: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBackgroundRefreshing = false;
        });
      }
    }
  }

  void _toggleRealTime() {
    if (_isRealTimeEnabled) {
      _realTimeTimer?.cancel();
      setState(() {
        _isRealTimeEnabled = false;
      });
      widget.onRealTimeToggled?.call(false);
    } else {
      final now = DateTime.now();
      setState(() {
        _isRealTimeEnabled = true;
        _isSwapped = true;
        _currentTransitDate = now;
      });
      widget.onRealTimeToggled?.call(true);
      widget.onTransitDateChanged?.call(now);
      
      // Fetch fresh transit calculation for the live current moment
      _fetchTransitData(isSilent: false);
      
      // Live clock updates smoothly every 1 second
      _realTimeTimer?.cancel();
      _realTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final tickTime = DateTime.now();
        setState(() {
          _currentTransitDate = tickTime;
        });
        widget.onTransitDateChanged?.call(tickTime);
        
        // Throttled background calculation (every 30s) so backend isn't hammered
        final lastFetch = _lastTransitFetchTime;
        if (!_isLoading && !_isBackgroundRefreshing &&
            (lastFetch == null || tickTime.difference(lastFetch).inSeconds >= 30)) {
          _fetchTransitData(isSilent: true);
        }
      });
    }
  }

  void _resetChart() {
    _realTimeTimer?.cancel();
    setState(() {
      _isSwapped = false;
      _isRealTimeEnabled = false;
      _currentTransitDate = DateTime.now();
    });
    widget.onRealTimeToggled?.call(false);
    widget.onTransitDateChanged?.call(_currentTransitDate);
    widget.onResetKpData();
  }

  void _accelerate() {
    setState(() {
      _currentTransitDate = _addTime(_currentTransitDate, _stepValue, _stepUnit);
      _isSwapped = true;
    });
    widget.onTransitDateChanged?.call(_currentTransitDate);
    if (!_isRealTimeEnabled) {
      _fetchTransitData();
    }
  }

  void _deaccelerate() {
    setState(() {
      _currentTransitDate = _addTime(_currentTransitDate, -_stepValue, _stepUnit);
      _isSwapped = true;
    });
    widget.onTransitDateChanged?.call(_currentTransitDate);
    if (!_isRealTimeEnabled) {
      _fetchTransitData();
    }
  }

  DateTime _addTime(DateTime date, int amount, String unit) {
    switch (unit) {
      case 'Sec.':
        return date.add(Duration(seconds: amount));
      case 'Min.':
        return date.add(Duration(minutes: amount));
      case 'Hour':
        return date.add(Duration(hours: amount));
      case 'Day':
        return date.add(Duration(days: amount));
      case 'Month':
        return DateTime(date.year, date.month + amount, date.day, date.hour, date.minute, date.second);
      case 'Year':
        return DateTime(date.year + amount, date.month, date.day, date.hour, date.minute, date.second);
      default:
        return date;
    }
  }

  void _showLocationPicker() async {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> places = await AstroApiService.getPlaces();

    if (!mounted) return;

    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const primaryIndigo = Color(0xFF4F46E5);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollCtrl) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          margin: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: primaryIndigo, size: 22.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Select Astrologer Location',
                              style: GoogleFonts.outfit(fontSize: 16.5.sp, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: TextField(
                          controller: searchCtrl,
                          style: GoogleFonts.outfit(fontSize: 14.sp, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search city (e.g. Bijapur, Mumbai)...',
                            hintStyle: GoogleFonts.outfit(fontSize: 13.5.sp, color: textMuted),
                            prefixIcon: Icon(Icons.search, color: textMuted, size: 20.sp),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: cardBorder)),
                          ),
                          onChanged: (val) async {
                            final results = await AstroApiService.getPlaces(query: val);
                            setModalState(() {
                              places = results;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 10.h),
                      const Divider(height: 1),
                      Expanded(
                        child: places.isEmpty
                            ? Center(
                                child: Text('No matching locations found', style: GoogleFonts.outfit(color: textMuted)),
                              )
                            : ListView.builder(
                                controller: scrollCtrl,
                                padding: EdgeInsets.all(16.w),
                                itemCount: places.length,
                                itemBuilder: (c, idx) {
                                  final p = places[idx];
                                  final isCurrentSelected = p['city'] == _transitLocation;
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(Icons.place_outlined, color: primaryIndigo, size: 20.sp),
                                    title: Text(
                                      p['city'] ?? '',
                                      style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600, color: textPrimary),
                                    ),
                                    subtitle: Text(
                                      '${p['coords']} • ${p['tz']}',
                                      style: GoogleFonts.inter(fontSize: 11.5.sp, color: textMuted),
                                    ),
                                    trailing: isCurrentSelected
                                        ? Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                            decoration: BoxDecoration(
                                              color: primaryIndigo,
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      final city = p['city'] ?? 'Custom Location';
                                      final lat = double.tryParse(p['lat_val'] ?? '') ?? 28.6139;
                                      final lon = double.tryParse(p['lon_val'] ?? '') ?? 77.2090;
                                      final tz = double.tryParse(p['tz_val'] ?? '') ?? 5.5;

                                      setState(() {
                                        _transitLocation = city;
                                        _transitLat = lat;
                                        _transitLon = lon;
                                        _transitTz = tz;
                                      });

                                      AstrologerLocationService.setLocation(
                                        AstrologerLocation(
                                          city: city,
                                          latitude: lat,
                                          longitude: lon,
                                          timezone: tz,
                                        ),
                                      );

                                      Navigator.pop(ctx);
                                      if (_cuspsType == 'Use Transit Cusps') {
                                        _fetchTransitData();
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Astrologer location updated to $city'),
                                          backgroundColor: const Color(0xFF4F46E5),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDateTimePicker() {
    DateTime selectedDate = _currentTransitDate;
    int hour = _currentTransitDate.hour;
    int minute = _currentTransitDate.minute;
    int second = _currentTransitDate.second;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = widget.isDark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
            final mutedColor = isDark ? Colors.white60 : const Color(0xFF64748B);

            return Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_calendar_rounded, color: const Color(0xFF4338CA), size: 22.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Set Transit Date & Time',
                            style: GoogleFonts.outfit(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        color: mutedColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Date Picker Card
                  Text(
                    'Transit Date',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: const Color(0xFF4338CA), size: 20.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMMM yyyy (EEEE)').format(selectedDate),
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            'Change',
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4338CA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Time Pickers (HH : MM : SS)
                  Text(
                    'Transit Time (24-Hour: HH : MM : SS)',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: mutedColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      // Hour
                      Expanded(
                        child: _buildTimeDropdown(
                          label: 'Hour',
                          value: hour,
                          max: 23,
                          isDark: isDark,
                          textColor: textColor,
                          sheetBg: sheetBg,
                          onChanged: (v) => setModalState(() => hour = v),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(':', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
                      ),
                      // Minute
                      Expanded(
                        child: _buildTimeDropdown(
                          label: 'Min',
                          value: minute,
                          max: 59,
                          isDark: isDark,
                          textColor: textColor,
                          sheetBg: sheetBg,
                          onChanged: (v) => setModalState(() => minute = v),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(':', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
                      ),
                      // Second
                      Expanded(
                        child: _buildTimeDropdown(
                          label: 'Sec',
                          value: second,
                          max: 59,
                          isDark: isDark,
                          textColor: textColor,
                          sheetBg: sheetBg,
                          onChanged: (v) => setModalState(() => second = v),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Quick presets
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      _buildPresetChip('Now', () {
                        final now = DateTime.now();
                        setModalState(() {
                          selectedDate = now;
                          hour = now.hour;
                          minute = now.minute;
                          second = now.second;
                        });
                      }, isDark),
                      _buildPresetChip('23:14:48 (Horosoft Ref)', () {
                        setModalState(() {
                          hour = 23;
                          minute = 14;
                          second = 48;
                        });
                      }, isDark),
                      _buildPresetChip('12:00:00 (Noon)', () {
                        setModalState(() {
                          hour = 12;
                          minute = 0;
                          second = 0;
                        });
                      }, isDark),
                      _buildPresetChip('00:00:00 (Midnight)', () {
                        setModalState(() {
                          hour = 0;
                          minute = 0;
                          second = 0;
                        });
                      }, isDark),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Apply Button
                  ElevatedButton(
                    onPressed: () {
                      final newDt = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        hour,
                        minute,
                        second,
                      );
                      setState(() {
                        _currentTransitDate = newDt;
                        _isSwapped = true;
                      });
                      widget.onTransitDateChanged?.call(_currentTransitDate);
                      Navigator.pop(ctx);
                      _fetchTransitData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'Apply & Calculate Transit',
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDropdown({
    required String label,
    required int value,
    required int max,
    required bool isDark,
    required Color textColor,
    required Color sheetBg,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.grey)),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value.clamp(0, max),
              isExpanded: true,
              dropdownColor: sheetBg,
              items: List.generate(max + 1, (i) => DropdownMenuItem(
                value: i,
                child: Center(
                  child: Text(
                    i.toString().padLeft(2, '0'),
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              )),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String text, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = const Color(0xFF4338CA).withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header Row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(
                Icons.explore_outlined,
                color: const Color(0xFF4338CA),
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Planetary Transit',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (_isRealTimeEnabled)
                FadeTransition(
                  opacity: _pulseController,
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'LIVE',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 2. Info Card (Location & Date)
        _buildSectionCard(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _cuspsType == 'Use Transit Cusps' ? _showLocationPicker : null,
                  borderRadius: BorderRadius.circular(8.r),
                  child: _buildInfoItem(
                    _cuspsType == 'Use Transit Cusps' ? 'Astrologer Location' : 'Birth Location',
                    _cuspsType == 'Use Transit Cusps' ? _transitLocation : widget.originalPlaceOfBirth,
                    Icons.location_on_rounded,
                    isDark,
                    textColor,
                    mutedTextColor,
                  ),
                ),
              ),
              Container(width: 1.w, height: 40.h, color: borderColor),
              SizedBox(width: 16.w),
              Expanded(
                child: InkWell(
                  onTap: _showDateTimePicker,
                  borderRadius: BorderRadius.circular(8.r),
                  child: _buildInfoItem('Date & Time (Tap to edit)', DateFormat('dd MMM yyyy\nHH:mm:ss').format(_currentTransitDate), Icons.calendar_month_rounded, isDark, textColor, mutedTextColor),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 3. Cusps Segmented Control Card
        _buildSectionCard(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          child: Row(
            children: ['Use Transit Cusps', 'Use Natal Cusps'].map((type) {
              final isSelected = _cuspsType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _cuspsType = type);
                    widget.onCuspsTypeChanged?.call(type);
                    if (!_isLoading) {
                      _fetchTransitData();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF)) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: isSelected ? Border.all(color: const Color(0xFF4338CA).withValues(alpha: 0.3)) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      type,
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF4338CA) : mutedTextColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16.h),

        // 4. Main Actions
        Row(
          children: [
            // Primary Action (Swap)
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: _isLoading || _isRealTimeEnabled ? null : _fetchTransitData,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isLoading && !_isRealTimeEnabled
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Calculate Transit Chart',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Reset Action
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: _resetChart,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.refresh_rounded, color: Colors.red, size: 24.sp),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        // Real-Time Toggle
        InkWell(
          onTap: _toggleRealTime,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: _isRealTimeEnabled 
                  ? Colors.redAccent.withValues(alpha: 0.12) 
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _isRealTimeEnabled 
                    ? Colors.redAccent 
                    : Colors.green.withValues(alpha: 0.5),
                width: _isRealTimeEnabled ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRealTimeEnabled)
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.green,
                    size: 20.sp,
                  ),
                if (!_isRealTimeEnabled) SizedBox(width: 8.w),
                Text(
                  _isRealTimeEnabled ? 'Stop Real-Time Display (LIVE)' : 'Enable Real-Time Display',
                  style: GoogleFonts.outfit(
                    color: _isRealTimeEnabled ? Colors.redAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                if (_isRealTimeEnabled && (_isLoading || _isBackgroundRefreshing)) ...[
                  SizedBox(width: 10.w),
                  SizedBox(
                    width: 13.w,
                    height: 13.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // 5. Embedded Chart Section with Step Interval Controls
        if (widget.chartChildBuilder != null) ...[
          widget.chartChildBuilder!(
            context,
            _buildStepIntervalCard(
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
            ),
          ),
        ] else ...[
          _buildStepIntervalCard(
            isDark: isDark,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
          ),
          SizedBox(height: 16.h),
          if (widget.chartChild != null) widget.chartChild!,
        ],
      ],
    );
  }

  Widget _buildStepIntervalCard({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedTextColor,
  }) {
    return _buildSectionCard(
      isDark: isDark,
      cardColor: cardColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transit Date & Time Display + Quick Tap to Edit
          InkWell(
            onTap: _showDateTimePicker,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18.sp, color: const Color(0xFF4338CA)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transit Date & Time (Tap to edit):',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w500,
                            color: mutedTextColor,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy   HH:mm:ss').format(_currentTransitDate),
                          style: GoogleFonts.outfit(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_calendar_rounded, size: 12.sp, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'Set Time',
                          style: GoogleFonts.outfit(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16.sp, color: mutedTextColor),
              SizedBox(width: 8.w),
              Text('Step Interval', style: TextStyle(color: mutedTextColor, fontSize: 13.sp)),
              const Spacer(),
              // Dropdown for Step Value
              Container(
                height: 32.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _stepValue,
                    icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF4338CA), size: 18.sp),
                    dropdownColor: cardColor,
                    items: _stepValues.map((val) => DropdownMenuItem(
                      value: val,
                      child: Text('$val', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w600)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _stepValue = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Unit Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _units.map((unit) {
                final isSelected = _stepUnit == unit;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: InkWell(
                    onTap: () => setState(() => _stepUnit = unit),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4338CA) : (isDark ? Colors.grey[800] : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        unit,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.h),
          // Accelerate / De-accelerate Buttons
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: Icons.fast_rewind_rounded,
                  label: 'Rewind',
                  color: Colors.orange,
                  onPressed: _isRealTimeEnabled ? null : _deaccelerate,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.fast_forward_rounded,
                  label: 'Forward',
                  color: Colors.blue,
                  onPressed: _isRealTimeEnabled ? null : _accelerate,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon, bool isDark, Color textColor, Color mutedTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: const Color(0xFF4338CA)),
            SizedBox(width: 6.w),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: mutedTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            color: textColor,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    final isDisabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isDisabled 
              ? (isDark ? Colors.grey[800] : const Color(0xFFF1F5F9)) 
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDisabled 
                ? Colors.transparent 
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isDisabled ? Colors.grey : color,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isDisabled ? Colors.grey : color,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
