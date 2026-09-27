import swisseph as swe
import datetime
import math

jd_ut = swe.julday(1998, 12, 16, 9.5 - 5.5)
lat, lon = 8.083333333333334, 77.53333333333333

swe.set_sid_mode(swe.SIDM_RAMAN)
aya_raman = swe.get_ayanamsa_ut(jd_ut)
sun_trop = swe.calc_ut(jd_ut, swe.SUN, swe.FLG_SWIEPH)[0][0]
sun_deg = (sun_trop - aya_raman) % 360.0
asc_trop, _ = swe.houses(jd_ut, lat, lon, b'O')
asc_deg = (asc_trop[0] - aya_raman) % 360.0

jd_ut_start = swe.julday(1998, 12, 16, 0.0)
geopos = (lon, lat, 0.0)
flags = swe.CALC_RISE | swe.BIT_NO_REFRACTION | swe.BIT_DISC_CENTER
res_rise = swe.rise_trans(jd_ut_start, swe.SUN, flags, geopos)
sunrise_jd_ut = res_rise[1][0]

time_from_sun = (jd_ut - sunrise_jd_ut) * 24.0
sun_sunrise_tropical = swe.calc_ut(sunrise_jd_ut, swe.SUN, swe.FLG_SWIEPH)[0][0]
sun_sunrise_deg = (sun_sunrise_tropical - aya_raman) % 360.0

hl_deg = (sun_sunrise_deg + (time_from_sun * 30.0)) % 360.0
gl_deg = (sun_sunrise_deg + (time_from_sun * 75.0)) % 360.0
bl_deg = (sun_sunrise_deg + (time_from_sun * 15.0)) % 360.0

print("Time from Sun (hrs):", time_from_sun)
print("Sun Sunrise Deg:", sun_sunrise_deg)
print("Hora Lagna:", hl_deg, "Sign:", int(hl_deg//30)+1)
print("Ghati Lagna:", gl_deg, "Sign:", int(gl_deg//30)+1)
print("Bhava Lagna:", bl_deg, "Sign:", int(bl_deg//30)+1)
