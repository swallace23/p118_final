import numpy as np
import h5py
import aacgmv2 as aac
import datetime as dt
from pathlib import Path

# --- user choices ---
dtime = dt.datetime(2017, 3, 2)
alt_m = 110          # constant altitude for AACGM conversion (km)
outdir = Path("inputs/Efield")
outdir.mkdir(parents=True, exist_ok=True)

with h5py.File("inputs/simgrid.h5", "r") as f:
    glat = f["glat"][:]   # (lx1,lx2,lx3)
    glon = f["glon"][:]

# top boundary slice (max x1): shape (lx2,lx3)
glat2 = glat[-1, :, :]
glon2 = glon[-1, :, :]

# flatten for aacgmv2 (it requires 1-D arrays)
glat1 = glat2.ravel()
glon1 = glon2.ravel()
alt1 = np.full(glat1.shape, alt_m)

mlat1, mlon1, _ = aac.convert_latlon_arr(glat1, glon1, alt1, dtime, method_code="G2A")

# reshape back to (lx2,lx3)
mlat2 = mlat1.reshape(glat2.shape)
mlon2 = mlon1.reshape(glon2.shape)

# build 1-D driver grid vectors (llat = lx2, llon = lx3)
llat, llon = mlat2.shape[0], mlat2.shape[1]
mlat_vec = np.linspace(np.nanmin(mlat2), np.nanmax(mlat2), llat)
mlon_min = np.nanmin(mlon2)
mlon_max = np.nanmax(mlon2)
mlon_vec = np.linspace(mlon_min, mlon_max, llon) % 360.0  # keep in [0,360)

# write Efield simsize.h5
with h5py.File(outdir / "simsize.h5", "w") as f:
    f.create_dataset("llat", data=np.int32(llat))
    f.create_dataset("llon", data=np.int32(llon))

# write Efield simgrid.h5
with h5py.File(outdir / "simgrid.h5", "w") as f:
    f.create_dataset("mlat", data=mlat_vec.astype(np.float64))
    f.create_dataset("mlon", data=mlon_vec.astype(np.float64))
