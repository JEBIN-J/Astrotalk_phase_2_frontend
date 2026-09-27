import sys
import swisseph as swe

jd = swe.julday(1995, 8, 15, 6.5)
swe.set_sid_mode(swe.SIDM_RAMAN)
raman = swe.get_ayanamsa_ut(jd)
swe.set_sid_mode(swe.SIDM_LAHIRI)
lahiri = swe.get_ayanamsa_ut(jd)

print('PySwissEph Raman:', raman)
print('PySwissEph Lahiri:', lahiri)

# Raman manual: (Year - 397) * 50.3333 / 3600
# For 1995.62
manual_raman = (1995.62 - 397) * 50.333333 / 3600.0
print('Manual Raman:', manual_raman)
