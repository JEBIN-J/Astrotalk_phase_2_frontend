import sys
path = r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('"occupants": occupants,', '"occupants": occupants,\n            "navamsha_sign_index": calculate_navamsha_sign(c_deg),')
with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
