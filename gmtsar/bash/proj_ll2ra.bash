#!/bin/bash
#
alias rm='rm -f'
if [ -f ~/.quiet ]; then
  V=""
else
  V="-V"
fi

#
#
#  project a grd file from lon/lat coordinates into range/azimuth coordinates
#  this version only works with GMT V4.0 and higher
#
#  Input:
#  trans.dat    - file generated by llt_grid2rat  (r a topo lon lat)
#  phase_ll.grd - a GRD file of phase or anything in longitude/latitude coordinates
#
#  Output:
#  phase_ra.grd - a GRD file of phase in radar coordinates
#
# check for number of arguments
#
if [ $# -lt 3 ]; then
  echo " "
  echo "Usage: proj_ll2ra.bash trans.dat phase_ll.grd phase_ra.grd"
  echo " "
  echo "        trans.dat    - file generated by llt_grid2rat  (r a topo lon lat)"
  echo "        phase_ll.grd - a GRD file of phase or anything in lon/lat-coordinates"
  echo "        phase_ra.grd - output a GRD file in radar coordinates"
  echo " "
  exit 1
fi
#
#  extract the phase in the r a positions
#
gmt set FORMAT_GEO_OUT D
gmt grd2xyz $2 -s -bo3f -fg >llp
#
#   make grids of longitude and latitude versus range and azimuth
#
gmt gmtconvert $1 -o3,4,0 -bi5d -bo3f >llr
gmt gmtconvert $1 -o3,4,1 -bi5d -bo3f >lla
#
gmt surface llr $(gmt gmtinfo llp -I0.08333333333 -bi3f) -bi3f -I.00083333333333 -T.50 -Gllr.grd $V
gmt surface lla $(gmt gmtinfo llp -I0.08333333333 -bi3f) -bi3f -I.00083333333333 -T.50 -Glla.grd $V
#
gmt grdtrack llp -nl -Gllr.grd -bi3f -bo4f >llpr
gmt grdtrack llpr -nl -Glla.grd -bi4f -bo5f >llpra
#
# get the range, azimuth, phase columns and grid
#
gmt gmtconvert llpra -bi5f -bo3f -o3,4,2 >rap
#
#
gmt xyz2grd rap $(gmt gmtinfo rap -I32/64 -bi3f) -I32/64 -r -G$3 -bi3f
#
# clean
#
rm ll* rap
