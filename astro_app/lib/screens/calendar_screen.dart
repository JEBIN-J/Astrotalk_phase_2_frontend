import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/celestial_animations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDay = 15;
  int _monthIndex = 2; // March 2026
  final List<String> _months = [
    'Pausha 2082 (Jan 2026)',
    'Magha 2082 (Feb 2026)',
    'Phalguna 2083 (March 2026)',
    'Chaitra 2083 (April 2026)',
    'Vaishakha 2083 (May 2026)',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMonth = _months[_monthIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Monthly Panchanga Calendar',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Month Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF2DD4BF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    if (_monthIndex > 0) {
                      setState(() => _monthIndex--);
                    }
                  },
                ),
                Flexible(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(currentMonth, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Text('Shukla & Krishna Paksha Vrats', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 11.5)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    if (_monthIndex < _months.length - 1) {
                      setState(() => _monthIndex++);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Day of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 31,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final isSelected = dayNum == _selectedDay;
              final isSpecial = dayNum == 11 || dayNum == 15 || dayNum == 26; // Ekadashi, Purnima, Pradosh

              return BouncyTouchCard(
                onTap: () {
                  setState(() {
                    _selectedDay = dayNum;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0D9488)
                        : (isSpecial
                            ? const Color(0xFF0D9488).withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2DD4BF)
                          : (isSpecial ? const Color(0xFF0D9488) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      if (isSpecial) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF0D9488),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Selected Day Detail Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Day $_selectedDay March 2026 Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Shukla Paksha', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDayDetailRow('Tithi', 'Shukla Ekadashi (Padmini Ekadashi Vrat)', isDark),
                _buildDayDetailRow('Nakshatra', 'Pushya (Lord: Saturn) upto 09:12 PM', isDark),
                _buildDayDetailRow('Yoga', 'Saubhagya Yoga (Lord: Brahma)', isDark),
                _buildDayDetailRow('Karana', 'Vanija Karana', isDark),
                _buildDayDetailRow('Fasting / Vrat', 'Special Ekadashi Fasting & Vishnu Sahasranama chanting', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
