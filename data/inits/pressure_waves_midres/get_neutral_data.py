import numpy as np
from datetime import datetime, timedelta, timezone
from pymsis import msis

# from config.nml [1]
t0 = datetime(2017, 3, 2, tzinfo=timezone.utc) + timedelta(seconds=27000.0)
glat, glon = 67.11, 212.95
alt_km = np.array([300.0])

# solar/geomagnetic indices from activ = f107a,f107,Ap [1]
f107a, f107, ap = 76.5, 79.3, 31.5

out = msis.run(t0, glon, glat, alt_km, f107s=f107, f107as=f107a, aps=ap)
# out contains densities and temperatures; neutral temperature is typically in out["Tn"] or similar
print(out)
