#!/bin/bash
#
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo " "
  echo "Usage: grd2kml.bash grd_file_stem cptfile [-R<west>/<east>/<south>/<north>] "
  echo " "
  echo "Example: grd2kml.bash phase phase.cpt "
  echo " "
  exit 1
fi
#
if [ -f ~/.quiet ]; then
  V=""
  VS=""
else
  V="-V"
  VS="-S -V"
fi

#
DX=$(gmt grdinfo $1.grd -C | cut -f8)
DPI=$(gmt gmtmath -Q $DX INV RINT = )
#echo $DPI
gmt set COLOR_MODEL = hsv
gmt set PS_MEDIA = A2
#
if [ $# -eq 3 ]; then
  gmt grdimage $1.grd -C$2 $3 -Jx1id -P -Y2i -X2i -Q $V >$1.ps
elif [ $# -eq 2 ]; then
  gmt grdimage $1.grd -C$2 -Jx1id -P -Y2i -X2i -Q $V >$1.ps
fi
#
#   now make the kml and png
#
echo "Make $1.kml and $1.png"
gmt psconvert $1.ps -W+k+t"$1" -E$DPI -TG -P $VS -F$1
rm -f $1.ps grad.grd ps2raster* psconvert*
#
