import swisseph as swe

jd = 2450000.5
swe.set_sid_mode(swe.SIDM_RAMAN)

# tropical
trop_lon = swe.calc_ut(jd, swe.SUN, swe.FLG_SWIEPH)[0][0]
ayanamsa = swe.get_ayanamsa_ut(jd)
manual_sid = (trop_lon - ayanamsa) % 360.0

# native sidereal
native_sid = swe.calc_ut(jd, swe.SUN, swe.FLG_SWIEPH | swe.FLG_SIDEREAL)[0][0]

print('Tropical:', trop_lon)
print('Ayanamsa:', ayanamsa)
print('Manual Sidereal:', manual_sid)
print('Native Sidereal:', native_sid)
print('Difference:', native_sid - manual_sid)
