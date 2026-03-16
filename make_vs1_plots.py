import argparse
from pathlib import Path

import gemini3d.read
import h5py
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import Normalize


def get_time_string(time):
    return f"{time.hour:02d}{time.minute:02d}{time.second:02d}"


def main():
    parser = argparse.ArgumentParser(
        description="Make GEMINI plots for electron vs1 perturbations and norm diagnostics."
    )
    parser.add_argument(
        "direc",
        help="Simulation directory. Should contain output HDF5 files and inputs/ directory.",
    )
    parser.add_argument("--solver", help="adds solver spec to plot title")
    args = parser.parse_args()

    direc = Path(args.direc).expanduser()
    solver = None
    if args.solver!=None:
        solver = args.solver
    plotdir = direc / "plots"
    plotdir.mkdir(parents=True, exist_ok=True)

    cfg = gemini3d.read.config(direc)

    # Read grid dimensions from simsize.h5
    fname = direc / "inputs" / "simsize.h5"
    with h5py.File(fname, "r") as f:
        l_alt = int(f["lx1"][()])
        l_east = int(f["lx2"][()])
        l_north = int(f["lx3"][()])

    xdist_km = cfg["xdist"] * 1e-3
    alt_min_km = cfg["alt_min"] * 1e-3
    alt_max_km = cfg["alt_max"] * 1e-3

    x_ax = np.linspace(0.0, xdist_km, l_east)
    alt_ax = np.linspace(alt_min_km, alt_max_km, l_alt)
    X, Y = np.meshgrid(x_ax, alt_ax)

    # Skip unreadable / empty frames
    valid_times = []
    dat0 = None
    failed_times = []

    for t in cfg["time"]:
        try:
            dat = gemini3d.read.frame(direc, time=t)
            if dat0 is None:
                dat0 = dat
            valid_times.append(t)
        except Exception:
            failed_times.append(get_time_string(t))
            continue

    if dat0 is None:
        raise RuntimeError("No readable output frames found.")

    times = valid_times

    # 7th species = electrons -> Python index 6
    isp = 6

    # Expected layout from your run: (species, alt, east-west singleton?, horizontal)
    # Use species 6, all altitude, singleton dim index 0, all east-west
    vs1_0 = np.array(dat0["vs1"][isp, :, :, 0], dtype=float)

    if vs1_0.shape != (l_alt, l_east):
        raise ValueError(
            f"Unexpected vs1 slice shape {vs1_0.shape}, expected {(l_alt, l_east)}"
        )

    # Determine fixed symmetric color scale for perturbation plots
    absmax = 0.0
    for t in times:
        try:
            d = gemini3d.read.frame(direc, time=t)
            vs1 = np.array(d["vs1"][isp, :, :, 0], dtype=float)
            dvs1 = vs1 - vs1_0
            this_absmax = np.nanmax(np.abs(dvs1))
            if np.isfinite(this_absmax):
                absmax = max(absmax, this_absmax)
        except Exception:
            continue

    if absmax == 0.0:
        absmax = 1.0

    pert_norm = Normalize(vmin=-absmax, vmax=absmax)

    # Track norms over time
    good_time_strings = []
    linf_vals = []
    l2_vals = []

    # Make per-frame perturbation plots
    for time in times:
        timestr = get_time_string(time)
        print("plotting time:", time)

        try:
            dat = gemini3d.read.frame(direc, time=time)
        except Exception:
            failed_times.append(timestr)
            continue

        vs1 = np.array(dat["vs1"][isp, :, :, 0], dtype=float)
        dvs1 = vs1 - vs1_0

        linf = np.nanmax(np.abs(dvs1))
        l2 = np.sqrt(np.nanmean(dvs1**2))

        good_time_strings.append(timestr)
        linf_vals.append(linf)
        l2_vals.append(l2)

        plt.figure(figsize=(10, 6))
        plt.pcolormesh(
            X,
            Y,
            dvs1,
            cmap="RdBu_r",
            shading="auto",
            norm=pert_norm,
        )
        plt.colorbar(label="electron vs1 - electron vs1(t0) [m/s]")
        plt.xlabel("Horizontal Distance (km)")
        plt.ylabel("Altitude (km)")
        plt.title("Electron Field-Aligned Drift Perturbation")
        plt.savefig(plotdir / f"vs1pert_electrons_{timestr}.png", bbox_inches="tight")
        plt.close()

    # Plot norm diagnostics
    if len(good_time_strings) > 0:
        t_index = np.arange(len(good_time_strings), dtype=int)

        plt.figure(figsize=(10, 6))
        plt.plot(t_index, linf_vals, label=r"$L_\infty$")
        plt.plot(t_index, l2_vals, label=r"$L_2$")
        plt.xticks(t_index, good_time_strings, rotation=45)
        plt.xlabel("Time (HHMMSS)")
        plt.ylabel("Norm of electron vs1 perturbation [m/s]")
        if solver==None:
            plt.title("Electron vs1 Perturbation Norms")
        else:
            plt.title(f"Electron vs1 Perturbation Norms - {solver}")
        plt.legend()
        plt.tight_layout()
        plt.savefig(plotdir / "vs1_electron_norms.png", bbox_inches="tight")
        plt.close()

    if len(failed_times) != 0:
        print("failed time slices:")
        print(failed_times)


if __name__ == "__main__":
    main()
