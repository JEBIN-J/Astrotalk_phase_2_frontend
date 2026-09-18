# -*- coding: utf-8 -*-
import re

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'r', encoding='utf-8') as f:
    content = f.read()

def inject_rp(match):
    return '''    # Vedic Day Lord
    WEEKDAY_LORDS = ["Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Sun"]
    offset = 0 if (tob_parts[0] + tob_parts[1] / 60.0) >= 6.0 else -1
    day_idx = (birth_dt + timedelta(days=offset)).weekday()
    day_lord = WEEKDAY_LORDS[day_idx]
    
    moon_kp = next((p for p in planets_list if p["name"] == "Moon"), planets_list[0])

    ruling_planets = {
        "lagna_rashi_lord": planets_list[0]["rashi_lord"],
        "lagna_nakshatra_lord": planets_list[0]["nakshatra_lord"],
        "moon_rashi_lord": moon_kp["rashi_lord"],
        "moon_nakshatra_lord": moon_kp["nakshatra_lord"],
        "day_lord": day_lord
    }

    return {
        "status": "success",
        "ruling_planets": ruling_planets,
'''

content = re.sub(r'    return \{\n        "status": "success",\n', inject_rp, content)

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'w', encoding='utf-8') as f:
    f.write(content)
