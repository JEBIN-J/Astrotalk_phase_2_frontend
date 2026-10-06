import os

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_frontend/astro_app/lib/screens/kp_system_view.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# Fix the duplicate 'return'
code = code.replace('''    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            return Container(''', '''    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(''')

# Fix the trailing semicolon comma
code = code.replace('''    );,
        _buildLegend(isDark),''', '''    ),
        _buildLegend(isDark),''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
print('Fixed syntax errors')
