file_path = r'..\Astrotalk_phase_2_backend\app\services\vedic_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix BL, HL, GL, VGL
content = content.replace('bl_deg = (sun_deg + (time_from_sun * 15.0)) % 360.0', 'bl_deg = (sun_sunrise_deg + (time_from_sun * 15.0)) % 360.0')
content = content.replace('hl_deg = (sun_deg + (time_from_sun * 30.0)) % 360.0', 'hl_deg = (sun_sunrise_deg + (time_from_sun * 30.0)) % 360.0')
content = content.replace('gl_deg = (sun_deg + (time_from_sun * 75.0)) % 360.0', 'gl_deg = (sun_sunrise_deg + (time_from_sun * 75.0)) % 360.0')
content = content.replace('vgl_deg = (sun_deg + (time_from_sun * 4500.0)) % 360.0', 'vgl_deg = (sun_sunrise_deg + (time_from_sun * 4500.0)) % 360.0')

# Fix Pranapada
pl_old1 = 'sun_sign_idx = int(sun_deg // 30) + 1'
pl_new1 = 'sun_sign_idx = int(sun_sunrise_deg // 30) + 1'
content = content.replace(pl_old1, pl_new1)

pl_old2 = 'pl_deg = (sun_deg + base_x + offset) % 360.0'
pl_new2 = 'pl_deg = (sun_sunrise_deg + base_x + offset) % 360.0'
content = content.replace(pl_old2, pl_new2)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched vedic_engine.py for Special Lagnas')
