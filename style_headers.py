import re

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_frontend/astro_app/lib/screens/kp_system_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace header colors
code = code.replace(
    'final headerBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);',
    'final headerBgColor = isDark ? const Color(0xFF422006) : const Color(0xFFFEF9C3); // Premium Gold/Yellow\n    final headerTextColor = isDark ? const Color(0xFFFEF08A) : const Color(0xFF854D0E);'
)

# Update the Planet header text
code = code.replace(
    "child: Text('Planet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.sp, color: isDark ? Colors.white70 : const Color(0xFF475569))),",
    "child: Text('Planet', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.sp, color: headerTextColor)),"
)

# Update the side headers text
code = code.replace(
    "child: Text(rName == 'Ascendant' ? 'Lagna' : _getLordShort(rName), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B))),",
    "child: Text(rName == 'Ascendant' ? 'Lagna' : _getLordShort(rName), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.sp, color: headerTextColor)),"
)

# Update the top headers text
code = code.replace(
    "child: Text(_getLordShort(cName), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B))),",
    "child: Text(_getLordShort(cName), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.sp, color: headerTextColor)),"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
print('Updated header styles in kp_system_view.dart')
