file_path = r'..\Astrotalk_phase_2_backend\app\services\vedic_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix ayanamsa_formatted in accuracy_metadata (line ~3133)
old_fmt1 = '        "ayanamsa_formatted": f"{ayanamsa} {degree_to_sign_and_dms(ayanamsa)[2]}",\n        "coordinate_source"'
new_fmt1 = '        "ayanamsa_formatted": f"{ayanamsa_display} {round(ayanamsa, 4)}\u00b0",\n        "coordinate_source"'
content = content.replace(old_fmt1, new_fmt1)

# Fix ayanamsa_formatted in main return dict (line ~3151)
old_fmt2 = '        "ayanamsa_formatted": f"{ayanamsa} {degree_to_sign_and_dms(ayanamsa)[2]}",\n        "ascendant_lagna"'
new_fmt2 = '        "ayanamsa_formatted": f"{ayanamsa_display} {degree_to_sign_and_dms(ayanamsa)[2]}",\n        "ascendant_lagna"'
content = content.replace(old_fmt2, new_fmt2)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Verify 
found = 'ayanamsa_formatted' in content
print(f'ayanamsa_formatted fixed: {found}')
# Count remaining hardcoded references
import re
leftovers = re.findall(r'"Lahiri', content)
print(f'Remaining hardcoded Lahiri string refs: {len(leftovers)}')
for m in leftovers[:5]:
    print(m)
