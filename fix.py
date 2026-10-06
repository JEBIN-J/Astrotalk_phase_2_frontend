import os

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_backend/app/services/kp_engine.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    aspects_data = calculate_kp_aspects(
        [p for p in planets_list if p["name"] != "Ascendant"],
        cusps_info
    )'''

replacement = '''    aspects_data = calculate_kp_aspects(
        planets_list,
        cusps_info
    )'''

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated kp_engine.py successfully.")
else:
    print("Target string not found in kp_engine.py.")
