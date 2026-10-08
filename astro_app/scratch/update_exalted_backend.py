import re
import os

file_path = r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\api\v1\horoscope.py'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_data = '''    planet_exalted_debilitated = [
        {"planet": "Sun", "exalted": "10 Degrees Aries", "debilitated": "10 Degrees Libra"},
        {"planet": "Moon", "exalted": "03 Degrees Taurus", "debilitated": "03 Degrees Scorpio"},
        {"planet": "Mars", "exalted": "28 Degrees Capricorn", "debilitated": "28 Degrees Cancer"},
        {"planet": "Mercury", "exalted": "15 Degrees Virgo", "debilitated": "15 Degrees Pisces"},
        {"planet": "Jupiter", "exalted": "05 Degrees Cancer", "debilitated": "05 Degrees Capricorn"},
        {"planet": "Venus", "exalted": "27 Degrees Pisces", "debilitated": "27 Degrees Virgo"},
        {"planet": "Saturn", "exalted": "20 Degrees Libra", "debilitated": "20 Degrees Aries"},
        {"planet": "Rahu", "exalted": "20 Degrees Taurus", "debilitated": "20 Degrees Scorpio"},
        {"planet": "Ketu", "exalted": "20 Degrees Scorpio", "debilitated": "20 Degrees Taurus"}
    ]

    return jsonify({
        "status": "success",
        "data": {
            "rasi_properties": rasi_properties,
            "parts_of_body": parts_of_body,
            "houses_events": houses_events,
            "nakshatra_padas": nakshatra_padas,
            "planet_properties": planet_properties,
            "planet_exalted_debilitated": planet_exalted_debilitated
        }
    })'''

# Since we know `get_cue_cards` is the very last function, we can just replace the last return jsonify
import re
content = re.sub(r'return jsonify\(\{\s*"status": "success",\s*"data": \{.*?\}\s*\}\)', new_data, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done updating horoscope.py")
