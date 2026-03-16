import shutil
from pathlib import Path
import numpy as np
import h5py

icfile = Path("inputs/initial_conditions.h5")
backup = Path("inputs/initial_conditions_backup.h5")
if not backup.exists():
    shutil.copy2(icfile, backup)

A = 200.0   # m/s amplitude
w = 2.0     # width in grid cells

with h5py.File(icfile, "r+") as f:
    vs1 = f["/vs1all"][:]   # shape seen in your outputs: (7, 1, 12, 15)
    print("vs1all shape:", vs1.shape)

    # put bump along the last spatial axis
    nz = vs1.shape[-1]
    z = np.arange(nz, dtype=float)
    z0 = 0.5 * (nz - 1)
    bump = A * np.exp(-((z - z0)**2) / (2*w**2))

    shape = [1] * vs1.ndim
    shape[-1] = nz
    bump = bump.reshape(shape)

    vs1 += bump
    f["/vs1all"][:] = vs1
