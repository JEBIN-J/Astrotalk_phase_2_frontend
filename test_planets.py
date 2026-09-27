import swisseph as swe
import datetime
import math

def calculate_julian_day(year, month, day, hour_utc):
    return swe.julday(year, month, day, hour_utc)

jd_utc = calculate_julian_day(1998, 12, 16, 9.5 - 5.5)

swe.set_sid_mode(swe.SIDM_LAHIRI)
aya_lahiri = swe.get_ayanamsa_ut(jd_utc)
sun_trop = swe.calc_ut(jd_utc, swe.SUN, swe.FLG_SWIEPH)[0][0]
sun_lahiri = (sun_trop - aya_lahiri) % 360.0

swe.set_sid_mode(swe.SIDM_RAMAN)
aya_raman = swe.get_ayanamsa_ut(jd_utc)
sun_raman = (sun_trop - aya_raman) % 360.0

print(f"Sun Trop: {sun_trop}")
print(f"Sun Lahiri: {sun_lahiri} -> Sign {int(sun_lahiri//30)+1}, Deg {sun_lahiri%30}")
print(f"Sun Raman: {sun_raman} -> Sign {int(sun_raman//30)+1}, Deg {sun_raman%30}")
