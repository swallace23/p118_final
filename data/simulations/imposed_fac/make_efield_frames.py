import numpy as np, h5py, datetime as dt
from pathlib import Path

ymd = (2017,3,2)
UTsec0 = 27000.0
dtE0 = 1.0
tdur = 300.0
outdir = Path("inputs/Efield")

# read driver grid
with h5py.File(outdir/"simgrid.h5","r") as f:
    mlon = f["mlon"][:]   # (llon,)
    mlat = f["mlat"][:]   # (llat,)
LLON, LLAT = len(mlon), len(mlat)
MLON, MLAT = np.meshgrid(mlon, mlat, indexing="ij")  # (llon,llat)

# pattern params
J0 = 2e-6        # A/m^2
T  = 20.0        # s
mlat0 = 67.0
sig_mlat = 0.2
lambda_mlon = (mlon.max()-mlon.min())/2  # example

t = 0.0
while t <= tdur + 1e-9:
    timefac = np.sin(2*np.pi*t/T)
    arc = np.exp(-0.5*((MLAT-mlat0)/sig_mlat)**2)
    wave = np.sin(2*np.pi*(MLON-mlon.min())/lambda_mlon)
    Jpar = J0 * timefac * arc * wave  # (llon,llat)

    fname = outdir / f"{ymd[0]:04d}{ymd[1]:02d}{ymd[2]:02d}_{UTsec0+t:011.6f}.h5"
    with h5py.File(fname,"w") as f:
        f["Exit"] = np.zeros((LLON,LLAT))
        f["Eyit"] = np.zeros((LLON,LLAT))
        f["Vmaxx1it"] = Jpar                  # FAC when flagdirich=0
        f["Vminx1it"] = np.zeros((LLON,LLAT))
        f["Vmaxx2ist"] = np.zeros((LLAT,))
        f["Vminx2ist"] = np.zeros((LLAT,))
        f["Vmaxx3ist"] = np.zeros((LLON,))
        f["Vminx3ist"] = np.zeros((LLON,))
        f["flagdirich"] = np.array([0], dtype=np.int32)
    t += dtE0
