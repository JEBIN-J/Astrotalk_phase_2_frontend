import re

path = r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the get_navamsa_data function
old_func = '''    def get_navamsa_data(deg, nav_sign_idx):
        deg_in_sign = deg % 30.0
        nav_deg = (deg_in_sign % (30.0 / 9.0)) * 9.0
        abs_nav_deg = (nav_sign_idx - 1) * 30.0 + nav_deg
        return calculate_kp_sub_lords(abs_nav_deg)'''

new_func = '''    def get_navamsa_deg(deg):
        deg_in_sign = deg % 30.0
        nav_deg = (deg_in_sign % (30.0 / 9.0)) * 9.0
        return format_deg_in_sign(nav_deg)'''

content = content.replace(old_func, new_func)

# Replace the D9 Chart definition
old_dict = '''    d9_chart = {
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

new_dict = '''    d9_chart = {
        "ascendant_sign_index": asc_nav_sign,
        "planets": [
            {
                "planet": p["name"],
                "name": p["name"],
                "sign_index": p["navamsha_sign_index"],
                "house": ((p["navamsha_sign_index"] - asc_nav_sign) % 12) + 1,
                "degree_formatted": get_navamsa_deg(p["longitude"]),
                "is_retrograde": p["is_retrograde"],
                "status_marker": " (R)" if p["is_retrograde"] else "",
                "rl": p.get("rl", "-"),
                "nl": p.get("nl", "-"),
                "sl": p.get("sl", "-"),
                "ssl": p.get("ssl", "-"),
                "sign": ZODIAC_SIGNS[p["navamsha_sign_index"] - 1]["name"],
                "nakshatra": p.get("nakshatra", "-"),
                "pada": p.get("pada", "-")
            } for p in planets_list
        ]
    }'''

content = content.replace(old_dict, new_dict)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
