import re

file_path = r'C:\Users\USER\Desktop\FJ Fusion\Astrotalk_phase_2\Astrotalk_phase_2_backend\app\api\v1\horoscope.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_data = '''    diseases_by_zodiac = {
        "ARIES": "Head Injuries, Neuralgia, Cerebral hemorrhage",
        "TAURUS": "Thyroid diseases, Diphtheria, Diseases of Cervical Spine, Irregular Menses, V.D., Piles & Constipation",
        "GEMINI": "Diseases of Lung, Asthma, T.B., Dry Cough, Disease of Pericardium, Affection of Shoulders & Hands",
        "CANCER": "Diseases of Stomach, Indigestion, Gas trouble, Jaundice & Gallstones, Hysteria",
        "LEO": "Angina pectoris, Palpitation, Aneurysm, Giddiness, Anemia, Curved Spine, Regurgitation of Blood, Spinal",
        "VIRGO": "Appendicitis, Peritonitis, Worm infestation, Loose Motions, Cholera, Typhoid",
        "LIBRA": "Diseases of Uterus, Rheumatic pain, Skin diseases, Hernias, Kidney diseases, Appendicitis",
        "SCORPIO": "V.D. Disease of Prostate gland, Ovary & Uterus, Diseases of Urethra, Bladder & Rectum, Renal stones, Irregular",
        "SAGITTARIUS": "Diseases of Hip & Femur, Sciatica, Varicose Veins, Lung Diseases, Fracture of Collar Bones",
        "CAPRICORN": "Diseases of Knee, Skin diseases, Leprosy, Piles, Gout, Neuralgia, Heart Disorders",
        "AQUARIUS": "Varicose veins, Diseases of Ankle, Heart Diseases, Skin diseases, Eye diseases",
        "PISCES": "Diseases of feet & Toes, Diseases of Bowels, Complication due to Drugs, Alcoholism"
    }

    return jsonify({
        "status": "success",
        "data": {
            "rasi_properties": rasi_properties,
            "parts_of_body": parts_of_body,
            "houses_events": houses_events,
            "nakshatra_padas": nakshatra_padas,
            "planet_properties": planet_properties,
            "planet_exalted_debilitated": planet_exalted_debilitated,
            "diseases_by_zodiac": diseases_by_zodiac
        }
    })'''

content = re.sub(r'    diseases_by_zodiac = \[.*?\n    \]\n\n    return jsonify\(\{\s*"status": "success",\s*"data": \{.*?\}\s*\}\)', new_data, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done updating diseases_by_zodiac to dict")
