import sys
file_path = r'..\Astrotalk_phase_2_backend\app\services\vedic_engine.py'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_block = '''    def get_upagraha_fraction(planet_idx, is_end=True):
        part_idx = (planet_idx - start_lord) % 7
        return (part_idx + 1) / 8.0 if is_end else part_idx / 8.0

    # Planet indices: Sun=0, Mars=2, Merc=3, Jup=4, Sat=6
    frac_kaala = get_upagraha_fraction(0, False)
    frac_mrityu = get_upagraha_fraction(2, False)
    frac_ardha = get_upagraha_fraction(3, False)
    frac_yama = get_upagraha_fraction(4, False)
    frac_mandi = get_upagraha_fraction(6, False)
    frac_gulika = get_upagraha_fraction(6, True)'''

new_block = '''    def get_upagraha_fraction(planet_idx, position="start"):
        part_idx = (planet_idx - start_lord) % 7
        if position == "end":
            return (part_idx + 1) / 8.0
        elif position == "mid":
            return (part_idx + 0.5) / 8.0
        else:
            return part_idx / 8.0

    # Planet indices: Sun=0, Mars=2, Merc=3, Jup=4, Sat=6
    frac_kaala = get_upagraha_fraction(0, "start")
    frac_mrityu = get_upagraha_fraction(2, "start")
    frac_ardha = get_upagraha_fraction(3, "start")
    frac_yama = get_upagraha_fraction(4, "start")
    frac_mandi = get_upagraha_fraction(6, "mid")
    frac_gulika = get_upagraha_fraction(6, "start")'''

if old_block in content:
    content = content.replace(old_block, new_block)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated upagraha calculation.')
else:
    print('old_block not found.')
