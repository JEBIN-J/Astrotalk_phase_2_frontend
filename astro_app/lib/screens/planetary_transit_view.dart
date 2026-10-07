import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';

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
  });

  @override
  State<KpPlanetaryTransitSection> createState() => _KpPlanetaryTransitSectionState();
}

class _KpPlanetaryTransitSectionState extends State<KpPlanetaryTransitSection> with SingleTickerProviderStateMixin {
  late DateTime _currentTransitDate;
  String _transitLocation = '';
  
  bool _isRealTimeEnabled = false;
  Timer? _realTimeTimer;

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
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _realTimeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _fetchTransitData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(_currentTransitDate);
      final String formattedTime = DateFormat('HH:mm:ss').format(_currentTransitDate);

      String targetLocation = _cuspsType == 'Use Natal Cusps' ? widget.originalPlaceOfBirth : _transitLocation;
      
      final res = await AstroApiService.getKpSystemData(
        name: 'Transit',
        dateOfBirth: formattedDate,
        timeOfBirth: formattedTime,
        placeOfBirth: targetLocation,
        latitude: widget.originalLatitude,
        longitude: widget.originalLongitude,
        timezone: widget.originalTimezone,
        ayanamsa: widget.selectedAyanamsa,
      );

      if (mounted) {
        final Map<String, dynamic> transitRes = Map<String, dynamic>.from(res);
        transitRes['is_transit'] = true;
        widget.onKpDataChanged(transitRes);
        setState(() {
          _isSwapped = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching transit data: $e');
      if (mounted) {
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
    } else {
      setState(() {
        _isRealTimeEnabled = true;
        _isSwapped = true;
      });
      _currentTransitDate = DateTime.now();
      _fetchTransitData();
      
      _realTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _currentTransitDate = DateTime.now();
        });
        
        if (!_isLoading) {
          _fetchTransitData();
        }
      });
    }
  }

  void _resetChart() {
    setState(() {
      _isSwapped = false;
      _isRealTimeEnabled = false;
      _realTimeTimer?.cancel();
      _currentTransitDate = DateTime.now();
    });
    widget.onResetKpData();
  }

  void _accelerate() {
    setState(() {
      _currentTransitDate = _addTime(_currentTransitDate, _stepValue, _stepUnit);
    });
    if (_isSwapped && !_isRealTimeEnabled) {
      _fetchTransitData();
    }
  }

  void _deaccelerate() {
    setState(() {
      _currentTransitDate = _addTime(_currentTransitDate, -_stepValue, _stepUnit);
    });
    if (_isSwapped && !_isRealTimeEnabled) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final mutedTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = const Color(0xFF4338CA).withOpacity(0.2);

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
                child: _buildInfoItem('Location', _transitLocation, Icons.location_on_rounded, isDark, textColor, mutedTextColor),
              ),
              Container(width: 1.w, height: 40.h, color: borderColor),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildInfoItem('Date & Time', DateFormat('dd MMM yyyy\nHH:mm:ss').format(_currentTransitDate), Icons.calendar_month_rounded, isDark, textColor, mutedTextColor),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // 3. Time Controls Card
        _buildSectionCard(
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ),
        SizedBox(height: 12.h),
        
        // 4. Cusps Segmented Control Card
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
                    if (_isSwapped && !_isRealTimeEnabled) {
                      _fetchTransitData();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF)) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: isSelected ? Border.all(color: const Color(0xFF4338CA).withOpacity(0.3)) : null,
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

        // 5. Main Actions
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
                        color: const Color(0xFF4338CA).withOpacity(0.3),
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                  ? Colors.redAccent.withOpacity(0.1) 
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _isRealTimeEnabled 
                    ? Colors.redAccent.withOpacity(0.5) 
                    : Colors.green.withOpacity(0.5)
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRealTimeEnabled ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                  color: _isRealTimeEnabled ? Colors.redAccent : Colors.green,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _isRealTimeEnabled ? 'Stop Real-Time Display' : 'Enable Real-Time Display',
                  style: GoogleFonts.outfit(
                    color: _isRealTimeEnabled ? Colors.redAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
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
              : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDisabled 
                ? Colors.transparent 
                : color.withOpacity(0.3),
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
