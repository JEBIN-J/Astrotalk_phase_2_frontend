file_path = r'..\Astrotalk_phase_2_backend\app\services\vedic_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add threading lock import after existing imports
old_import = '''import math
from datetime import datetime, timedelta
from typing import Dict, List, Any, Tuple, Optional'''

new_import = '''import math
import threading
from datetime import datetime, timedelta
from typing import Dict, List, Any, Tuple, Optional

# Global lock to protect the non-thread-safe swe.set_sid_mode() / swe.get_ayanamsa_ut() sequence
_SWE_AYANAMSA_LOCK = threading.Lock()'''

content = content.replace(old_import, new_import)

# Wrap the set_sid_mode + get_ayanamsa_ut calls inside the lock
old_lock = '''        mode = SWE_MAP[ayanamsa_key]
        swe.set_sid_mode(mode)
        return swe.get_ayanamsa_ut(jd)'''

new_lock = '''        mode = SWE_MAP[ayanamsa_key]
        with _SWE_AYANAMSA_LOCK:
            swe.set_sid_mode(mode)
            return swe.get_ayanamsa_ut(jd)'''

content = content.replace(old_lock, new_lock)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Thread safety lock added to vedic_engine.py')
