#!/bin/bash
#       $Id$
# Matt WEI Feb 1 2010
# modified by Xiaopeng Feb 9 2010
# modified by E. Fielding, DST, XT to add TSX data Jan 10 2014
#=======================================================================
#  script to make topography for interferograms
#  The USGS elevations are height above WGS84 so this is OK.
#
alias rm='rm -f'
#
if [ $# -ne 3 ] && [ $# -ne 2 ]; then
  echo " "
  echo "Usage: dem2topo_ra.bash master.PRM dem.grd [xmin/xmax/ymin/ymax]"
  echo " "
  echo "        Note: Works for TSX,ALOS,ERS,ENVISAT"
  echo " "
  exit 1
fi
#
# local variables
#
scale=-JX7i
if [ -f ~/.quiet ]; then
  V=""
else
  V="-V"
fi
#
# tension
#
tension=0.1

#
#========================Mosaic topo data===============================

#-----------------------------------------------------------------------
#
#------------------------Get bounds in radar coordinates----------------
XMAX=$(grep num_rng_bins $1 | awk '{print $3}')
yvalid=$(grep num_valid_az $1 | awk '{print $3}')
num_patch=$(grep num_patches $1 | awk '{print $3}')
YMAX=$(echo "$yvalid $num_patch" | awk '{print $1*$2}')
SC=$(grep SC_identity $1 | awk '{print $3}')
PRF=$(grep PRF *.PRM | awk 'NR == 1 {printf("%d", $3)}')
if [ $# -eq 3 ]; then
  region=$3
else
  region=0/$XMAX/0/$YMAX
fi
#
# look for range sampling rate
#
rng_samp_rate=$(grep rng_samp_rate $1 | awk 'NR == 1 {printf("%d", $3)}')
#
# the range spacing of simulation in units of image range pixel size
#
if [ $rng_samp_rate -gt 0 ] && [ $rng_samp_rate -lt 25000000 ]; then
  rng=1
elif [ $rng_samp_rate -gt 25000000 ] && [ $rng_samp_rate -lt 72000000 ] || [ $SC == 7 ]; then
  rng=2
elif ($rng_samp_rate -gt 72000000); then
  rng=4
else
  echo "range sampling rate out of bounds"
  exit 0
fi
echo " range decimation is: " $rng
#
if [ $SC -eq 10 ]; then
  gmt grd2xyz --FORMAT_FLOAT_OUT=%lf $2 -s | SAT_llt2rat $1 1 -bod >trans.dat
else
  gmt grd2xyz --FORMAT_FLOAT_OUT=%lf $2 -s | SAT_llt2rat $1 0 -bod >trans.dat
fi
#
# use an azimuth spacing of 2 for low PRF data such as S1 TOPS
#
if [ $PRF -lt 1000 ]; then
  gmt gmtconvert trans.dat -o0,1,2 -bi5d -bo3d | gmt blockmedian -R$region -I$rng/2 -bi3d -bo3d -r $V >temp.rat
  gmt surface temp.rat -R$region -I$rng/2 -bi3d -T$tension -N1000 -Gpixel.grd -r -Q >&tmp
  RR=$(grep Hint tmp | head -1 | awk '{for(i=1;i<=NF;i++) print $i}' | grep /)
  if [ "x$RR" == "x" ]; then
    gmt surface temp.rat -R$region -I$rng/2 -bi3d -T$tension -N1000 -Gpixel.grd -r $V
  else
    gmt surface temp.rat $RR -I$rng/2 -bi3d -T$tension -N1000 -Gpixel.grd -r $V
    gmt grdcut pixel.grd -R$region -Gtmp.grd
    mv tmp.grd pixel.grd
  fi
else
  gmt gmtconvert trans.dat -o0,1,2 -bi5d -bo3d | gmt blockmedian -R$region -I$rng/4 -bi3d -bo3d -r $V >temp.rat
  gmt surface temp.rat -R$region -I$rng/4 -bi3d -T$tension -N1000 -Gpixel.grd -r -Q >&tmp
  RR=$(grep Hint tmp | head -1 | awk '{for(i=1;i<=NF;i++) print $i}' | grep /)
  if [ "x$RR" == "x" ]; then
    gmt surface temp.rat -R$region -I$rng/4 -bi3d -T$tension -N1000 -Gpixel.grd -r $V
  else
    gmt surface temp.rat $RR -I$rng/4 -bi3d -T$tension -N1000 -Gpixel.grd -r $V
    gmt grdcut pixel.grd -R$region -Gtmp.grd
    mv tmp.grd pixel.grd
  fi
fi
#
# flip top to bottom for both ascending and descending passes
#
gmt grdmath pixel.grd FLIPUD = topo_ra.grd

if [ $# -eq 3 ]; then
  x0=echo $region | awk -F'/' '{print $1}'
  y0=echo $region | awk -F'/' '{print $3}'
  x1=echo $region | awk -F'/' '{printf("%d",$1 - '$x0')}'
  y1=echo $region | awk -F'/' '{printf("%d",$3 - '$y0')}'
  gmt grdedit topo_ra.grd -R0/$x1/0/$y1
fi

#
# plotting
#
gmt grd2cpt topo_ra.grd -Cgray $V -Z >topo_ra.cpt
gmt grdimage topo_ra.grd $scale -P -Ctopo_ra.cpt -Bxaf+lRange -Byaf+lAzimuth -BWSen $V -K >topo_ra.ps
gmt psscale -Rtopo_ra.grd -J -DJTC+w5i/0.2i+h -Ctopo_ra.cpt -Bxaf -By+lm -O >>topo_ra.ps
gmt psconvert -Tf -P -A -Z topo_ra.ps
echo "Topo range/azimuth map: topo_ra.pdf"
#
#  clean up
#
rm pixel.grd temp.rat dem.xyz tmp
rm topo_ra.cpt
