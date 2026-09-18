# -*- coding: utf-8 -*-
import re

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'r', encoding='utf-8') as f:
    content = f.read()

def replacer(match):
    return '''    # D9 Navamsa Chart Data
    def get_navamsa_data(deg, nav_sign_idx):
        deg_in_sign = deg % 30.0
        nav_deg = (deg_in_sign % (30.0 / 9.0)) * 9.0
        abs_nav_deg = (nav_sign_idx - 1) * 30.0 + nav_deg
        return calculate_kp_sub_lords(abs_nav_deg)

    d9_chart = {
        "ascendant_sign_index": asc_nav_sign,
        "planets": [
            {
                "planet": p["name"],
                "name": p["name"],
                "sign_index": p["navamsha_sign_index"],
                "house": ((p["navamsha_sign_index"] - asc_nav_sign) % 12) + 1,
                "degree_formatted": get_navamsa_data(p["longitude"], p["navamsha_sign_index"])["degree_formatted"],
                "is_retrograde": p["is_retrograde"],
                "status_marker": " (R)" if p["is_retrograde"] else "",
                "rl": get_navamsa_data(p["longitude"], p["navamsha_sign_index"])["rl"],
                "nl": get_navamsa_data(p["longitude"], p["navamsha_sign_index"])["nl"],
                "sl": get_navamsa_data(p["longitude"], p["navamsha_sign_index"])["sl"],
                "ssl": get_navamsa_data(p["longitude"], p["navamsha_sign_index"])["ssl"],
                "sign": ZODIAC_SIGNS[p["navamsha_sign_index"] - 1]["name"],
                "nakshatra": get_navamsa_data(p["longitude"], p["navamsha_sign_index"])["nakshatra_name"],
                "pada": get_navamsa_data(p["longitude"], p["navamsha_sign_index"])["pada"]
            } for p in planets_list
        ]
    }'''

content = re.sub(r'    # D9 Navamsa Chart Data.*?    \}', replacer, content, flags=re.DOTALL)

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'w', encoding='utf-8') as f:
    f.write(content)
