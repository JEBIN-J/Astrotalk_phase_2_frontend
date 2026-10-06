import os

path = 'c:/Users/USER/Desktop/FJ Fusion/Astrotalk_phase_2/Astrotalk_phase_2_backend/app/services/kp_engine.py'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# Fix the KeyError for 'desc'
code = code.replace('"description": asp["desc"]', '"description": asp.get("desc", "")')

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
print('Fixed backend crash')
