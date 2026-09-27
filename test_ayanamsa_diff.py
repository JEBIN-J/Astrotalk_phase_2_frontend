import sys
sys.path.append('..\Astrotalk_phase_2_backend')
from app.services.vedic_engine import generate_full_kundli
from datetime import datetime

# Test with Lahiri
k1 = generate_full_kundli("Test", "2000-01-01", "12:00:00", "Delhi", 28.6139, 77.2090, 5.5, "LAHIRI")
print("LAHIRI Arudha A1:", k1["arudha_padas"][0]["degree_formatted"])
print("LAHIRI Bhava Lagna:", k1["special_lagnas"][0]["degree_formatted"])

# Test with Raman
k2 = generate_full_kundli("Test", "2000-01-01", "12:00:00", "Delhi", 28.6139, 77.2090, 5.5, "BV_RAMAN")
print("RAMAN Arudha A1:", k2["arudha_padas"][0]["degree_formatted"])
print("RAMAN Bhava Lagna:", k2["special_lagnas"][0]["degree_formatted"])

