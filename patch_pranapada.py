file_path = r'..\Astrotalk_phase_2_backend\app\services\vedic_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Line 529 - Pranapada in Upagrahas - remove FLG_SIDEREAL, manually subtract ayanamsa
old_pranapada = '''    if SWISSEPH_AVAILABLE and swe is not None:
        sun_sunrise_deg = swe.calc_ut(sunrise_jd, swe.SUN, swe.FLG_SWIEPH | swe.FLG_SIDEREAL)[0][0]
    else:
        sun_sunrise_deg = sun_deg'''

new_pranapada = '''    if SWISSEPH_AVAILABLE and swe is not None:
        sun_sunrise_trop = swe.calc_ut(sunrise_jd, swe.SUN, swe.FLG_SWIEPH)[0][0]
        sun_sunrise_deg = (sun_sunrise_trop - ayanamsa) % 360.0
    else:
        sun_sunrise_deg = sun_deg'''

if old_pranapada in content:
    content = content.replace(old_pranapada, new_pranapada)
    print('Fix 1 applied: Pranapada FLG_SIDEREAL removed')
else:
    print('Fix 1 NOT FOUND')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
