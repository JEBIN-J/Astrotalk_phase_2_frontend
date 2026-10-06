import os
import re

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_backend/app/services/kp_engine.py'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

new_aspects = '''    ASPECT_DEFINITIONS = [
        {"name": "Conjunction", "short_name": "Conj", "angle": 0.0, "orb": 15.0, "nature": "Yellow"},
        {"name": "Vigintile", "short_name": "Vigi", "angle": 18.0, "orb": 2.0, "nature": "Green"},
        {"name": "Quin-decile", "short_name": "Qdec", "angle": 24.0, "orb": 2.0, "nature": "Green"},
        {"name": "Semi-Sextile", "short_name": "Semi", "angle": 30.0, "orb": 2.0, "nature": "Green"},
        {"name": "Semi-quintile", "short_name": "Squi", "angle": 36.0, "orb": 2.0, "nature": "Green"},
        {"name": "Semi-Square", "short_name": "Ssqu", "angle": 45.0, "orb": 4.0, "nature": "LightRed"},
        {"name": "Degrees 54", "short_name": "D54", "angle": 54.0, "orb": 2.0, "nature": "LightRed"},
        {"name": "Sextile", "short_name": "Sext", "angle": 60.0, "orb": 6.0, "nature": "Green"},
        {"name": "Quintile", "short_name": "Quin", "angle": 72.0, "orb": 4.0, "nature": "Green"},
        {"name": "Square", "short_name": "Squr", "angle": 90.0, "orb": 9.0, "nature": "Red"},
        {"name": "Tredecile", "short_name": "Tred", "angle": 108.0, "orb": 3.0, "nature": "Green"},
        {"name": "Trine", "short_name": "Trin", "angle": 120.0, "orb": 9.0, "nature": "DarkGreen"},
        {"name": "Degrees 126", "short_name": "D126", "angle": 126.0, "orb": 2.0, "nature": "DarkGreen"},
        {"name": "Sesquiquadrate", "short_name": "Ssqu", "angle": 135.0, "orb": 3.0, "nature": "LightRed"},
        {"name": "Bi-quintile", "short_name": "Bqui", "angle": 144.0, "orb": 3.0, "nature": "DarkGreen"},
        {"name": "Quincunx", "short_name": "Quin", "angle": 150.0, "orb": 3.0, "nature": "Red"},
        {"name": "Degree 162", "short_name": "D162", "angle": 162.0, "orb": 2.0, "nature": "Green"},
        {"name": "Opposition", "short_name": "Oppn", "angle": 180.0, "orb": 15.0, "nature": "Red"}
    ]'''

pattern = re.compile(r'    ASPECT_DEFINITIONS = \[.*?\]', re.DOTALL)
new_code = pattern.sub(new_aspects, code)

# Also ensure Ascendant is passed to calculate_kp_aspects
target = '''    aspects_data = calculate_kp_aspects(
        [p for p in planets_list if p["name"] != "Ascendant"],
        cusps_info
    )'''
replacement = '''    aspects_data = calculate_kp_aspects(
        planets_list,
        cusps_info
    )'''
if target in new_code:
    new_code = new_code.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_code)
print('Updated kp_engine.py with new aspects')
