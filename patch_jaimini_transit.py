import sys
file_path = r'..\Astrotalk_phase_2_backend\app\services\jaimini_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_call = 'transit_kundli = generate_full_kundli("Transit", now_str, time_str, pob_str, latitude, longitude, timezone)'
new_call = 'transit_kundli = generate_full_kundli("Transit", now_str, time_str, pob_str, latitude, longitude, timezone, ayanamsa=ayanamsa, custom_ayanamsa=custom_ayanamsa)'

if old_call in content:
    content = content.replace(old_call, new_call)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated jaimini transit call.')
else:
    print('old_call not found.')
