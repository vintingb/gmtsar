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
#  project a grd file from range/azimuth coordinates into lon/lat coordinates
#  this version only works with GMT V4.0 and higher
#
#  Input:
#  trans.dat    - file generated by llt_grid2rat  (r a topo lon lat)
#  phase_ra.grd - a GRD file of phase or anything
#
#  Output:
#  phase_ll.grd - a GRD file of phase in longitude/latitude coordinates
#
# check for number of arguments
#
if [ $# -lt 3 ]; then
    echo " "
    echo "Usage: proj_ra2ll.bash trans.dat phase.grd phase_ll.grd"
    echo "        trans.dat    - file generated by llt_grid2rat  (r a topo lon lat)"
    echo "        phase_ra.grd - a GRD file of phase or anything"
    echo "        phase_ll.grd - output file in lon/lat-coordinates"
    echo " "
    exit 1
fi
echo "proj_ra2ll.bash"
#
#  extract the phase in the r a positions
#
gmt grd2xyz $2 -s -bo3f >rap
#
#   make grids of longitude and latitude versus range and azimuth unless they already exist
#
if [ ! -f raln.grd ] || [ ! -f ralt.grd ]; then
    region=$(gmt gmtinfo rap -I16/32 -bi3f)
    gmt surface $1 -i0,1,3 -bi5d $region -I16/32 -T.50 -Graln.grd $V
    gmt surface $1 -i0,1,4 -bi5d $region -I16/32 -T.50 -Gralt.grd $V
fi
#
#  add lon and lat columns and then just keep lon, lat, phase
#
gmt grdtrack rap -nl -bi3f -bo5f -Graln.grd -Gralt.grd | gmt gmtconvert -bi5f -bo3f -o3,4,2 >llp
#
# set the output grid spaccing to be 1/4 the filter wavelength

filt=$(ls gauss_*)
if [ $filt != "" ]; then
    pix_m=$(ls gauss_* | awk -F_ '{print $2/4}') # Use 1/4 the filter width
    echo "Sampling in geocoordinates with $pix_m meter pixels ..."
else
    pix_m=60
    echo "Sampling in geocoordinates with deault ($pix_m meter) pixel size ..."
fi

incs=$(m2s.bash $pix_m llp) # Get fine and crude grid interval for lookup grids
#
R=$(gmt gmtinfo llp -I"$incs"[2] -bi3f)
gmt blockmedian llp $R -bi3f -bo3f -I"$incs"[1] -r -V >llpb
gmt xyz2grd llpb $R -I"$incs"[1] -r -fg -G"$3" -bi3f
#
# clean
#
rm rap* llp llpb raln ralt
