file_path = r'..\Astrotalk_phase_2_backend\app\services\vedic_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix generate_full_kundli signature to preserve ayanamsa key
old_sig = '''def generate_full_kundli(
    name: str,
    dob_str: str,
    tob_str: str,
    pob_str: str,
    latitude: float = 28.6139,
    longitude: float = 77.2090,
    timezone: float = 5.5,
    days_in_year: float = 365.256364,
    bhava_system: str = "Porphyry (Sripathi)",
    ayanamsa: str = "LAHIRI",
    custom_ayanamsa: float = None
)'''
new_sig = '''def generate_full_kundli(
    name: str,
    dob_str: str,
    tob_str: str,
    pob_str: str,
    latitude: float = 28.6139,
    longitude: float = 77.2090,
    timezone: float = 5.5,
    days_in_year: float = 365.256364,
    bhava_system: str = "Porphyry (Sripathi)",
    ayanamsa: str = "LAHIRI",
    custom_ayanamsa: float = None
)'''
# Both are the same, just need to find the line that calculates ayanamsa decimal

# Fix: save the ayanamsa key before overwriting it
old_resolve = '''    jd = calculate_julian_day(dob.year, dob.month, dob.day, hour_utc)
    ayanamsa = calculate_lahiri_ayanamsa(jd, ayanamsa, custom_ayanamsa)'''
new_resolve = '''    jd = calculate_julian_day(dob.year, dob.month, dob.day, hour_utc)
    ayanamsa_key = ayanamsa  # Preserve string key before converting to decimal
    ayanamsa = calculate_lahiri_ayanamsa(jd, ayanamsa, custom_ayanamsa)'''
content = content.replace(old_resolve, new_resolve)

# Human-readable ayanamsa name map
old_meta = '''    accuracy_metadata = {
        "swisseph_used": SWISSEPH_AVAILABLE,
        "engine": "Swiss Ephemeris (pyswisseph)" if SWISSEPH_AVAILABLE else "Keplerian Approximation",
        "ayanamsa_system": "Lahiri (Chitra Paksha)",'''
new_meta = '''    AYANAMSA_DISPLAY_NAMES = {
        "LAHIRI": "Lahiri (Chitrapaksha)",
        "BV_RAMAN": "B.V. Raman",
        "KP_OLD": "Krishnamurti (KP Old)",
        "SRI_YUKTESWAR": "Sri Yukteswar",
        "DE_LUCE": "De Luce",
        "USHA_SHASHI": "Usha-Shashi (Revati)",
        "DJWHAL_KHOOL": "Djwhal Khool",
        "JN_BHASIN": "J.N. Bhasin",
        "FAGAN_BRADLEY": "Fagan-Bradley",
        "TROPICAL": "Tropical (Sayana)",
        "CUSTOM": "Custom",
        "KP_NEW": "Krishnamurti (KP New)",
        "KP_STRAIGHT_LINE": "KP Straight Line",
        "KHULLAR": "Khullar",
        "CHANDRA_HARI": "Chandra Hari",
    }
    ayanamsa_display = AYANAMSA_DISPLAY_NAMES.get(ayanamsa_key, ayanamsa_key)

    accuracy_metadata = {
        "swisseph_used": SWISSEPH_AVAILABLE,
        "engine": "Swiss Ephemeris (pyswisseph)" if SWISSEPH_AVAILABLE else "Keplerian Approximation",
        "ayanamsa_system": ayanamsa_display,'''
content = content.replace(old_meta, new_meta)

# Fix hardcoded "Lahiri" in ayanamsa_value return key
old_val = '        "ayanamsa_value": f"Lahiri {degree_to_sign_and_dms(ayanamsa)[2]}",'
new_val = '        "ayanamsa_value": f"{ayanamsa_display} {degree_to_sign_and_dms(ayanamsa)[2]}",'
content = content.replace(old_val, new_val)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated generate_full_kundli ayanamsa label fixes.')
