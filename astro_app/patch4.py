# -*- coding: utf-8 -*-
import re

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'r', encoding='utf-8') as f:
    content = f.read()

def replacer_planets(match):
    return '''        ("Saturn", swe.SATURN if SWISSEPH_AVAILABLE else 6),
        ("Uranus", swe.URANUS if SWISSEPH_AVAILABLE else 7),
        ("Neptune", swe.NEPTUNE if SWISSEPH_AVAILABLE else 8),
        ("Pluto", swe.PLUTO if SWISSEPH_AVAILABLE else 9),
        ("Rahu", swe.MEAN_NODE if SWISSEPH_AVAILABLE else 10)'''

content = re.sub(r'        \(\"Saturn\"\, swe\.SATURN if SWISSEPH_AVAILABLE else 6\),\n        \(\"Rahu\"\, swe\.MEAN_NODE if SWISSEPH_AVAILABLE else 10\)', replacer_planets, content)

def replacer_fortuna(match):
    return '''    moon_lon = 0.0
    sun_lon = 0.0

    for p in raw_planets:
        if p["name"] == "Sun":
            sun_lon = p["longitude"]'''

content = content.replace('''    moon_lon = 0.0

    for p in raw_planets:''', replacer_fortuna(''))

def replacer_fortuna2(match):
    return '''        if p_name == "Moon":
            moon_lon = p_deg
        if p_name == "Sun":
            sun_lon = p_deg'''

content = content.replace('''        if p_name == "Moon":
            moon_lon = p_deg''', replacer_fortuna2(''))

def replacer_fortuna_add(match):
    return '''            "color": PLANET_COLORS.get(p_name, "#4338CA")
        })

    # Add Fortuna (Pars Fortuna) -> Ascendant + Moon - Sun
    fortuna_deg = (asc_deg + moon_lon - sun_lon) % 360.0
    f_kp = calculate_kp_sub_lords(fortuna_deg)
    f_nav_sign = calculate_navamsha_sign(fortuna_deg)
    f_house = find_house_for_degree(fortuna_deg, cusp_degrees)
    
    planets_list.append({
        "name": "Fortuna",
        "planet_name_simple": "Fortuna",
        "display_name": "Fortuna",
        "table_display_name": "Fortuna",
        "sanskrit_name": "Fortuna",
        "longitude": fortuna_deg,
        "sign": f_kp["sign_name"],
        "sign_index": f_kp["sign_index"],
        "sign_sanskrit": f_kp["sign_sanskrit"],
        "house": f_house,
        "degree_formatted": f_kp["degree_formatted"],
        "degree_decimal": round(fortuna_deg, 4),
        "nakshatra": f_kp["nakshatra_name"],
        "nakshatra_lord": f_kp["nakshatra_lord"],
        "pada": f_kp["pada"],
        "rl": f_kp["rl"],
        "nl": f_kp["nl"],
        "sl": f_kp["sl"],
        "ssl": f_kp["ssl"],
        "rashi_lord": f_kp["rashi_lord"],
        "sub_lord": f_kp["sub_lord"],
        "sub_sub_lord": f_kp["sub_sub_lord"],
        "is_retrograde": False,
        "speed": 0.0,
        "navamsha_sign_index": f_nav_sign,
        "color": PLANET_COLORS.get("Fortuna", "#4338CA")
    })

    cusps_info = []'''

content = content.replace('''            "color": PLANET_COLORS.get(p_name, "#4338CA")
        })

    cusps_info = []''', replacer_fortuna_add(''))


with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'w', encoding='utf-8') as f:
    f.write(content)
