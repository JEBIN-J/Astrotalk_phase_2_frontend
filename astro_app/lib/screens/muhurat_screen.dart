import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/astro_api_service.dart';

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
  Set<String> _auspiciousDates = {};

  @override
  void initState() {
    super.initState();
    _fetchMonthMarkers(_focusedDay);
    _fetchMuhuratForDate(_selectedDay);
  }

  Future<void> _fetchMonthMarkers(DateTime month) async {
    final dates = await AstroApiService.getMuhuratMonth(month.year, month.month);
    if (mounted) {
      setState(() {
        _auspiciousDates.addAll(dates);
      });
    }
  }

  Future<void> _fetchMuhuratForDate(DateTime date) async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final data = await AstroApiService.getMuhurat(dateStr: dateStr);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Cosmic & Elegant Theme Colors
    final bgColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFF9F9FB);
    final cardColor = isDark ? const Color(0xFF161A25) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A24);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final goldColor = const Color(0xFFD4AF37); // Classic Astrology Gold
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Muhurat Explorer', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 22, color: textColor)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Calendar Section - PREMIUM ELEGANT
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF000000).withValues(alpha: 0.04),
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
                  if (_auspiciousDates.contains(dateStr)) {
                    return ['Auspicious'];
                  }
                  return [];
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: goldColor, // Gold markers for auspicious days
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: goldColor.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: goldColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  todayTextStyle: TextStyle(color: isDark ? goldColor : const Color(0xFFB8860B), fontWeight: FontWeight.bold),
                  defaultTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  weekendTextStyle: const TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.w500),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: textColor, size: 24),
                  rightChevronIcon: Icon(Icons.chevron_right, color: textColor, size: 24),
                ),
              ),
            ),
            
            const SizedBox(height: 28),
            
            if (_isLoading)
              Center(child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: goldColor, strokeWidth: 3),
              ))
            else ...[
              // Date and Sun Info - COSMIC GRADIENT
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF000000)], // Deep space gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2C3E50).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _muhurat?['date'] ?? DateFormat('yyyy-MM-dd').format(_selectedDay),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSunItem(Icons.wb_sunny_outlined, 'Sunrise', _muhurat?['sunrise'] ?? '--:--', const Color(0xFFFFD54F)),
                        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                        _buildSunItem(Icons.nightlight_round, 'Sunset', _muhurat?['sunset'] ?? '--:--', const Color(0xFF9FA8DA)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Specific Muhurats Categories
              if (_muhurat?['categories'] != null) ...[
                Text(
                  'Specific Categories',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                ...(_muhurat!['categories'] as Map<String, dynamic>).entries.map((entry) {
                  final catName = entry.key;
                  final catData = entry.value;
                  final status = catData['status'] as String;
                  
                  Color statusColor;
                  IconData icon;

                  switch (status.toLowerCase()) {
                    case 'auspicious':
                      statusColor = const Color(0xFF4CAF50);
                      icon = Icons.check_circle_outline_rounded;
                      break;
                    case 'inauspicious':
                      statusColor = const Color(0xFFE53935);
                      icon = Icons.cancel_outlined;
                      break;
                    default:
                      statusColor = goldColor;
                      icon = Icons.info_outline_rounded;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildElegantTimingCard(
                      title: catName,
                      time: catData['time'] ?? '',
                      subtitle: status,
                      icon: icon,
                      statusColor: statusColor,
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                    ),
                  );
                }),
                
                const SizedBox(height: 24),
              ],
              
              // General Timings
              Text(
                'General Timings (Daily)',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              if (_muhurat?['general'] != null) ...[
                _buildElegantTimingCard(
                  title: 'Abhijit Muhurta',
                  time: _muhurat!['general']['abhijit_muhurta'] ?? '--:--',
                  subtitle: 'Highly Auspicious',
                  icon: Icons.star_border_rounded,
                  statusColor: const Color(0xFF4CAF50),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildElegantTimingCard(
                  title: 'Rahu Kaal',
                  time: _muhurat!['general']['rahu_kaal'] ?? '--:--',
                  subtitle: 'Inauspicious',
                  icon: Icons.warning_amber_rounded,
                  statusColor: const Color(0xFFE53935),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildElegantTimingCard(
                  title: 'Yamaganda Kaal',
                  time: _muhurat!['general']['yamaganda'] ?? '--:--',
                  subtitle: 'Inauspicious',
                  icon: Icons.access_time_rounded,
                  statusColor: const Color(0xFFE53935),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildElegantTimingCard(
                  title: 'Gulika Kaal',
                  time: _muhurat!['general']['gulika_kaal'] ?? '--:--',
                  subtitle: 'Inauspicious',
                  icon: Icons.hourglass_empty_rounded,
                  statusColor: const Color(0xFF5E35B1),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSunItem(IconData icon, String label, String time, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, letterSpacing: 1.0, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildElegantTimingCard({
    required String title,
    required String time,
    required String subtitle,
    required IconData icon,
    required Color statusColor,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
