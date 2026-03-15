import gemini3d.read    
import numpy as np
from pathlib import Path
import h5py
import matplotlib.pyplot as plt

def get_time_string(time):
    hour_str = str(time.hour)
    if len(hour_str) == 1:
        hour_str = "0"+hour_str
    minute_str = str(time.minute)
    if len(minute_str) == 1:
        minute_str = "0"+minute_str
    second_str = str(time.second)
    if len(second_str) == 1:
        second_str = "0"+second_str
    return hour_str+minute_str+second_str
direc="~/Documents/p118_final/data/simulations/pressure_waves_lowres"
cfg = gemini3d.read.config(direc)
dat = gemini3d.read.frame(direc,time=cfg["time"][-1])

#read grid dimensions
fname = Path(direc+"/inputs/simsize.h5").expanduser()
with h5py.File(fname,"r") as f:
    l_alt = f["lx1"][()]
    l_east = f["lx2"][()]
    l_north = f["lx3"][()]


# assuming 2d for now
# if l_north == 1:
#     twod = True
# else:
#     twod = False

# print(cfg["xdist"],cfg["alt_min"],cfg["alt_max"],cfg["glat"],cfg["glon"])
xdist_km = cfg["xdist"]*1e-3
alt_min_km = cfg["alt_min"]*1e-3
alt_max_km = cfg["alt_max"]*1e-3
x_ax = np.linspace(0,xdist_km,l_east)
alt_ax = np.linspace(alt_min_km,alt_max_km,l_alt)

times = cfg["time"]
for time in times:
    timestr = get_time_string(time)
    print("plotting time:",time)
    dat = gemini3d.read.frame(direc,time=time)
    ne = np.array(dat["ne"][:,:,0])
    X,Y = np.meshgrid(x_ax,alt_ax)
    plt.figure(figsize=(10,6))
    plt.pcolormesh(X,Y,ne,cmap="viridis",shading="auto")
    plt.colorbar(label="Electron Density (m^-3)")
    plt.xlabel("Horizontal Distance (km)")
    plt.ylabel("Altitude (km)")
    plt.title("Electron Density ]Profile")
    plt.savefig(f"plots/ne_{timestr}.png")
    plt.close()