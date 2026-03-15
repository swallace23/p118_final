# Project Overview
testing different diffusion solvers for the gemini3d ionospheric mhd model. general setup is to oscillate neutral temperature in the center of a low resolution grid to try to generate pressure waves, and see if we can resolve them at low frequencies. Doing it in 2D because discovery broke the day this project was due so I needed fast runs, but also results in 2D are good for this kind of project.

# Repo Organization
simulation setup and data in data/
solver changes in gemini3d/. It's a local build of the gemini model - I didn't want to fork it for a school project, so if this ends up going somewhere I'll fork it into this repo.
plot is a local copy of the plot utilities from pygemini, might modify some of them for visualizing stuff but currently just using my own grids.

grids and setups are generated with matgemini. neutral data generation is in data/inits and that's turned into h5 files by mat\_gemini-scripts/magic/makedneuframes2DcartAxi\_h5.m
