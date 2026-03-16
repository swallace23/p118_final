# Project Overview
Experiments in reducing numerical diffusion for the gemini3d ionospheric mhd model. The general setup is to propagate a sharp drift velocity bump on a low resolution grid and analyze numerical results.
Currently the only new solver implemented is the Alexander's SDIRK solver described in his 1977 paper "Diagonally Implicit Runge-Kutta Methods for Stiff ODEs."

# Repo Organization
Simulation setup and data in data/
Solver changes in gemini3d/. You can choose the new SDIRK diffusion solver by setting diffsolvetype = 3 in config.nml.

Grids and setups are generated with matgemini. Input data generation is in data/inits and that's turned into h5 files by mat\_gemini-scripts/magic/makedneuframes2DcartAxi\_h5.m
