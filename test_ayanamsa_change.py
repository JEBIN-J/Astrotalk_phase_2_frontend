import sys
sys.path.append('..\Astrotalk_phase_2_backend')
from app.services.vedic_engine import generate_full_kundli
import json

k_lahiri = generate_full_kundli("Rahul", "1995-08-15", "06:30", "New Delhi", 28.6139, 77.2090, 5.5, "LAHIRI", 0)
k_raman = generate_full_kundli("Rahul", "1995-08-15", "06:30", "New Delhi", 28.6139, 77.2090, 5.5, "BV_RAMAN", 0)

print("LAHIRI Navamsha (D-9) Sun:", [p for p in k_lahiri['divisional_charts']['D-9']['planets'] if p['planet'] == 'Sun'][0])
print("RAMAN Navamsha (D-9) Sun:", [p for p in k_raman['divisional_charts']['D-9']['planets'] if p['planet'] == 'Sun'][0])

print("LAHIRI Arudha A1:", k_lahiri['arudha_padas'][0])
print("RAMAN Arudha A1:", k_raman['arudha_padas'][0])

print("LAHIRI Special Lagna BL:", k_lahiri['special_lagnas'][0])
print("RAMAN Special Lagna BL:", k_raman['special_lagnas'][0])
