#!/bin/bash
#       $Id$
# Usage: m2s.bash pixel_size_in_meters llpfile
#
# Convert pixel dimension in meters to dx/dy in arc seconds at mean latitude
pix=$1 # Input pixel dimension in meters
llp=$2 # lon lat phase binary float file
# 1. Get w e s n in array
range=($(gmt gmtinfo $2 -bi3f -C))
# 2. Get mean latitude
mlat=$(gmt math -Q ${range[3]} ${range[4]} ADD 2 DIV =)
# 3. Get nearest integer 1/2 arc second for latitude (at least 1")
dy=$(gmt math -Q $pix 111195.079734 DIV 3600 MUL 2 MUL RINT 1 MAX 2 DIV =)
# 4. Get nearest integer 1/2 arc second for longitude at mean latitude (at least 1")
dx=$(gmt math -Q $pix 111195.079734 DIV $mlat COSD DIV 3600 MUL 2 MUL RINT 1 MAX 2 DIV =)
# Report two -Idx/dy settings: first for actual grid and 2nd for 10 times larger intervals
inc1="${dx}s/${dy}s"
dx=$(gmt math -Q $dx 10 MUL =)
dy=$(gmt math -Q $dy 10 MUL =)
inc2="${dx}s/${dy}s"
echo $inc1 $inc2
