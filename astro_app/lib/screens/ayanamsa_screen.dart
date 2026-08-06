import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/celestial_animations.dart';

class AyanamsaScreen extends StatefulWidget {
  const AyanamsaScreen({super.key});

  @override
  State<AyanamsaScreen> createState() => _AyanamsaScreenState();
}

class _AyanamsaScreenState extends State<AyanamsaScreen> {
  DateTime _calculationDate = DateTime.now();
  String _selectedSystem = 'Lahiri (Chitra Paksha)';

  final Map<String, String> _ayanamsaValues = {
    'Lahiri (Chitra Paksha)': '24° 13\' 44.8"',
    'Krishnamurti (KP)': '24° 07\' 22.1"',
    'B.V. Raman': '22° 49\' 18.0"',
    'Fagan / Bradley': '25° 02\' 11.4"',
    'Yukteshwar': '21° 53\' 29.5"',
    'True Chitra / Spica': '24° 14\' 02.2"',
    'Hipparchus': '22° 10\' 00.0"',
    'Suryasiddhanta': '23° 46\' 12.0"',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Ayanamsa Calculator',
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
          // Active Ayanamsa Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Offset: $_selectedSystem', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _ayanamsaValues[_selectedSystem] ?? '24° 13\' 44.8"',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Epoch Date: ${DateFormat('d MMMM yyyy').format(_calculationDate)} (Speed: 50.29"/yr)',
                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date Selector Button
          BouncyTouchCard(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _calculationDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _calculationDate = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.date_range_rounded, color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 8),
                  Text('Change Calculation Epoch Date', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Ayanamsa System List
          Text('Available Ayanamsa Systems', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._ayanamsaValues.entries.toList().asMap().entries.map((mapEntry) {
            final idx = mapEntry.key;
            final entry = mapEntry.value;
            final isSelected = entry.key == _selectedSystem;

            return StaggeredAnimatedItem(
              index: idx,
              child: BouncyTouchCard(
                onTap: () {
                  setState(() {
                    _selectedSystem = entry.key;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF059669)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? const Color(0xFF059669) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.key,
                            style: GoogleFonts.outfit(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF059669))
                                  : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        entry.value,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
