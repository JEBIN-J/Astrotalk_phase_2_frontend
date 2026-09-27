import sys
import json
from app.services.vedic_engine import generate_full_kundli

k_lahiri = generate_full_kundli('Rahul', '1995-08-15', '06:30', 'New Delhi', 28.6139, 77.2090, 5.5, 365.25, 'Porphyry', ayanamsa='LAHIRI')
k_raman = generate_full_kundli('Rahul', '1995-08-15', '06:30', 'New Delhi', 28.6139, 77.2090, 5.5, 365.25, 'Porphyry', ayanamsa='BV_RAMAN')

p1 = [p for p in k_lahiri['divisional_charts']['D-9']['planets'] if p['planet'] == 'Sun'][0]
p2 = [p for p in k_raman['divisional_charts']['D-9']['planets'] if p['planet'] == 'Sun'][0]
print('LAHIRI Navamsha Sun:', p1['sign'], p1['degree_formatted'])
print('RAMAN Navamsha Sun:', p2['sign'], p2['degree_formatted'])

a1 = k_lahiri['arudha_padas'][0]
a2 = k_raman['arudha_padas'][0]
print('LAHIRI Arudha A1:', a1['sign'], a1['degree_formatted'])
print('RAMAN Arudha A1:', a2['sign'], a2['degree_formatted'])

b1 = k_lahiri['special_lagnas'][0]
b2 = k_raman['special_lagnas'][0]
print('LAHIRI Special Lagna BL:', b1['sign'], b1['degree_formatted'])
print('RAMAN Special Lagna BL:', b2['sign'], b2['degree_formatted'])
