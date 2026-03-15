#!/bin/bash
direc=$1
cd $direc
ffmpeg -framerate 30 -pattern_type glob -i '*.png' -vf "setpts=2*PTS" -c:v mpeg4 -pix_fmt yuv420p -movflags +faststart output.mp4
