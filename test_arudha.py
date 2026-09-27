def dms(deg):
    d = int(deg)
    m = int((deg - d) * 60)
    s = int(((deg - d) * 60 - m) * 60)
    return f"{d:02d}:{m:02d}:{s:02d}"

def rasi_deg(deg):
    return deg % 30

def to_deg(sign_idx, deg_in_sign):
    return (sign_idx - 1) * 30 + deg_in_sign

# Given data roughly from image
asc = to_deg(10, 12.616) # Capricorn
saturn = to_deg(1, 4.6) # Aries
venus = to_deg(9, 10.6) # Sagittarius
mercury = to_deg(8, 9.5) # Scorpio
moon = to_deg(7, 7.0) # Libra
sun = to_deg(8, 29.5) # Scorpio
mars = to_deg(6, 16.8) # Virgo
jupiter = to_deg(11, 27.3) # Aquarius

print("AL (A1) House=Cap(10), Lord=Saturn(1)")
h_deg = asc
l_deg = saturn
# Distance in degrees
dist = l_deg - h_deg
if dist < 0: dist += 360
arudha = (l_deg + dist) % 360
print(f"Classical distance in deg: {arudha} -> {arudha/30 + 1}, {dms(rasi_deg(arudha))}")

# Distance in signs
h_s = 10
l_s = 1
dist_s = (l_s - h_s) % 12
arudha_s = ((l_s - 1 + dist_s) % 12) + 1
# Exceptions
dist_from_h = (arudha_s - h_s) % 12
if dist_from_h == 0: arudha_s = ((arudha_s - 1 + 9) % 12) + 1
elif dist_from_h == 6: arudha_s = ((arudha_s - 1 + 3) % 12) + 1
print(f"Exception rule sign: {arudha_s}")

