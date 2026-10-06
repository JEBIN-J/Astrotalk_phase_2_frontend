import re

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_frontend/astro_app/lib/screens/kp_system_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

legend_func = '''
  Widget _buildLegend(bool isDark) {
    Widget buildLegendItem(String label, Color bgColor, Color textColor) {
      return Container(
        margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 4.h,
        children: [
          buildLegendItem('Very Good', const Color(0xFF166534), Colors.white), // Dark Green
          buildLegendItem('Good', const Color(0xFF22C55E), Colors.white), // Medium Green
          buildLegendItem('Mild Good', const Color(0xFF86EFAC), Colors.black87), // Light Green
          buildLegendItem('Conjunction', const Color(0xFFFDE047), const Color(0xFF1E3A8A)), // Yellow
          buildLegendItem('Very Evil', const Color(0xFFDC2626), Colors.white), // Red
          buildLegendItem('Mild Evil', const Color(0xFFFCA5A5), Colors.black87), // Light Red
        ],
      ),
    );
  }
'''

# We need to insert this helper method inside _KPSystemViewState
# We'll inject it just before _buildPlanetAspectsTable
if '_buildLegend' not in code:
    code = code.replace('  Widget _buildPlanetAspectsTable', legend_func + '\n  Widget _buildPlanetAspectsTable')

# Now modify the return statement of _buildPlanetAspectsTable
pattern = re.compile(r'    return Container\(\s*decoration: BoxDecoration\(\s*color:(.*?)child: hasText \? content : const SizedBox\(\),\s*\);\s*}\)\.toList\(\),\s*\);\s*}\)\.toList\(\),\s*],\s*\),\s*\),\s*\),\s*],\s*\),\s*\),\s*\);', re.DOTALL)

def replacer(match):
    original_container = match.group(0)
    # Wrap it in a Column
    new_code = f'''    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        {original_container},
        _buildLegend(isDark),
      ],
    );'''
    return new_code

new_code = pattern.sub(replacer, code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_code)
print('Updated kp_system_view.dart with legend')
