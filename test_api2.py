import json
import requests

url = "http://127.0.0.1:5000/api/v1/horoscope/kundli"
payload = {
    "name": "Test",
    "date_of_birth": "1995-08-15",
    "time_of_birth": "06:30",
    "place_of_birth": "New Delhi",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "timezone": 5.5,
    "bhava_system": "Porphyry (Sripathi)"
}

payload['ayanamsa'] = 'LAHIRI'
res_lahiri = requests.post(url, json=payload).json()
cusps_lahiri = res_lahiri['bhava_chalit']['cusps']

payload['ayanamsa'] = 'BV_RAMAN'
res_raman = requests.post(url, json=payload).json()
cusps_raman = res_raman['bhava_chalit']['cusps']

print("Lahiri Cusp 1:", cusps_lahiri[0]['cusp_midpoint_formatted'])
print("Raman Cusp 1:", cusps_raman[0]['cusp_midpoint_formatted'])
if cusps_lahiri[0]['cusp_midpoint_formatted'] == cusps_raman[0]['cusp_midpoint_formatted']:
    print("THEY ARE THE SAME!")
else:
    print("THEY CHANGED.")
