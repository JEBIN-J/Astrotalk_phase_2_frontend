import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const SettingsScreen({
    super.key,
    this.onToggleTheme,
    this.isDark = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _chartStyle = 'North Indian (उत्तर)';
  String _ayanamsa = 'Lahiri (Chitra Paksha)';
  String _language = 'English (English)';
  bool _notifyRahuKaal = true;
  bool _notifyTithi = false;
  bool _highPrecisionEphemeris = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Settings & Preferences',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Astrological Calculations'),
          _buildSelectTile('Default Kundli Format', _chartStyle, ['North Indian (उत्तर)', 'South Indian (दक्षिण)', 'East Indian (सूर्य)'], (v) => setState(() => _chartStyle = v), isDark),
          _buildSelectTile('Default Ayanamsa', _ayanamsa, ['Lahiri (Chitra Paksha)', 'Krishnamurti (KP)', 'B.V. Raman', 'Fagan / Bradley'], (v) => setState(() => _ayanamsa = v), isDark),
          _buildSwitchTile('High Precision Swiss Ephemeris (0.01")', _highPrecisionEphemeris, (v) => setState(() => _highPrecisionEphemeris = v), isDark),
          const SizedBox(height: 16),

          _buildSectionHeader('Localization & Appearance'),
          _buildSelectTile('Language', _language, ['English (English)', 'Hindi (हिन्दी)', 'Tamil (தமிழ்)', 'Telugu (తెలుగు)', 'Marathi (मराठी)'], (v) => setState(() => _language = v), isDark),
          _buildActionTile('Dark Mode Theme', isDark ? 'Active (Cosmic Midnight)' : 'Active (Celestial Light)', Icons.dark_mode_rounded, widget.onToggleTheme, isDark),
          const SizedBox(height: 16),

          _buildSectionHeader('Daily Notifications & Alerts'),
          _buildSwitchTile('Rahu Kaal Daily Alert (15 min prior)', _notifyRahuKaal, (v) => setState(() => _notifyRahuKaal = v), isDark),
          _buildSwitchTile('Daily Tithi & Nakshatra Change Notice', _notifyTithi, (v) => setState(() => _notifyTithi = v), isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1), letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSelectTile(String title, String currentVal, List<String> options, ValueChanged<String> onChanged, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: currentVal,
            underline: const SizedBox(),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF4338CA),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback? onTap, bool isDark, {Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFF4338CA)),
        title: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
