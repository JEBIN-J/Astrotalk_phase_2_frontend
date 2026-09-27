file_path = r'..\Astrotalk_phase_2_backend\app\services\kp_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add threading import
old_import = 'import math\nfrom datetime import datetime, timedelta\nfrom typing import Dict, List, Any, Tuple, Optional'
new_import = 'import math\nimport threading\nfrom datetime import datetime, timedelta\nfrom typing import Dict, List, Any, Tuple, Optional\n\n# Global lock for thread-safe swe.set_sid_mode() — shared with vedic_engine via import\ntry:\n    from app.services.vedic_engine import _SWE_AYANAMSA_LOCK\nexcept ImportError:\n    _SWE_AYANAMSA_LOCK = threading.Lock()'
content = content.replace(old_import, new_import, 1)

# Wrap the set_sid_mode call with the lock
old_try = '''        if matched_mode is not None:
            # Save + restore previous global mode to avoid polluting parallel calculations
            prev_mode = swe.get_ayanamsa_ut(jd)  # just read before changing
            try:
                swe.set_sid_mode(matched_mode)
                ayan_deg = swe.get_ayanamsa_ut(jd)
            except Exception:
                ayan_deg = prev_mode
            return ayan_deg, f"{matched_label} {format_dms(ayan_deg)}"'''

new_try = '''        if matched_mode is not None:
            try:
                with _SWE_AYANAMSA_LOCK:
                    swe.set_sid_mode(matched_mode)
                    ayan_deg = swe.get_ayanamsa_ut(jd)
            except Exception:
                ayan_deg = 23.85  # fallback to approx Lahiri
            return ayan_deg, f"{matched_label} {format_dms(ayan_deg)}"'''

if old_try in content:
    content = content.replace(old_try, new_try)
    print('Lock wrapped in kp_engine.py')
else:
    print('old_try not found')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('kp_engine.py updated.')
