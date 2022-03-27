#!/bin/bash
#       $Id$
# Xiaopeng Tong Nov 23 2009
#
#
# Converts a complex SLC file to a real amplitude grd
# file using optional filter and a PRM file
#
# define the filters
#
sharedir=$(gmtsar_sharedir.bash)
fil1=$sharedir/filters/gauss5x3
fil2=$sharedir/filters/gauss9x5
#
# check for number of arguments
#
if [ $# -ne 3 ]; then
  echo ""
  echo "Usage: slc2amp.bash filein.PRM rng_dec fileout.grd "
  echo ""
  echo "       rng_dec is range decimation"
  echo "       e.g. 1 for ERS ENVISAT ALOS FBD"
  echo "            2 for ALOS FBS "
  echo "            4 for TSX"
  echo ""
  echo "Example: slc2amp.bash IMG-HH-ALPSRP055750660-H1.0__A.PRM 2 amp-ALPSRP055750660-H1.0__A.grd"
  echo ""
  exit 1
fi
#
# filter the amplitudes done in conv
# check the input and output filename before
#
if [[ $1 =~ *PRM* ]] || [[ $1 =~ *prm* ]] && [[ $3 =~ *grd* ]]; then
  echo " range decimation is:" $2
  conv 4 $2 $fil1 $1 $3=bf
else
  echo "slc2amp.bash"
  echo "wrong filename"
  exit 1
fi
#
# get the zmin and zmax value
#
gmt grdmath $3=bf 1 MUL=$3
