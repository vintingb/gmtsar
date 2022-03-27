#!/bin/bash
#
#  Preprocess the data to Raw or SLC or aligned SLC depending on which satellite to use
#

alias rm='rm -f'

#
# check the number of arguments
#
if [ $# -ne 3 ]; then
  echo ""
  echo "Usage: pre_proc.bash SAT master_stem aligned_stem [-near near_range] [-radius RE] [-npatch num_patches] [-fd1 DOPP] [-ESD mode]"
  echo ""
  echo "Example: pre_proc.bash S1_TOPS s1a-iw1-slc-vv-20150526t014935-20150526t015000-006086-007e23-001 s1a-iw1-slc-vv-20150607t014936-20150607t015001-006261-00832e-004"
  echo ""
  exit 1
fi
#
# parse the command line arguments
#
echo "pre_proc.bash"
SAT=$1
master=$(echo $2)
aligned=$(echo $3)

if [[ $SAT == "S1_TOPS" ]]; then
  echo ""
  echo " Pre-Process S1_TOPS data - START"
  echo ""
  if [ ! -f ../topo/dem.grd ]; then
    echo "missing file ../topo/dem.grd"
    exit 1
  fi
  ln -s ../topo/dem.grd .

  iono=""
  ESD=$(grep spec_div config* | head -1 | awk '{print $3}')
  if [ -z "$ESD" ]; then ESD=$(grep spec_div ../config* | head -1 | awk '{print $3}'); fi
  ESD_mode=$(grep spec_mode config* | head -1 | awk '{print $3}')
  if [ -z "$ESD_mode" ]; then ESD_mode=$(grep spec_mode ../config* | head -1 | awk '{print $3}'); fi
  if [ -z "$iono" ]; then iono=$(grep correct_iono config* | head -1 | awk '{print $3}'); fi
  if [ -z "$iono" ]; then iono=$(grep correct_iono ../config* | head -1 | awk '{print $3}'); fi

  if [ "x$iono" == "x0" ] || [ -z "$iono" ]; then
    if [ "x$ESD" == "x0" ] || [ -z "$ESD" ]; then
      echo "align_tops.bash $master $master.EOF $aligned $aligned.EOF dem.grd"
      align_tops.bash $master $master.EOF $aligned $aligned.EOF dem.grd >& align_tops.log
    else
      if [ -z "$ESD_mode" ]; then
        echo "align_tops.bash $master $master.EOF $aligned $aligned.EOF dem.grd"
        align_tops.bash $master $master.EOF $aligned $aligned.EOF dem.grd >&align_tops.log
      else
        align_tops_esd.bash $master $master.EOF $aligned $aligned.EOF dem.grd $ESD_mode >&align_tops_esd.log
      fi
    fi
  else
    echo "Running align TOPS script with BESD for ionospheric correction"
    align_tops_esd.bash $master $master.EOF $aligned $aligned.EOF dem.grd 2 >&align_tops_esd.log
  fi
  echo ""
  echo " Pre-Process S1_TOPS data - END"
  echo ""

fi

#
