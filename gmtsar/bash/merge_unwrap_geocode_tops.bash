#!/bin/bash
#       $Id$
#
#
#    Xiaohua(Eric) XU, July 7, 2016
#
# Script for merging 3 subswaths TOPS interferograms and then unwrap and geocode.
#
if [ $# != 2 ]; then
  echo ""
  echo "Usage: merge_unwrap_geocode_tops.bash inputfile config_file"
  echo ""
  echo "Note: Inputfiles should be as following:"
  echo ""
  echo "      Swath1_Path:Swath1_master.PRM:Swath1_repeat.PRM"
  echo "      Swath2_Path:Swath2_master.PRM:Swath2_repeat.PRM"
  echo "      Swath3_Path:Swath3_master.PRM:Swath3_repeat.PRM"
  echo "      (Use the repeat PRM which contains the shift information.)"
  echo "      e.g. ../F1/intf/2015016_2015030/:S1A20151012_134357_F1.PRM"
  echo ""
  echo "      Make sure under each path, the processed phasefilt.grd, corr.grd and mask.grd exist."
  echo "      Also make sure the dem.grd is linked. "
  echo ""
  echo "      config_file is the same one used for processing."
  echo ""
  echo "Example: merge_unwrap_geocode_tops.bash filelist batch.config"
  echo ""
  exit 1
fi

if [ -f tmp_phaselist ]; then
  rm tmp_phaselist
fi
if [ -f tmp_corrlist ]; then
  rm tmp_corrlist
fi
if [ -f tmp_masklist ]; then
  rm tmp_masklist
fi

if [ ! -f dem.grd ]; then
  echo "Please link dem.grd to current folder"
  exit 1
fi

region_cut=$(grep region_cut $2 | awk '{print $3}')

# Creating inputfiles for merging
for line in $(awk '{print $0}' $1); do

  now_dir=$(pwd)
  pth=$(echo $line | awk -F: '{print $1}')
  prm=$(echo $line | awk -F: '{print $2}')
  prm2=$(echo $line | awk -F: '{print $3}')
  cd $pth
  rshift=$(grep rshift $prm2 | tail -1 | awk '{print $3}')
  fs1=$(grep first_sample $prm | awk '{print $3}')
  fs2=$(grep first_sample $prm2 | awk '{print $3}')
  cp $prm tmp.PRM
  if [ $fs2 ] >$fs1; then
    update_PRM tmp.PRM first_sample $fs2
  fi
  update_PRM tmp.PRM rshift $rshift
  cd $now_dir

  echo $pth"tmp.PRM:"$pth"phasefilt.grd" >>tmp_phaselist
  echo $pth"tmp.PRM:"$pth"corr.grd" >>tmp_corrlist
  echo $pth"tmp.PRM:"$pth"mask.grd" >>tmp_masklist
done

pth=$(awk -F: 'NR==1 {print $1}' $1)
stem=$(awk -F: 'NR==1 {print $2}' $1 | awk -F"." '{print $1}')
#echo $pth $stem

echo ""
echo "Merging START"
echo "Calculating valid starting columns of data ..."
nl=$(wc -l $1 | awk '{print $1}')
if [ $nl -eq 2 ]; then
  pth2=$(head -1 $1 | awk -F: '{print $1}')
  gmt grdcut $pth2/phasefilt.grd -Z+N -Gtmp.grd
  xm1=$(gmt grdinfo $pth2/phasefilt.grd -C | awk '{print $3}')
  xc1=$(gmt grdinfo tmp.grd -C | awk '{print $3}')
  incx=$(gmt grdinfo tmp.grd -C | awk '{print $8}')
  n12=$(echo $xm1 $xc1 $incx | awk '{printf("%d",($1-$2)/$3)}')

  pth2=$(tail -1 $1 | awk -F: '{print $1}')
  gmt grdcut $pth2/phasefilt.grd -Z+N -Gtmp.grd
  x01=$(gmt grdinfo tmp.grd -C | awk '{print $2}')
  incx=$(gmt grdinfo tmp.grd -C | awk '{print $8}')
  n21=$(echo $x01 $incx | awk '{printf("%d",$1/$2)}')
  n1=$(echo $n12 $n21 | awk '{printf("%d",($1+$2)/2)}')
  n2=0
  rm tmp.grd
elif [ $nl -eq 3 ]; then
  pth2=$(head -1 $1 | awk -F: '{print $1}')
  gmt grdcut $pth2/phasefilt.grd -Z+N -Gtmp.grd
  xm1=$(gmt grdinfo $pth2/phasefilt.grd -C | awk '{print $3}')
  xc1=$(gmt grdinfo tmp.grd -C | awk '{print $3}')
  incx=$(gmt grdinfo tmp.grd -C | awk '{print $8}')
  n12=$(echo $xm1 $xc1 $incx | awk '{printf("%d",($1-$2)/$3)}')

  pth2=$(head -2 $1 | tail -1 | awk -F: '{print $1}')
  gmt grdcut $pth2/phasefilt.grd -Z+N -Gtmp.grd
  x02=$(gmt grdinfo tmp.grd -C | awk '{print $2}')
  incx=$(gmt grdinfo tmp.grd -C | awk '{print $8}')
  n21=$(echo $x02 $incx | awk '{printf("%d",$1/$2)}')
  n1=$(echo $n12 $n21 | awk '{printf("%d",($1+$2)/2)}')
  xm2=$(gmt grdinfo $pth2/phasefilt.grd -C | awk '{print $3}')
  xc2=$(gmt grdinfo tmp.grd -C | awk '{print $3}')
  n22=$(echo $xm1 $xc1 $incx | awk '{printf("%d",($1-$2)/$3)}')

  pth2=$(tail -1 $1 | awk -F: '{print $1}')
  gmt grdcut $pth2/phasefilt.grd -Z+N -Gtmp.grd
  x03=$(gmt grdinfo tmp.grd -C | awk '{print $2}')
  incx=$(gmt grdinfo tmp.grd -C | awk '{print $8}')
  n31=$(echo $x03 $incx | awk '{printf("%d",$1/$2)}')
  n2=$(echo $n22 $n31 | awk '{printf("%d",($1+$2)/2)}')
  rm tmp.grd
else
  echo "Incorrect number of records in input filelist .."
  exit 1
fi
echo "Stitching postitions set to $n1 $n2"

merge_swath tmp_phaselist phasefilt.grd $stem $n1 $n2 >merge_log
merge_swath tmp_corrlist corr.grd $n1 $n2 >merge_log_corr
merge_swath tmp_masklist mask.grd $n1 $n2 >merge_log_mask
echo "Merging END"
echo ""

iono=$(grep correct_iono $2 | awk '{print $3}')
skip_iono=$(grep iono_skip_est $2 | awk '{print $3}')
if [ $iono != 0 ] && [ $skip_iono -eq 0 ]; then
  if [ ! -f ph_iono_orig.grd ]; then
    echo "Need ph_iono_orig.grd to correct ionosphere ..."
  else
    echo "Correcting ionosphere ..."
    gmt grdsample ph_iono_orig.grd -Rphasefilt.grd -Gtmp.grd
    gmt grdmath phasefilt.grd tmp.grd SUB PI ADD 2 PI MUL MOD PI SUB = tmp2.grd
    mv phasefilt.grd phasefilt_orig.grd
    mv tmp2.grd phasefilt.grd
    rm tmp.grd
  fi
fi

# This step is essential, cut the DEM so it can run faster.
if [ ! -f trans.dat ]; then
  led=$(grep led_file $pth$stem".PRM" | awk '{print $3}')
  cp $pth$led .
  echo "Recomputing the projection LUT..."
  # Need to compute the geocoding matrix with supermaster.PRM with rshift set to 0
  rshift=$(grep rshift $stem".PRM" | tail -1 | awk '{print $3}')
  update_PRM $stem".PRM" rshift 0
  gmt grd2xyz --FORMAT_FLOAT_OUT=%lf dem.grd -s | SAT_llt2rat $stem".PRM" 1 -bod >trans.dat
  # Set rshift back for other usage
  update_PRM $stem".PRM" rshift $rshift
fi

# Read in parameters
threshold_snaphu=$(grep threshold_snaphu $2 | awk '{print $3}')
threshold_geocode=$(grep threshold_geocode $2 | awk '{print $3}')
region_cut=$(grep region_cut $2 | awk '{print $3}')
switch_land=$(grep switch_land $2 | awk '{print $3}')
defomax=$(grep defomax $2 | awk '{print $3}')
near_interp=$(grep near_interp $2 | awk '{print $3}')
mask_water=$(grep mask_water $2 | awk '{print $3}')

# Unwrapping
if [ -n "$region_cut" ]; then
  region_cut=$(gmt grdinfo phasefilt.grd -I- | cut -c3-20)
fi
if [ $threshold_snaphu != 0 ]; then
  if [ $mask_water -eq 1 ] || [ $switch_land -eq 1 ]; then
    if [ ! -f landmask_ra.grd ]; then
      landmask.bash $region_cut
    fi
  fi

  echo ""
  echo "SNAPHU.bash - START"
  echo "threshold_snaphu: $threshold_snaphu"
  if [ $near_interp -eq 1 ]; then
    snaphu_interp.bash $threshold_snaphu $defomax $region_cut
  else
    snaphu.bash $threshold_snaphu $defomax $region_cut
  fi
  echo "SNAPHU.bash - END"
else
  echo ""
  echo "SKIP UNWRAP PHASE"
fi

# Geocoding
#if (-f raln.grd) rm raln.grd
#if (-f ralt.grd) rm ralt.grd

if [ $threshold_geocode != 0 ]; then
  echo ""
  echo "GEOCODE-START"
  proj_ra2ll.bash trans.dat phasefilt.grd phasefilt_ll.grd
  gmt grdmath corr.grd $threshold_geocode GE 0 NAN mask.grd MUL = mask2.grd
  gmt grdmath phasefilt.grd mask2.grd MUL = phasefilt_mask.grd
  proj_ra2ll.bash trans.dat phasefilt_mask.grd phasefilt_mask_ll.grd
  proj_ra2ll.bash trans.dat corr.grd corr_ll.grd
  gmt makecpt -Crainbow -T-3.15/3.15/0.05 -Z >phase.cpt
  BT=$(gmt grdinfo -C corr.grd | awk '{print $7}')
  gmt makecpt -Cgray -T0/$BT/0.05 -Z >corr.cpt
  grd2kml.bash phasefilt_ll phase.cpt
  grd2kml.bash phasefilt_mask_ll phase.cpt
  grd2kml.bash corr_ll corr.cpt

  if [ -f unwrap.grd ]; then
    gmt grdmath unwrap.grd mask2.grd MUL = unwrap_mask.grd
    proj_ra2ll.bash trans.dat unwrap.grd unwrap_ll.grd
    proj_ra2ll.bash trans.dat unwrap_mask.grd unwrap_mask_ll.grd
    BT=$(gmt grdinfo -C unwrap.grd | awk '{print $7}')
    BL=$(gmt grdinfo -C unwrap.grd | awk '{print $6}')
    gmt makecpt -T$BL/$BT/0.5 -Z >unwrap.cpt
    grd2kml.bash unwrap_mask_ll unwrap.cpt
    grd2kml.bash unwrap_ll unwrap.cpt
  fi

  echo "GEOCODE END"
fi

rm tmp_phaselist tmp_corrlist tmp_masklist *.eps *.bb
