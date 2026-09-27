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
    "ayanamsa": "BV_RAMAN"
}
try:
    res = requests.post(url, json=payload)
    print("Status:", res.status_code)
    if res.status_code == 200:
        data = res.json()
        print("A1:", data['arudha_padas'][0])
except Exception as e:
    print("Error:", e)
