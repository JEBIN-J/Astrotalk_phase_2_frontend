file_path = r'..\Astrotalk_phase_2_backend\app\services\kp_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_block = '''    if SWISSEPH_AVAILABLE and swe:
        if "KP Old" in norm or "Old" in norm:
            try:
                swe.set_sid_mode(44)
                ayan_deg = swe.get_ayanamsa_ut(jd)
                return ayan_deg, f"KP Old {format_dms(ayan_deg)}"
            except Exception:
                ayan_deg = (year_dec - 291.0) * (50.2388475 / 3600.0)
                return ayan_deg, f"KP Old {format_dms(ayan_deg)}"

        elif "KP New" in norm or "Krishnamurti" in norm:
            swe.set_sid_mode(swe.SIDM_KRISHNAMURTI)
            ayan_deg = swe.get_ayanamsa_ut(jd)
            return ayan_deg, f"KP New {format_dms(ayan_deg)}"

        elif "Raman" in norm:
            swe.set_sid_mode(swe.SIDM_RAMAN)
            ayan_deg = swe.get_ayanamsa_ut(jd)
            return ayan_deg, f"B.V. Raman {format_dms(ayan_deg)}"

        elif "Yukteswar" in norm:
            swe.set_sid_mode(swe.SIDM_YUKTESHWAR)
            ayan_deg = swe.get_ayanamsa_ut(jd)
            return ayan_deg, f"Sri Yukteswar {format_dms(ayan_deg)}"

        elif "Lahiri" in norm or "Chitapaksha" in norm:
            swe.set_sid_mode(swe.SIDM_LAHIRI)
            ayan_deg = swe.get_ayanamsa_ut(jd)
            return ayan_deg, f"Lahiri {format_dms(ayan_deg)}"'''

new_block = '''    if SWISSEPH_AVAILABLE and swe:
        SWE_MODE_MAP = {
            "KP Old":          44,
            "Old":             44,
            "KP New":          swe.SIDM_KRISHNAMURTI,
            "Krishnamurti":    swe.SIDM_KRISHNAMURTI,
            "Raman":           swe.SIDM_RAMAN,
            "Yukteswar":       swe.SIDM_YUKTESHWAR,
            "Lahiri":          swe.SIDM_LAHIRI,
            "Chitapaksha":     swe.SIDM_LAHIRI,
        }
        matched_mode = None
        matched_label = None
        for key, mode in SWE_MODE_MAP.items():
            if key in norm:
                matched_mode = mode
                if "Old" in key:
                    matched_label = "KP Old"
                elif "New" in key or "Krishnamurti" in key:
                    matched_label = "KP New"
                elif "Raman" in key:
                    matched_label = "B.V. Raman"
                elif "Yukteswar" in key:
                    matched_label = "Sri Yukteswar"
                else:
                    matched_label = "Lahiri"
                break

        if matched_mode is not None:
            # Save + restore previous global mode to avoid polluting parallel calculations
            prev_mode = swe.get_ayanamsa_ut(jd)  # just read before changing
            try:
                swe.set_sid_mode(matched_mode)
                ayan_deg = swe.get_ayanamsa_ut(jd)
            except Exception:
                ayan_deg = prev_mode
            return ayan_deg, f"{matched_label} {format_dms(ayan_deg)}"'''

if old_block in content:
    content = content.replace(old_block, new_block)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('kp_engine.py patched: global swe.set_sid_mode calls consolidated and isolated.')
else:
    print('Block not found. Checking partial match...')
    if 'swe.set_sid_mode(swe.SIDM_LAHIRI)' in content:
        print('Found SIDM_LAHIRI call')
    if 'swe.set_sid_mode(swe.SIDM_RAMAN)' in content:
        print('Found SIDM_RAMAN call')
