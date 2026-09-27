import sys
file_path = r'..\Astrotalk_phase_2_backend\app\api\v1\horoscope.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_call = '''    result = generate_full_kundli(
        data["name"], data["date_of_birth"], data["time_of_birth"],
        data["place_of_birth"], data["latitude"], data["longitude"], data["timezone"]
    )
    resp = {
        "person_name": result["person_name"],
        "ascendant": result["ascendant_lagna"],
        "planets": result["planets"]'''

new_call = '''    result = generate_full_kundli(
        data["name"], data["date_of_birth"], data["time_of_birth"],
        data["place_of_birth"], data["latitude"], data["longitude"], data["timezone"],
        ayanamsa=data["ayanamsa"], custom_ayanamsa=data["custom_ayanamsa"]
    )
    resp = {
        "person_name": result["person_name"],
        "ascendant": result["ascendant_lagna"],
        "planets": result["planets"]'''

if old_call in content:
    content = content.replace(old_call, new_call)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated horoscope.py')
else:
    print('old_call not found in horoscope.py')
