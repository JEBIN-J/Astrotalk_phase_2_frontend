import swisseph as swe

jd_utc = swe.julday(1998, 12, 16, 9.5 - 5.5)
lat, lon = 8.08, 77.53

swe.set_sid_mode(swe.SIDM_LAHIRI)
aya_lahiri = swe.get_ayanamsa_ut(jd_utc)
cusps_lahiri, _ = swe.houses(jd_utc, lat, lon, b'O')
c1_lahiri = (cusps_lahiri[0] - aya_lahiri) % 360.0

swe.set_sid_mode(swe.SIDM_RAMAN)
aya_raman = swe.get_ayanamsa_ut(jd_utc)
cusps_raman, _ = swe.houses(jd_utc, lat, lon, b'O')
c1_raman = (cusps_raman[0] - aya_raman) % 360.0

print(f"Cusp 1 Lahiri: {c1_lahiri}")
print(f"Cusp 1 Raman: {c1_raman}")
