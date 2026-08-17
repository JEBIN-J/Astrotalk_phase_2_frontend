import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MuhuratScreen extends StatefulWidget {
  const MuhuratScreen({super.key});

  @override
  State<MuhuratScreen> createState() => _MuhuratScreenState();
}

class _MuhuratScreenState extends State<MuhuratScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _muhurat;
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final Set<String> _auspiciousDates = {};

  String _selectedCityName = "New Delhi, India";
  double _lat = 28.6139;
  double _lon = 77.2090;
  double _tz = 5.5;

  final Color goldColor = const Color(0xFFD4AF37);
  final Color darkCard = const Color(0xFF161A25);

  @override
  void initState() {
    super.initState();
    _fetchMonthMarkers(_focusedDay);
    _fetchMuhuratForDate(_selectedDay);
  }

  Future<void> _fetchMonthMarkers(DateTime month) async {
    final dates = await AstroApiService.getMuhuratMonth(month.year, month.month, lat: _lat, lon: _lon, tz: _tz);
    if (mounted) {
      setState(() {
        _auspiciousDates.clear();
        _auspiciousDates.addAll(dates);
      });
    }
  }

  Future<void> _fetchMuhuratForDate(DateTime date) async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final data = await AstroApiService.getMuhurat(dateStr: dateStr, lat: _lat, lon: _lon, tz: _tz);
      if (mounted) {
        setState(() {
          _muhurat = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Muhurat: $e')),
        );
      }
    }
  }

  void _showMuhuratDetails(Map<String, dynamic> categoryData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailsSheet(categoryData),
    );
  }

  Widget _buildDetailsSheet(Map<String, dynamic> categoryData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161A25) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            '${categoryData['category']} Muhurat',
            style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor),
          ),
          SizedBox(height: 8.h),
          Text(
            _muhurat!['date'],
            style: GoogleFonts.outfit(fontSize: 16.sp, color: goldColor, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 24.h),
          
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: goldColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended Time', style: GoogleFonts.outfit(fontSize: 12.sp, color: textColor.withValues(alpha: 0.7))),
                    SizedBox(height: 4.h),
                    Text(categoryData['time'], style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Quality', style: GoogleFonts.outfit(fontSize: 12.sp, color: textColor.withValues(alpha: 0.7))),
                    SizedBox(height: 4.h),
                    Text(categoryData['status'], style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _getStatusColor(categoryData['status']))),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          
          Text('Why this time?', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
          SizedBox(height: 12.h),
          Text(categoryData['reason'], style: GoogleFonts.outfit(fontSize: 15.sp, height: 1.5, color: textColor.withValues(alpha: 0.8))),
          
          SizedBox(height: 24.h),
          Text('Planetary Conditions', style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
          SizedBox(height: 16.h),
          
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildConditionRow('Tithi', _muhurat!['panchanga']['tithi'], isDark),
                _buildConditionRow('Nakshatra', _muhurat!['panchanga']['nakshatra'], isDark),
                _buildConditionRow('Yoga', _muhurat!['panchanga']['yoga'], isDark),
                _buildConditionRow('Karana', _muhurat!['panchanga']['karana'], isDark),
                _buildConditionRow('Rahu Kaal', _muhurat!['general_timings']['rahu']['start'] + ' - ' + _muhurat!['general_timings']['rahu']['end'], isDark),
                _buildConditionRow('Yamaganda', _muhurat!['general_timings']['yama']['start'] + ' - ' + _muhurat!['general_timings']['yama']['end'], isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 15.sp, color: isDark ? Colors.white70 : Colors.black54)),
          Text(value, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toUpperCase() == 'GOOD') return const Color(0xFF4CAF50);
    if (status.toUpperCase() == 'AVERAGE') return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }

  void _showLocationSelector() {
    bool isSearching = false;
    List<Map<String, String>> searchResults = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Helper to fetch places
            Future<void> _fetchPlaces(String query) async {
              setModalState(() => isSearching = true);
              try {
                final results = await AstroApiService.getPlaces(query: query);
                setModalState(() {
                  searchResults = results;
                  isSearching = false;
                });
              } catch (e) {
                setModalState(() {
                  isSearching = false;
                });
              }
            }

            // Fetch default list on initial load
            if (searchResults.isEmpty && !isSearching) {
              _fetchPlaces("");
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161A25) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2.r)),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text('Select Location', style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  SizedBox(height: 16.h),
                  
                  // Search Field
                  TextField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search for a city...',
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      prefixIcon: Icon(Icons.search, color: goldColor),
                      filled: true,
                      fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      _fetchPlaces(val);
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Results List
                  Expanded(
                    child: isSearching
                        ? Center(child: CircularProgressIndicator(color: goldColor))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final city = searchResults[index];
                              final cityName = city['city'] ?? 'Unknown';
                              final isSelected = cityName == _selectedCityName;
                              
                              return ListTile(
                                leading: Icon(Icons.location_on, color: isSelected ? goldColor : Colors.grey),
                                title: Text(cityName, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white : Colors.black87)),
                                subtitle: Text('${city['coords']} • ${city['tz']}', style: GoogleFonts.outfit(fontSize: 12.sp, color: isDark ? Colors.white54 : Colors.black54)),
                                trailing: isSelected ? Icon(Icons.check_circle, color: goldColor) : null,
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _selectedCityName = cityName;
                                    _lat = double.parse(city['lat_val']!);
                                    _lon = double.parse(city['lon_val']!);
                                    _tz = double.parse(city['tz_val']!);
                                  });
                                  _fetchMonthMarkers(_focusedDay);
                                  _fetchMuhuratForDate(_selectedDay);
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFF9F9FB);
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A24);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Muhurat Explorer', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 22.sp, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: RefreshIndicator(
        color: goldColor,
        onRefresh: () async {
          await _fetchMonthMarkers(_focusedDay);
          await _fetchMuhuratForDate(_selectedDay);
        },
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Location Selector
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: goldColor, size: 20),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _selectedCityName, 
                            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton(
                    onPressed: _showLocationSelector,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      backgroundColor: goldColor.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                    ),
                    child: Text('Change Location', style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: goldColor)),
                  ),
                ],
              ),
            ),
            
            _buildCalendar(isDark, cardColor, textColor),
            SizedBox(height: 28.h),
            
            if (_isLoading)
              Center(child: Padding(
                padding: EdgeInsets.all(32.0.w),
                child: CircularProgressIndicator(color: goldColor, strokeWidth: 3),
              ))
            else ...[
              _buildSunriseSunset(isDark),
              SizedBox(height: 24.h),
              
              _buildPanchangaCard(isDark, cardColor, textColor),
              SizedBox(height: 32.h),
              
              Text('Specific Categories', style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w700, color: textColor)),
              SizedBox(height: 16.h),
              ...(_muhurat!['categories'] as List<dynamic>).map((cat) => _buildCategoryCard(cat, isDark, cardColor, textColor)),
              
              SizedBox(height: 32.h),
              Text('General Timings', style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w700, color: textColor)),
              SizedBox(height: 16.h),
              _buildGeneralTimings(isDark, cardColor, textColor),

              SizedBox(height: 32.h),
              Text('Choghadiya', style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w700, color: textColor)),
              SizedBox(height: 16.h),
              _buildChoghadiyaTable(isDark, cardColor, textColor),

              SizedBox(height: 32.h),
              Text('Hora (Planetary Hours)', style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w700, color: textColor)),
              SizedBox(height: 16.h),
              _buildHoraTable(isDark, cardColor, textColor),
              
              SizedBox(height: 40.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDark, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _fetchMuhuratForDate(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _fetchMonthMarkers(focusedDay);
        },
        eventLoader: (day) {
          final dateStr = DateFormat('yyyy-MM-dd').format(day);
          if (_auspiciousDates.contains(dateStr)) return ['Auspicious'];
          return [];
        },
        calendarStyle: CalendarStyle(
          markerDecoration: BoxDecoration(color: goldColor, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: goldColor.withValues(alpha: 0.5), width: 1.5.w),
          ),
          todayTextStyle: TextStyle(color: isDark ? goldColor : const Color(0xFFB8860B), fontWeight: FontWeight.bold),
          defaultTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textColor),
          leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
          rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
        ),
      ),
    );
  }

  Widget _buildSunriseSunset(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text(
            _muhurat!['date'],
            style: GoogleFonts.outfit(fontSize: 22.sp, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.1),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSunItem(Icons.wb_sunny_outlined, 'Sunrise', _muhurat!['sunrise'], const Color(0xFFFFD54F)),
              Container(width: 1.w, height: 40.h, color: Colors.white.withValues(alpha: 0.2)),
              _buildSunItem(Icons.nightlight_round, 'Sunset', _muhurat!['sunset'], const Color(0xFF9FA8DA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunItem(IconData icon, String label, String time, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        SizedBox(height: 8.h),
        Text(label.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12.sp, letterSpacing: 1.0, fontWeight: FontWeight.w500)),
        SizedBox(height: 4.h),
        Text(time, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPanchangaCard(bool isDark, Color cardColor, Color textColor) {
    final p = _muhurat!['panchanga'];
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: goldColor),
              SizedBox(width: 8.w),
              Text("Today's Panchanga", style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          Divider(color: Colors.grey.withValues(alpha: 0.2), height: 30.h),
          _buildConditionRow('Vara (Day)', p['vara'], isDark),
          _buildConditionRow('Tithi', p['tithi'], isDark),
          _buildConditionRow('Nakshatra', p['nakshatra'], isDark),
          _buildConditionRow('Yoga', p['yoga'], isDark),
          _buildConditionRow('Karana', p['karana'], isDark),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, bool isDark, Color cardColor, Color textColor) {
    final statusColor = _getStatusColor(cat['status']);
    int rating = cat['rating'] ?? 3;
    
    return GestureDetector(
      onTap: () => _showMuhuratDetails(cat),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.stars_rounded, color: statusColor, size: 28),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat['category'], style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor)),
                  SizedBox(height: 4.h),
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: index < rating ? goldColor : Colors.grey,
                      size: 16,
                    )),
                  ),
                  SizedBox(height: 6.h),
                  Text(cat['time'], style: GoogleFonts.outfit(fontSize: 14.sp, color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20.r)),
              child: Text(cat['status'], style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTimings(bool isDark, Color cardColor, Color textColor) {
    final gen = _muhurat!['general_timings'];
    return Column(
      children: [
        _buildTimingRow('Abhijit Muhurta', gen['abhijit']['start'] + ' - ' + gen['abhijit']['end'], const Color(0xFF4CAF50), cardColor, textColor),
        _buildTimingRow('Rahu Kaal', gen['rahu']['start'] + ' - ' + gen['rahu']['end'], const Color(0xFFE53935), cardColor, textColor),
        _buildTimingRow('Yamaganda', gen['yama']['start'] + ' - ' + gen['yama']['end'], const Color(0xFFE53935), cardColor, textColor),
        _buildTimingRow('Gulika Kaal', gen['gulika']['start'] + ' - ' + gen['gulika']['end'], const Color(0xFF5E35B1), cardColor, textColor),
      ],
    );
  }

  Widget _buildTimingRow(String title, String time, Color color, Color cardColor, Color textColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w600, color: textColor)),
          Text(time, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildChoghadiyaTable(bool isDark, Color cardColor, Color textColor) {
    final list = _muhurat!['choghadiya'] as List<dynamic>;
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        children: list.map((c) {
          final isAuspicious = c['is_auspicious'] as bool;
          return ListTile(
            leading: Icon(isAuspicious ? Icons.check_circle : Icons.cancel, color: isAuspicious ? Colors.green : Colors.red),
            title: Text(c['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Text(c['type'], style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54)),
            trailing: Text(c['time'], style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHoraTable(bool isDark, Color cardColor, Color textColor) {
    final list = _muhurat!['hora'] as List<dynamic>;
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        children: list.map((h) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: goldColor.withValues(alpha: 0.2),
              child: Icon(Icons.language, color: goldColor, size: 20),
            ),
            title: Text('${h['planet']} Hora', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Text(h['type'], style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54)),
            trailing: Text(h['time'], style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor)),
          );
        }).toList(),
      ),
    );
  }
}
