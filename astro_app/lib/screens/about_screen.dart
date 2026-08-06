import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'About ABC App',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 44),
                ),
                const SizedBox(height: 14),
                Text('ABC App', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800)),
                Text('Advanced Vedic Astrology & Panchanga Platform', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Version 2.4.0 (Build 2026.08)', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Engine Specifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildInfoTile('Calculation Core', 'Swiss Ephemeris v2.10 High Precision Engine', isDark),
          _buildInfoTile('Ayanamsa Precision', 'Lahiri (Chitra Paksha) with 0.001" arcsecond precision', isDark),
          _buildInfoTile('Panchanga Algorithm', 'Traditional 5-Anga Surya Siddhanta + Modern Ephemeris', isDark),
          _buildInfoTile('Kundli Milan', '36 Guna Ashtakoota with Nadi & Bhakoot dosha cancellation', isDark),
          const SizedBox(height: 20),

          Text('Legal & Privacy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildActionTile('Privacy Policy', Icons.privacy_tip_outlined, isDark),
          _buildActionTile('Terms of Service', Icons.description_outlined, isDark),
          _buildActionTile('Open Source Licenses', Icons.code_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3B82F6))),
          const SizedBox(height: 3),
          Text(desc, style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        title: Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () {},
      ),
    );
  }
}
