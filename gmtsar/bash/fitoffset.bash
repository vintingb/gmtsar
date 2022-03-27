#!/bin/bash
#
#
#  compute 2-6 alignment parameters from xcorr.dat
#
alias rm='rm -f'
#
# check for number of arguments
#
if [ $# == 0 ]; then
	echo "  "
	echo "Usage: fitoffset.bash npar_rng npar_azi xcorr.dat [SNR]"
	echo "  "
	echo "        npar_rng    - number of parameters to fit in range "
	echo "        npar_aiz    - number of parameters to fit in azimuth "
	echo "        xcorr.dat   - files of range and azimuth offestimates "
	echo "        SNR         - optional SNR cutoff (default 20)"
	echo "  "
	echo "Example: fitoffset.bash 3 3 freq_xcorr.dat "
	echo "  "
	exit 1
fi
#
if [ $# == 4 ]; then
	SNR=$4
else
	SNR=20.
fi

#
#  first extract the range and azimuth data
#
awk '{ if ($5 > '$SNR') printf("%f %f %f \n",$1,$3,$2); }' <$3 >r.xyz
awk '{ if ($5 > '$SNR') printf("%f %f %f \n",$1,$3,$4); }' <$3 >a.xyz
#
#  make sure there are enough points remaining, otherwise exit
#
NPTS0=$(wc -l $3 | awk '{print $1}')
NPTS=$(wc -l r.xyz | awk '{print $1}')
if [ $NPTS -lt 8 ]; then
	echo "  "
	echo " FAILED - not enough points to estimate parameters"
	echo " try lower SNR "
	echo " NPTS0, NPTS  " $NPTS0 $NPTS
	echo "  "
	exit 1
fi

#
# compute requested number of parameters
#
azi_p=$2
rng_p=$1

(gmt trend2d r.xyz -Fxyz -N"$rng_p"r -V >/dev/null) |& grep oefficients | awk -F":" '{print $NF, 0, 0, 0'} >rm.coef
(gmt trend2d a.xyz -Fxyz -N"$azi_p"r -V >/dev/null) |& grep oefficients | awk -F":" '{print $NF, 0 ,0, 0'} >am.coef
awk '{print $1, $2, $3}' <rm.coef >tmp.coef
mv tmp.coef rm.coef
awk '{print $1, $2, $3}' <am.coef >tmp.coef
mv tmp.coef am.coef
#
#  get the data range and paste to the coeffifients
#
gmt gmtinfo r.xyz -C | awk '{print $1, $2, $3, $4 }' >range.coef
paste rm.coef range.coef >rm.rng
paste am.coef range.coef >am.rng
rm am.coef rm.coef range.coef
#
#   now convert to range coefficients
#
awk '{print ( $1 - $2*($5+$4)/($5-$4) -$3*($7+$6)/($7-$6) ) }' <rm.rng >rshift
awk '{if($1 >= 0) {printf("%s %g \n","rshift=",int($1)); printf("%s %g \n","sub_int_r=",($1 %1))}}' <rshift
awk '{if($1 < 0)  {printf("%s %g \n","rshift=",int($1)-1); printf("%s %g \n","sub_int_r=",($1 %1)+1)}}' <rshift
awk '{printf ("%s %g \n","stretch_r=",$2*2./($5-$4))}' <rm.rng
awk '{printf ("%s %g \n","a_stretch_r=",$3*2./($7-$6))}' <rm.rng
#
#  now convert to azimuth coefficients
#
awk '{print ( $1 - $2*($5+$4)/($5-$4) -$3*($7+$6)/($7-$6) ) }' <am.rng >ashift
awk '{if($1 >= 0) {printf("%s %g \n","ashift=",int($1)); printf("%s %g \n","sub_int_a=",($1 %1))}}' <ashift
awk '{if($1 < 0)  {printf("%s %g \n","ashift=",int($1)-1); printf("%s %g \n","sub_int_a=",($1 %1)+1)}}' <ashift
awk '{printf ("%s %g \n","stretch_a=",$2*2./($5-$4))}' <am.rng
awk '{printf ("%s %g \n","a_stretch_a=",$3*2./($7-$6))}' <am.rng
#
#  cleanup
#
rm rshift ashift rm.rng am.rng
#
#  OK we are done
#
#  echo " NPTS0, NPTS  " $NPTS0 $NPTS
