import sys
import glob
files = ['..\Astrotalk_phase_2_backend\app\services\bnn_engine.py',
         '..\Astrotalk_phase_2_backend\app\services\lal_kitab_engine.py',
         '..\Astrotalk_phase_2_backend\app\services\kota_engine.py']

for file_path in files:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # We need to replace generate_full_kundli(name, dob_str, tob_str, pob_str, latitude, longitude, timezone)
        # with generate_full_kundli(name, dob_str, tob_str, pob_str, latitude, longitude, timezone, ayanamsa=ayanamsa, custom_ayanamsa=custom_ayanamsa)
        
        # Be careful not to replace already patched ones or transit ones without ayanamsa in scope
        # Actually, let's just do a regex replace for the standard call
        import re
        
        # Add ayanamsa to def if missing (for lal_kitab and kota)
        def_pattern = re.compile(r'(def generate_[a-z_]+\([\s\S]*?timezone: float)(\s*\))')
        if 'ayanamsa: str = "LAHIRI"' not in content:
            content = def_pattern.sub(r'\1,\n    ayanamsa: str = "LAHIRI",\n    custom_ayanamsa: float = None\2', content)
            
        call_pattern = re.compile(r'(generate_full_kundli\([^)]*latitude,\s*longitude,\s*timezone)(\))')
        content = call_pattern.sub(r'\1, ayanamsa=ayanamsa, custom_ayanamsa=custom_ayanamsa\2', content)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Patched', file_path)
    except Exception as e:
        print('Error in', file_path, e)
