# -*- coding: utf-8 -*-
import re

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'r', encoding='utf-8') as f:
    content = f.read()

def replacer(match):
    return '''    # D9 Navamsa Chart Data
    def get_navamsa_degree(deg):
        deg_in_sign = deg % 30.0
        nav_deg = (deg_in_sign % (30.0 / 9.0)) * 9.0
        d = int(nav_deg)
        m = int((nav_deg - d) * 60)
        return f\"{d:02d}\u00b0 {m:02d}'\"

    d9_chart = {
        \"ascendant_sign_index\": asc_nav_sign,
        \"planets\": [
            {
                \"planet\": p[\"name\"],
                \"name\": p[\"name\"],
                \"sign_index\": p[\"navamsha_sign_index\"],
                \"house\": ((p[\"navamsha_sign_index\"] - asc_nav_sign) % 12) + 1,
                \"degree_formatted\": get_navamsa_degree(p[\"longitude\"]),
                \"is_retrograde\": p[\"is_retrograde\"],
                \"status_marker\": \" (R)\" if p[\"is_retrograde\"] else \"\",
                \"rl\": p.get(\"rl\", \"\"),
                \"nl\": p.get(\"nl\", \"\"),
                \"sl\": p.get(\"sl\", \"\"),
                \"ssl\": p.get(\"ssl\", \"\"),
                \"sign\": ZODIAC_SIGNS[p[\"navamsha_sign_index\"] - 1][\"name\"]
            } for p in planets_list
        ]
    }'''

content = re.sub(r'    # D9 Navamsa Chart Data.*?    \}', replacer, content, flags=re.DOTALL)

with open(r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py', 'w', encoding='utf-8') as f:
    f.write(content)
