path = r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\services\kp_engine.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_str = '"degree_formatted": get_navamsa_deg(p["longitude"]),'
new_str = '"degree_formatted": p.get("degree_formatted", "-"),'
content = content.replace(old_str, new_str)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
