#!/bin/bash
#
alias rm='rm -f'
#
if [ $# -lt 1 ]; then
  echo ""
  echo "Usage: geocode.bash correlation_threshold"
  echo ""
  echo " phase is masked when correlation is less than correlation_threshold"
  echo ""
  echo "Example: geocode.bash .12"
  echo ""
  exit 1
fi
#
if [ -f ~/.quiet ]; then
  V=""
else
  V="-V"
fi

#   first mask the phase and phase gradient using the correlation
#
gmt grdmath corr.grd $1 GE 0 NAN mask.grd MUL = mask2.grd $V
gmt grdmath phase.grd mask2.grd MUL = phase_mask.grd
if [ -e xphase.grd ]; then
  gmt grdmath xphase.grd mask2.grd MUL = xphase_mask.grd
  gmt grdmath yphase.grd mask2.grd MUL = yphase_mask.grd
fi
if [ -e unwrap.grd ]; then
  gmt grdsample mask2.grd $(gmt grdinfo unwrap.grd -I-) $(gmt grdinfo unwrap.grd -I) -Gmask3.grd
  gmt grdmath unwrap.grd mask3.grd MUL = unwrap_mask.grd
fi
if [ -e phasefilt.grd ]; then
  gmt grdmath phasefilt.grd mask2.grd MUL = phasefilt_mask.grd
fi
#
#   look at the masked phase
#
gmt grdimage phase_mask.grd -JX6.5i -Cphase.cpt -Bxaf+lRange -Byaf+lAzimuth -BWSen -X1.3i -Y3i -P -K >phase_mask.ps
gmt psscale -Rphase_mask.grd -J -DJTC+w5i/0.2i+h -Cphase.cpt -Bxa1.57+l"Phase" -By+lrad -O >>phase_mask.ps
gmt psconvert -Tf -P -A -Z phase_mask.ps
echo "Masked phase map: phase_mask.pdf"
if [ -e xphase_mask.grd ]; then
  gmt makecpt -Cgray -T-.3/.3/.1 -N -Z >xphase.cpt
  gmt grdimage xphase_mask.grd -JX8i -Cxphase.cpt -X.2i -Y.5i -P -K >xphase_mask.ps
  gmt psscale -Rxphase_mask.grd -J -DJTC+w5i/0.2i+h -Cxphase.cpt -Bxa0.1+l"Phase" -By+lrad -O >>xphase_mask.ps
  gmt psconvert -Tf -P -A -Z xphase_mask.ps
  echo "Masked x phase map: xphase_mask.pdf"
  gmt makecpt -Cgray -T-.6/.6/.1 -N -Z >yphase.cpt
  gmt grdimage yphase_mask.grd -JX8i -Cyphase.cpt -X.2i -Y.5i -P -K >yphase_mask.ps
  gmt psscale -Ryphase_mask.grd -J -DJTC+w5i/0.2i+h -Cyphase.cpt -Bxa0.1+l"Phase" -By+lrad -O >>yphase_mask.ps
  gmt psconvert -Tf -P -A -Z yphase_mask.ps
  echo "Masked y phase map: yphase_mask.pdf"
fi
if [ -e unwrap_mask.grd ]; then
  gmt grdimage unwrap_mask.grd -JX6.5i -Bxaf+lRange -Byaf+lAzimuth -BWSen -Cunwrap.cpt -X1.3i -Y3i -P -K >unwrap_mask.ps
  gmt psscale -Runwrap_mask.grd -J -DJTC+w5i/0.2i+h+e -Cunwrap.cpt -Bxaf+l"Unwrapped phase" -By+lrad -O >>unwrap_mask.ps
  gmt psconvert -Tf -P -A -Z unwrap_mask.ps
  echo "Unwrapped masked phase map: unwrap_mask.pdf"
fi
if [ -e phasefilt_mask.grd ]; then
  gmt grdimage phasefilt_mask.grd -JX6.5i -Bxaf+lRange -Byaf+lAzimuth -BWSen -Cphase.cpt -X1.3i -Y3i -P -K >phasefilt_mask.ps
  gmt psscale -Rphasefilt_mask.grd -J -DJTC+w5i/0.2i+h -Cphase.cpt -Bxa1.57+l"Phase" -By+lrad -O >>phasefilt_mask.ps
  gmt psconvert -Tf -P -A -Z phasefilt_mask.ps
  echo "Filtered masked phase map: phasefilt_mask.pdf"
fi
# line-of-sight displacement
if [ -e unwrap_mask.grd ]; then
  wavel=$(grep wavelength *.PRM | awk '{print($3)}' | head -1)
  gmt grdmath unwrap_mask.grd $wavel MUL -79.58 MUL = los.grd
  gmt grdgradient los.grd -Nt.9 -A0. -Glos_grad.grd
  tmp=$(gmt grdinfo -C -L2 los.grd)
  limitU=$(echo $tmp | awk '{printf("%5.1f", $12+$13*2)}')
  limitL=$(echo $tmp | awk '{printf("%5.1f", $12-$13*2)}')
  gmt makecpt -Cpolar -Z -T"$limitL"/"$limitU"/1 -D >los.cpt
  gmt grdimage los.grd -Ilos_grad.grd -Clos.cpt -Bxaf+lRange -Byaf+lAzimuth -BWSen -JX6.5i -X1.3i -Y3i -P -K >los.ps
  gmt psscale -Rlos.grd -J -DJTC+w5i/0.2i+h+e -Clos.cpt -Bxaf+l"LOS displacement [range decrease @~\256@~]" -By+lmm -O >>los.ps
  gmt psconvert -Tf -P -A -Z los.ps
  echo "Line-of-sight map: los.pdf"
fi

#
#  now reproject the phase to lon/lat space
#
echo "geocode.bash"
echo "project correlation, phase, unwrapped and amplitude back to lon lat coordinates"
maker=$0:t
today=$(date)
remarked=$(echo by $USER on $today with $maker)
echo remarked is $remarked

proj_ra2ll.bash trans.dat corr.grd corr_ll.grd
gmt grdedit -D//"dimensionless"/1///"$PWD:t geocoded correlation"/"$remarked" corr_ll.grd
#proj_ra2ll.bash trans.dat phase.grd       phase_ll.grd          ; gmt grdedit -D//"radians"/1///"$PWD:t wrapped phase"/"$remarked"                   phase_ll.grd
proj_ra2ll.bash trans.dat phasefilt.grd phasefilt_ll.grd
gmt grdedit -D//"radians"/1///"$PWD:t wrapped phase after filtering"/"$remarked" phasefilt_ll.grd
proj_ra2ll.bash trans.dat phase_mask.grd phase_mask_ll.grd
gmt grdedit -D//"radians"/1///"$PWD:t wrapped phase after masking"/"$remarked" phase_mask_ll.grd
proj_ra2ll.bash trans.dat display_amp.grd display_amp_ll.grd
gmt grdedit -D//"dimensionless"/1///"PWD:t amplitude"/"$remarked" display_amp_ll.grd
if [ -e xphase_mask.grd ]; then
  proj_ra2ll.bash trans.dat xphase_mask.grd xphase_mask_ll.grd
  gmt grdedit -D//"radians"/1///"$PWD:t xphase"/"$remarked" xphase_mask_ll.grd
  proj_ra2ll.bash trans.dat yphase_mask.grd yphase_mask_ll.grd
  gmt grdedit -D//"radians"/1///"$PWD:t yphase"/"$remarked" yphase_mask_ll.grd
fi
if [ -e unwrap_mask.grd ]; then
  proj_ra2ll.bash trans.dat unwrap_mask.grd unwrap_mask_ll.grd
  gmt grdedit -D//"radians"/1///"PWD:t unwrapped, masked phase"/"$remarked" unwrap_mask_ll.grd
fi
if [ -e unwrap.grd ]; then
  proj_ra2ll.bash trans.dat unwrap.grd unwrap_ll.grd
  gmt grdedit -D//"radians"/1///"PWD:t unwrapped phase"/"$remarked" unwrap_ll.grd
fi
if [ -e phasefilt_mask.grd ]; then
  proj_ra2ll.bash trans.dat phasefilt_mask.grd phasefilt_mask_ll.grd
  gmt grdedit -D//"phase in radians"/1///"PWD:t wrapped phase masked filtered"/"$remarked" phasefilt_mask_ll.grd
fi
#
#   now image for google earth
#
echo "geocode.bash"
echo "make the KML files for Google Earth"
grd2kml.bash display_amp_ll display_amp.cpt
grd2kml.bash corr_ll corr.cpt
grd2kml.bash phase_mask_ll phase.cpt
grd2kml.bash phasefilt_mask_ll phase.cpt
if [ -e xphase_mask_ll.grd ]; then
  grd2kml.bash xphase_mask_ll xphase.cpt
  grd2kml.bash yphase_mask_ll yphase.cpt
fi
if [ -e unwrap_mask_ll.grd ]; then
  grd2kml.bash unwrap_mask_ll unwrap.cpt
fi
if [ -e phasefilt_mask_ll.grd ]; then
  grd2kml.bash phasefilt_mask_ll phase.cpt
fi
if [ -e unwrap_mask_ll.grd ]; then
  # constant is negative to make LOS = -1 * range change
  # constant is (1000 mm) / (4 * pi)
  gmt grdmath unwrap_mask_ll.grd $wavel MUL -79.58 MUL = los_ll.grd
  gmt grdedit -D//"mm"/1///"$PWD:t LOS displacement"/"equals negative range" los_ll.grd
  grd2kml.bash los_ll los.cpt
fi
