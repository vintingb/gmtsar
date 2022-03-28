#!/bin/bash
#
if [ $# != 4 ]; then
  echo ""
  echo "Usage: p2p_processing.bash SAT master_image aligned_image configuration_file "
  echo ""
  echo "Example: p2p_processing.bash S1_TOPS s1a-iw1-slc-vv-20150526t014935-20150526t015000-006086-007e23-001 s1a-iw1-slc-vv-20150607t014936-20150607t015001-006261-00832e-004 config.txt"
  echo ""
  echo "    Make sure the files from the same date have the same stem, e.g. aaaa.tif aaaa.xml aaaa.cos aaaa.EOF, etc"
  echo ""
  echo ""
  exit 1
fi

# start
#  Make sure the config exist
if [ $# == 4 ]; then
  if [ ! -f "$4" ]; then
    echo " no configure file: $4"
    echo " Leave it blank to generate config file with default values."
    exit 1
  fi
fi

#
#  Read parameters from the configure file
#
SAT=$1
conf=$4

# conf may need to be changed later on
stage=$(grep proc_stage "$conf" | awk '{print $3}')
s_stages=$(grep skip_stage "$conf" | awk '{print $3}' | awk -F, '{print $1,$2,$3,$4,$5,$6}')
skip_1=0
skip_2=0
skip_3=0
skip_4=0
skip_5=0
skip_6=0
for line in $s_stages; do
  if [ "$line" -eq 1 ]; then
    skip_1=1
  fi
  if [ "$line" -eq 2 ]; then
    skip_2=1
  fi
  if [ "$line" -eq 3 ]; then
    skip_3=1
  fi
  if [ "$line" -eq 4 ]; then
    skip_4=1
  fi
  if [ "$line" -eq 5 ]; then
    skip_5=1
  fi
  if [ "$line" -eq 6 ]; then
    skip_6=1
  fi
done

num_patches=$(grep num_patches "$conf" | awk '{print $3}')
# near_range=$(grep near_range $conf | awk '{print $3}')
earth_radius=$(grep earth_radius "$conf" | awk '{print $3}')
# fd=$(grep fd1 $conf | awk '{print $3}')
topo_phase=$(grep topo_phase "$conf" | awk '{print $3}')
shift_topo=$(grep shift_topo "$conf" | awk '{print $3}')
switch_master=$(grep switch_master "$conf" | awk '{print $3}')
filter=$(grep filter_wavelength "$conf" | awk '{print $3}')
compute_phase_gradient=$(grep compute_phase_gradient "$conf" | awk '{print $3}')
iono=$(grep correct_iono "$conf" | awk '{print $3}')
if [ -n "$filter" ]; then
  iono=0
fi
iono_filt_rng=$(grep iono_filt_rng "$conf" | awk '{print $3}')
iono_filt_azi=$(grep iono_filt_azi "$conf" | awk '{print $3}')
iono_dsamp=$(grep iono_dsamp "$conf" | awk '{print $3}')
iono_skip_est=$(grep iono_skip_est "$conf" | awk '{print $3}')
spec_div=$(grep spec_div "$conf" | awk '{print $3}')
spec_mode=$(grep spec_mode "$conf" | awk '{print $3}')
#  filter=200
#  echo " "
#  echo "WARNING filter wavelength was not in config.txt file"
#  echo "        please specify wavelength (e.g., filter_wavelength=200)"
#  echo "        remove filter1=gauss_alos_200m"
#fi
dec=$(grep dec_factor "$conf" | awk '{print $3}')
threshold_snaphu=$(grep threshold_snaphu "$conf" | awk '{print $3}')
threshold_geocode=$(grep threshold_geocode "$conf" | awk '{print $3}')
region_cut=$(grep region_cut "$conf" | awk '{print $3}')
mask_water=$(grep mask_water "$conf" | awk '{print $3}')
switch_land=$(grep switch_land "$conf" | awk '{print $3}')
defomax=$(grep defomax "$conf" | awk '{print $3}')
range_dec=$(grep range_dec "$conf" | awk '{print $3}')
azimuth_dec=$(grep azimuth_dec "$conf" | awk '{print $3}')
SLC_factor=$(grep SLC_factor "$conf" | awk '{print $3}')
near_interp=$(grep near_interp "$conf" | awk '{print $3}')
master=$2
aligned=$3

#
#  combine preprocess parameters
#
commandline=""
if [[ -n $earth_radius ]]; then
  commandline="$commandline -radius $earth_radius"
fi
if [[ -n $num_patches ]]; then
  commandline="$commandline -npatch $num_patches"
fi
if [[ -n $SLC_factor ]]; then
  commandline="$commandline -SLC_factor $SLC_factor"
fi

#############################
# 1 - start from preprocess #
#############################
#
#   make sure the files exist
#
if [ "$stage" -eq 1 ] && [ $skip_1 -eq 0 ]; then
  echo ""
  echo "PREPROCESS - START"
  echo ""
  echo "Working on images $master $aligned ..."
  if [[ $SAT == "S1_TOPS" ]]; then
    if [ ! -f raw/"$master".EOF ]; then
      echo " no file  raw/"$master".EOF"
    fi
    if [ ! -f raw/$aligned.EOF ]; then
      echo " no file  raw/"$aligned".EOF"
    fi
    if [ ! -f raw/$master.xml ]; then
      echo " no file  raw/"$master".xml"
      exit
    fi
    if [ ! -f raw/$aligned.xml ]; then
      echo " no file  raw/"$aligned".xml"
      exit
    fi
  fi

  cd raw
  if [ -f "*.PRM*" ]; then
    rm ./*.PRM*
  fi
  if [ -f "*.SLC" ]; then
    rm ./*.SLC
  fi
  if [ -f "*.LED" ]; then
    rm ./*.LED
  fi

  echo "pre_proc.bash $SAT $master $aligned $commandline"
  # pre_proc.bash S1_TOPS s1a-iw1-slc-vv-20150526t014935-20150526t015000-006086-007e23-001 s1a-iw1-slc-vv-20150607t014936-20150607t015001-006261-00832e-004
  pre_proc.bash $SAT $master $aligned $commandline >&pre_proc.log
  cd ..
  echo " "
  echo "PREPROCESS - END"
  echo ""
fi
#############################################
# 2 - start from focus and align SLC images #
#############################################
#

mkdir -p intf SLC
if [ $iono -eq 1 ]; then
  mkdir -p SLC_L
  mkdir -p SLC_H
fi

if [ $SAT == "S1_TOPS" ]; then
  master=$(echo $master | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
  aligned=$(echo $aligned | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
fi

if [ $stage -le 2 ] && [ $skip_2 -eq 0 ]; then
  cleanup.bash SLC
  if [ $iono -eq 1 ]; then
    rm -rf SLC_L/* SLC_H/*
  fi
fi

#
# focus and align SLC images
#
echo " "
echo "ALIGN.bash - START"
echo ""
cd SLC

if [ $SAT == "S1_TOPS" ]; then
  cp ../raw/*.PRM .
  ln -s ../raw/$master.SLC .
  ln -s ../raw/$aligned.SLC .
  ln -s ../raw/$master.LED .
  ln -s ../raw/$aligned.LED .

  if [ $iono == 1 ]; then
    cd ..
    mkdir -p SLC_L
    mkdir -p SLC_H
    cd SLC
    ln -s ../raw/$2.tiff .
    ln -s ../raw/$3.tiff .
    split_spectrum $master.PRM >params1
    mv high.tiff ../SLC_H/$2.tiff
    mv low.tiff ../SLC_L/$2.tiff
    split_spectrum $aligned.PRM >params2
    mv high.tiff ../SLC_H/$3.tiff
    mv low.tiff ../SLC_L/$3.tiff

    cd ../SLC_L
    ln -s ../raw/$2.xml .
    ln -s ../raw/$2.EOF .
    ln -s ../raw/$3.xml .
    ln -s ../raw/$3.EOF .
    ln -s ../topo/dem.grd .
    ln -s ../raw/a.grd .
    ln -s ../raw/r.grd .
    ln -s ../raw/offset*.dat .
    if [ $spec_div == 1 ]; then
      align_tops_esd.bash $2 $2.EOF $3 $3.EOF dem.grd 1 $spec_mode
    else
      align_tops.bash $2 $2.EOF $3 $3.EOF dem.grd 1
    fi

    wl1=$(grep low_wavelength ../SLC/params1 | awk '{print $3}')
    wl2=$(grep low_wavelength ../SLC/params2 | awk '{print $3}')
    #cp ../raw/$master.PRM .
    #ln -s ../raw/$master.LED .
    sed "s/.*wavelength.*/radar_wavelength  =$wl1/g" $master.PRM >tmp
    mv tmp $master.PRM
    #cp ../raw/$aligned.PRM .
    #ln -s ../raw/$aligned.LED .
    sed "s/.*wavelength.*/radar_wavelength  =$wl2/g" $aligned.PRM >tmp
    mv tmp $aligned.PRM

    cd ../SLC_H
    ln -s ../raw/$2.xml .
    ln -s ../raw/$2.EOF .
    ln -s ../raw/$3.xml .
    ln -s ../raw/$3.EOF .
    ln -s ../topo/dem.grd .
    ln -s ../raw/a.grd .
    ln -s ../raw/r.grd .
    ln -s ../raw/offset*.dat .
    if [ $spec_div == 1 ]; then
      align_tops_esd.bash $2 $2.EOF $3 $3.EOF dem.grd 1 $spec_mode
    else
      align_tops.bash $2 $2.EOF $3 $3.EOF dem.grd 1
    fi

    wh1=$(grep high_wavelength ../SLC/params1 | awk '{print $3}')
    wh2=$(grep high_wavelength ../SLC/params2 | awk '{print $3}')
    #cp ../raw/$master.PRM .
    #ln -s ../raw/$master.LED .
    sed "s/.*wavelength.*/radar_wavelength  =$wh1/g" $master.PRM >tmp
    mv tmp $master.PRM
    #cp ../raw/$aligned.PRM .
    #ln -s ../raw/$aligned.LED .
    sed "s/.*wavelength.*/radar_wavelength  =$wh2/g" $aligned.PRM >tmp
    mv tmp $aligned.PRM

    cd ../SLC

  fi

  if [[ -n $region_cut ]]; then
    echo "Cutting SLC image to $region_cut"
    cut_slc $master.PRM junk1 $region_cut
    cut_slc $aligned.PRM junk2 $region_cut
    mv junk1.PRM $master.PRM
    mv junk2.PRM $aligned.PRM
    mv junk1.SLC $master.SLC
    mv junk2.SLC $aligned.SLC

    if [ $iono -eq 1 ]; then
      cd ../SLC_L
      cut_slc $master.PRM junk1 $region_cut
      cut_slc $aligned.PRM junk2 $region_cut
      mv junk1.PRM $master.PRM
      mv junk2.PRM $aligned.PRM
      mv junk1.SLC $master.SLC
      mv junk2.SLC $aligned.SLC

      cd ../SLC_H
      cut_slc $master.PRM junk1 $region_cut
      cut_slc $aligned.PRM junk2 $region_cut
      mv junk1.PRM $master.PRM
      mv junk2.PRM $aligned.PRM
      mv junk1.SLC $master.SLC
      mv junk2.SLC $aligned.SLC

    fi

  fi

  cd ..
  echo ""
  echo "ALIGN.bash - END"
  echo ""

fi
##################################
# 3 - start from make topo_ra  #
##################################
#
if [ $stage -le 3 ] && [ $skip_3 == 0 ]; then
  #
  # clean up
  #
  cleanup.bash topo
  #
  # make topo_ra if there is dem.grd
  #
  if [ $topo_phase -eq 1 ]; then
    echo " "
    echo "DEM2TOPO_RA.bash - START"
    echo "USER SHOULD PROVIDE DEM FILE"
    cd topo
    cp ../SLC/$master.PRM master.PRM
    ln -s ../raw/$master.LED .
    if [ -f dem.grd ]; then
      dem2topo_ra.bash master.PRM dem.grd >&dem2topo_ra.log
    else
      echo "no DEM file found: " dem.grd
      exit 1
    fi
    cd ..
    echo "DEM2TOPO_RA.bash - END"
    #
    # shift topo_ra
    #
    if [ $shift_topo == 1 ]; then
      echo " "
      echo "OFFSET_TOPO - START"
      cd SLC
      # rng_samp_rate=$(grep rng_samp_rate $master.PRM | awk 'NR == 1 {printf("%d", $3)}')
      rng=$(gmt grdinfo ../topo/topo_ra.grd | grep x_inc | awk '{print $7}')
      slc2amp.bash $master.PRM $rng amp-$master.grd
      cd ..
      cd topo
      ln -s ../SLC/amp-$master.grd .
      offset_topo amp-$master.grd topo_ra.grd 0 0 7 topo_shift.grd
      cd ..
      echo "OFFSET_TOPO - END"
    elif [ $shift_topo == 0 ]; then
      echo "NO TOPO_RA SHIFT "
    else
      echo "Wrong paramter: shift_topo "$shift_topo
      exit 1
    fi
  elif [ $topo_phase == 0 ]; then
    echo "NO TOPO_RA IS SUBSTRACTED"
  else
    echo "Wrong paramter: topo_phase "$topo_phase
    exit 1
  fi
fi

##################################################
# 4 - start from make and filter interferograms  #
##################################################
#

#
# select the master
#
if [ $switch_master == 0 ]; then
  ref=$master
  rep=$aligned
elif [ $switch_master == 1 ]; then
  ref=$aligned
  rep=$master
else
  echo "Wrong paramter: switch_master "$switch_master
fi
if [ $stage -le 4 ] && [ $skip_4 == 0 ]; then
  #
  # clean up
  #
  cleanup.bash intf

  echo " "
  echo "INTF.bash, FILTER.bash - START"
  cd intf/
  ref_id=$(grep SC_clock_start ../raw/$ref.PRM | awk '{printf("%d",int($3))}')
  rep_id=$(grep SC_clock_start ../raw/$rep.PRM | awk '{printf("%d",int($3))}')
  mkdir $ref_id"_"$rep_id
  cd $ref_id"_"$rep_id
  ln -s ../../SLC/$ref.LED .
  ln -s ../../SLC/$rep.LED .
  ln -s ../../SLC/$ref.SLC .
  ln -s ../../SLC/$rep.SLC .
  cp ../../SLC/$ref.PRM .
  cp ../../SLC/$rep.PRM .
  if [ $topo_phase -eq 1 ]; then
    if [ $shift_topo -eq 1 ]; then
      ln -s ../../topo/topo_shift.grd .
      intf.bash $ref.PRM $rep.PRM -topo topo_shift.grd >&intf.log
      filter.bash $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec $compute_phase_gradient >&filter.log
    else
      ln -s ../../topo/topo_ra.grd .
      echo "intf.bash $ref.PRM $rep.PRM -topo topo_ra.grd &>intf.log"
      intf.bash $ref.PRM $rep.PRM -topo topo_ra.grd &>intf.log
      echo "filter.bash $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec $compute_phase_gradient &> filter.log"
      filter.bash $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec $compute_phase_gradient &>filter.log
    fi
  else
    echo "NO TOPOGRAPHIC PHASE REMOVAL PORFORMED"
    intf.bash $ref.PRM $rep.PRM >&intf.log
    filter.bash $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec $compute_phase_gradient >&filter.log
  fi
  cd ../..
  if [ $iono -eq 1 ]; then
    if [ -e iono_phase ]; then
      rm -r iono_phase
    fi
    mkdir -p iono_phase
    cd iono_phase
    mkdir -p intf_o intf_h intf_l iono_correction

    new_incx=$(echo $range_dec $iono_dsamp | awk '{print $1*$2}')
    new_incy=$(echo $azimuth_dec $iono_dsamp | awk '{print $1*$2}')

    echo ""
    cd intf_h
    ln -s ../../SLC_H/*.SLC .
    ln -s ../../SLC_H/*.LED .
    cp ../../SLC_H/*.PRM .
    cp ../../SLC/params* .
    if [ $topo_phase == 1 ]; then
      if [ $shift_topo == 1 ]; then
        ln -s ../../topo/topo_shift.grd .
        intf.bash $ref.PRM $rep.PRM -topo topo_shift.grd
        filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      else
        ln -s ../../topo/topo_ra.grd .
        intf.bash $ref.PRM $rep.PRM -topo topo_ra.grd
        filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      fi
    else
      echo "NO TOPOGRAPHIC PHASE REMOVAL PORFORMED"
      intf.bash $ref.PRM $rep.PRM
      filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
    fi
    cp phase.grd phasefilt.grd
    if [ $iono_skip_est == 0 ]; then
      if [ $mask_water == 1 ] || [ $switch_land == 1 ]; then
        rcut=$(gmt grdinfo phase.grd -I- | cut -c3-20)
        cd ../../topo
        landmask.bash $rcut
        cd ../iono_phase/intf_h
        ln -s ../../topo/landmask_ra.grd .
      fi
      snaphu_interp.bash 0.05 0
    fi
    cd ..

    echo ""
    cd intf_l
    ln -s ../../SLC_L/*.SLC .
    ln -s ../../SLC_L/*.LED .
    cp ../../SLC_L/*.PRM .
    cp ../../SLC/params* .
    if [ $topo_phase == 1 ]; then
      if [ $shift_topo == 1 ]; then
        ln -s ../../topo/topo_shift.grd .
        intf.bash $ref.PRM $rep.PRM -topo topo_shift.grd
        filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      else
        ln -s ../../topo/topo_ra.grd .
        intf.bash $ref.PRM $rep.PRM -topo topo_ra.grd
        filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      fi
    else
      echo "NO TOPOGRAPHIC PHASE REMOVAL PORFORMED"
      intf.bash $ref.PRM $rep.PRM
      filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
    fi
    cp phase.grd phasefilt.grd
    if [ $iono_skip_est == 0 ]; then
      if [ $mask_water == 1 ] || [ $switch_land == 1 ]; then
        ln -s ../../topo/landmask_ra.grd .
        snaphu_interp.bash 0.05 0
      fi
    fi
    cd ..

    echo ""
    cd intf_o
    ln -s ../../SLC/*.SLC .
    ln -s ../../SLC/*.LED .
    cp ../../SLC/*.PRM .
    if [ $topo_phase == 1 ]; then
      if [ $shift_topo == 1 ]; then
        ln -s ../../topo/topo_shift.grd .
        intf.bash $ref.PRM $rep.PRM -topo topo_shift.grd
        filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      else
        ln -s ../../topo/topo_ra.grd .
        intf.bash $ref.PRM $rep.PRM -topo topo_ra.grd
        filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      fi
    else
      echo "NO TOPOGRAPHIC PHASE REMOVAL PORFORMED"
      intf.bash $ref.PRM $rep.PRM
      filter.bash $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
    fi
    cp phase.grd phasefilt.grd
    if [ $iono_skip_est == 0 ]; then
      if [ $mask_water == 1 ] || [ $switch_land == 1 ]; then ln -s ../../topo/landmask_ra.grd .; fi
      snaphu_interp.bash 0.05 0
    fi
    cd ../iono_correction
    echo ""

    if [ $iono_skip_est == 0 ]; then
      estimate_ionospheric_phase.bash ../intf_h ../intf_l ../intf_o ../../intf/$ref_id"_"$rep_id $iono_filt_rng $iono_filt_azi

      cd ../../intf/$ref_id"_"$rep_id
      mv phasefilt.grd phasefilt_non_corrected.grd
      gmt grdsample ../../iono_phase/iono_correction/ph_iono_orig.grd -Rphasefilt_non_corrected.grd -Gph_iono.grd
      gmt grdmath phasefilt_non_corrected.grd ph_iono.grd SUB PI ADD 2 PI MUL MOD PI SUB = phasefilt.grd
      gmt grdimage phasefilt.grd -JX6.5i -Bxaf+lRange -Byaf+lAzimuth -BWSen -Cphase.cpt -X1.3i -Y3i -P -K >phasefilt.ps
      gmt psscale -Rphasefilt.grd -J -DJTC+w5i/0.2i+h -Cphase.cpt -Bxa1.57+l"Phase" -By+lrad -O >>phasefilt.ps
      gmt psconvert -Tf -P -A -Z phasefilt.ps
      #rm phasefilt.ps
    fi
    cd ../../
  fi

  echo "INTF.bash, FILTER.bash - END"
fi
################################
# 5 - start from unwrap phase  #
################################
#
if [ $stage -le 5 ] && [ $skip_5 == 0 ]; then
  if [ $threshold_snaphu == 0 ]; then
    cd intf
    ref_id=$(grep SC_clock_start ../raw/$ref.PRM | awk '{printf("%d",int($3))}')
    rep_id=$(grep SC_clock_start ../raw/$rep.PRM | awk '{printf("%d",int($3))}')
    cd $ref_id"_"$rep_id
    #
    # landmask
    #
    if [ $mask_water == 1 ] || [ $switch_land == 1 ]; then
      r_cut=$(gmt grdinfo phase.grd -I- | cut -c3-20)
      cd ../../topo
      if [ ! -f landmask_ra.grd ]; then
        landmask.bash $r_cut
      fi
      cd ../intf
      cd $ref_id"_"$rep_id
      ln -s ../../topo/landmask_ra.grd .
    fi
    #
    echo " "
    echo "SNAPHU.bash - START"
    echo "threshold_snaphu: $threshold_snaphu"
    #
    if [ $near_interp == 1 ]; then
      snaphu_interp.bash $threshold_snaphu $defomax
    else
      snaphu.bash $threshold_snaphu $defomax
    fi
    #
    echo "SNAPHU.bash - END"
    cd ../..
  else
    echo ""
    echo "SKIP UNWRAP PHASE"
  fi
fi

###########################
# 6 - start from geocode  #
###########################
#
if [ $stage -le 6 ] && [ $skip_6 == 0 ]; then
  if [ $threshold_geocode == 0 ]; then
    cd intf
    ref_id=$(grep SC_clock_start ../raw/$ref.PRM | awk '{printf("%d",int($3))}')
    rep_id=$(grep SC_clock_start ../raw/$rep.PRM | awk '{printf("%d",int($3))}')
    cd $ref_id"_"$rep_id
    echo " "
    echo "GEOCODE.bash - START"
    if [ -f raln.grd ]; then rm raln.grd; fi
    if [ -f ralt.grd ]; then rm ralt.grd; fi
    if [ -f trans.dat ]; then rm trans.dat; fi
    if [ $topo_phase == 1 ]; then
      ln -s ../../topo/trans.dat .
      echo "threshold_geocode: $threshold_geocode"
      geocode.bash $threshold_geocode
    else
      echo "topo_ra is needed to geocode"
      exit 1
    fi
    echo "GEOCODE.bash - END"
    cd ../..
  else
    echo ""
    echo "SKIP GEOCODE"
    echo ""
  fi
fi
#
# end
