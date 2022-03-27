#!/bin/bash
#
#  David Dandwell, December 29, 2015
#
# process Sentinel-1A TOPS data
# Automatically process a single frame of interferogram.
# see instruction.txt for details.
#

alias rm='rm -f'
#
if [ $# -lt 3 ]; then
  echo ""
  echo "Usage: p2p_S1_TOPS.bash master_image aligned_image configuration_file"
  echo ""
  echo "Example: p2p_S1_TOPS.bash S1_20150526_F1 S1_20150607_F1 config.slc.txt "
  echo ""
  exit 1
fi
# start
#
#   make sure the files exist
#
if [ ! -f raw/$1.PRM ] && [ ! -f raw/$1.LED ] && [ ! -f raw/$1.SLC ]; then
  echo " missing input files  raw/"$1
  exit
fi
if [ ! -f raw/$2.PRM ] && [ ! -f raw/$2.LED ] && [ ! -f raw/$2.SLC ]; then
  echo " missing input files  raw/"$2
  exit
fi
if [ ! -f $3 ]; then
  echo " no configure file: "$3
  exit
fi
#
# read parameters from configuration file
#
stage=$(grep proc_stage $3 | awk '{print $3}')
earth_radius=""
earth_radius=$(grep earth_radius $3 | awk '{print $3}')
if [ -z $earth_radius ]; then
  earth_radius=0
fi
topo_phase=$(grep topo_phase $3 | awk '{print $3}')
shift_topo=$(grep shift_topo $3 | awk '{print $3}')
switch_master=$(grep switch_master $3 | awk '{print $3}')
#
# if filter wavelength is not set then use a default of 200m
#
filter=$(grep filter_wavelength $3 | awk '{print $3}')
if [ "x$filter" == "x" ]; then
  filter=200
  echo " "
  echo "WARNING filter wavelength was not set in config.txt file"
  echo "        please specify wavelength (e.g., filter_wavelength = 200)"
  echo "        remove filter1 = gauss_alos_200m"
fi
echo $filter
dec=$(grep dec_factor $3 | awk '{print $3}')
threshold_snaphu=$(grep threshold_snaphu $3 | awk '{print $3}')
threshold_geocode=$(grep threshold_geocode $3 | awk '{print $3}')
region_cut=$(grep region_cut $3 | awk '{print $3}')
switch_land=$(grep switch_land $3 | awk '{print $3}')
defomax=$(grep defomax $3 | awk '{print $3}')
range_dec=$(grep range_dec $3 | awk '{print $3}')
azimuth_dec=$(grep azimuth_dec $3 | awk '{print $3}')
near_interp=$(grep near_interp $3 | awk '{print $3}')
mask_water=$(grep mask_water $3 | awk '{print $3}')
#
# read file names of raw data
#
master=$1
aligned=$2

if [ $switch_master -eq 0 ]; then
  ref=$master
  rep=$aligned
elif [ $switch_master -eq 1 ]; then
  ref=$aligned
  rep=$master
else
  echo "Wrong paramter: switch_master "$switch_master
fi
#
# make working directories
#
mkdir -p intf/ SLC/

#############################
# 1 - start from preprocess #
#############################

if [ $stage -eq 1 ]; then
  #
  # preprocess the raw data
  #
  echo " "
  echo "PREPROCESS - START"
  cd raw
  #
  # preprocess the raw data make the raw data and copy the PRM to PRM00
  # in case the script is run a second time
  #
  #   make_raw.com
  #
  if [ -e $master.PRM00 ]; then
    cp $master.PRM00 $master.PRM
    cp $aligned.PRM00 $aligned.PRM
  else
    cp $master.PRM $master.PRM00
    cp $aligned.PRM $aligned.PRM00
  fi
  #
  # set the num_lines to be the min of the master and aligned
  #
  m_lines=$(grep num_lines ../raw/$master.PRM | awk '{printf("%d",int($3))}')
  s_lines=$(grep num_lines ../raw/$aligned.PRM | awk '{printf("%d",int($3))}')
  if [ $s_lines ] <$m_lines; then
    update_PRM $master.PRM num_lines $s_lines
    update_PRM $master.PRM num_valid_az $s_lines
    update_PRM $master.PRM nrows $s_lines
  else
    update_PRM $aligned.PRM num_lines $m_lines
    update_PRM $aligned.PRM num_valid_az $m_lines
    update_PRM $aligned.PRM nrows $m_lines
  fi
  #
  #   set the higher Doppler terms to zerp to be zero
  #
  update_PRM $master.PRM fdd1 0
  update_PRM $master.PRM fddd1 0
  #
  update_PRM $aligned.PRM fdd1 0
  update_PRM $aligned.PRM fddd1 0
  #
  rm *.log
  rm *.PRM0

  cd ..
  echo "PREPROCESS.bash - END"
fi

#############################################
# 2 - start from focus and align SLC images #
#############################################

if [ $stage -le 2 ]; then
  #
  # clean up
  #
  cleanup.bash SLC
  #
  # align SLC images
  #
  echo " "
  echo "ALIGN - START"
  cd SLC
  cp ../raw/*.PRM .
  ln -s ../raw/$master.SLC .
  ln -s ../raw/$aligned.SLC .
  ln -s ../raw/$master.LED .
  ln -s ../raw/$aligned.LED .

  #    cp $aligned.PRM $aligned.PRM0
  #    resamp $master.PRM $aligned.PRM $aligned.PRMresamp $aligned.SLCresamp 1
  #    rm $aligned.SLC
  #    mv $aligned.SLCresamp $aligned.SLC
  #    cp $aligned.PRMresamp $aligned.PRM
  cd ..
  echo "ALIGN - END"
fi

##################################
# 3 - start from make topo_ra    #
##################################
#if [ 6 == 9 ] ; then
if [ $stage -le 3 ]; then
  #
  # clean up
  #
  cleanup.bash topo
  #
  # make topo_ra if there is dem.grd
  #
  if [ "$topo_phase" -eq 1 ]; then
    echo " "
    echo "DEM2TOPO_RA.bash - START"
    echo "USER SHOULD PROVIDE DEM FILE"
    cd topo
    cp ../SLC/$master.PRM master.PRM
    ln -s ../raw/$master.LED .
    if [ -f dem.grd ]; then
      dem2topo_ra.bash master.PRM dem.grd
    else
      echo "no DEM file found: " dem.grd
      exit 1
    fi
    cd ..
    echo "DEM2TOPO_RA.bash - END"
    #
    # shift topo_ra
    #
    if [ $shift_topo -eq 1 ]; then
      echo " "
      echo "OFFSET_TOPO - START"
      #
      #  make sure the range increment of the amplitude image matches the topo_ra.grd
      #
      rng=$(grdinfo topo/topo_ra.grd | grep x_inc | awk '{print $7}')
      cd SLC
      echo " range decimation is:  " $rng
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

if [ $stage -le 4 ]; then
  #
  # clean up
  #
  cleanup.bash intf
  #
  # make and filter interferograms
  #
  echo " "
  echo "INTF.bash, FILTER.bash - START"
  cd intf/
  ref_id=$(grep SC_clock_start ../raw/$master.PRM | awk '{printf("%d",int($3))}')
  rep_id=$(grep SC_clock_start ../raw/$aligned.PRM | awk '{printf("%d",int($3))}')
  mkdir $ref_id"_"$rep_id
  cd $ref_id"_"$rep_id
  ln -s ../../raw/$ref.LED .
  ln -s ../../raw/$rep.LED .
  ln -s ../../SLC/$ref.SLC .
  ln -s ../../SLC/$rep.SLC .
  cp ../../SLC/$ref.PRM .
  cp ../../SLC/$rep.PRM .

  if [ $topo_phase == 1 ]; then
    if [ $shift_topo == 1 ]; then
      ln -s ../../topo/topo_shift.grd .
      intf.bash $ref.PRM $rep.PRM -topo topo_shift.grd
      filter.bash $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec
    else
      ln -s ../../topo/topo_ra.grd .
      intf.bash $ref.PRM $rep.PRM -topo topo_ra.grd
      filter.bash $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec
    fi
  else
    intf.bash $ref.PRM $rep.PRM
    filter.bash $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec
  fi
  cd ../..
  echo "INTF.bash, FILTER.bash - END"
fi

################################
# 5 - start from unwrap phase  #
################################

if [ $stage -le 5 ]; then
  if [ $threshold_snaphu != 0 ]; then
    cd intf
    ref_id=$(grep SC_clock_start ../SLC/$master.PRM | awk '{printf("%d",int($3))}')
    rep_id=$(grep SC_clock_start ../SLC/$aligned.PRM | awk '{printf("%d",int($3))}')
    cd $ref_id"_"$rep_id
    if [ -z $region_cut ]; then
      region_cut=$(gmt grdinfo phase.grd -I- | cut -c3-20)
    fi

    #
    # landmask
    #
    if [ $mask_water == 1 -o $switch_land == 1 ]; then
      cd ../../topo
      if [ ! -f landmask_ra.grd ]; then
        landmask.bash $region_cut
      fi
      cd ../intf
      cd $ref_id"_"$rep_id
      ln -s ../../topo/landmask_ra.grd .
    fi

    echo " "
    echo "SNAPHU.bash - START"
    echo "threshold_snaphu: $threshold_snaphu"
    if [ $near_interp == 1 ]; then
      snaphu_interp.bash $threshold_snaphu $defomax $region_cut
    else
      snaphu.bash $threshold_snaphu $defomax $region_cut
    fi

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

if [ $stage -le 6 ]; then
  if [ $threshold_geocode != 0 ]; then
    cd intf
    ref_id=$(grep SC_clock_start ../SLC/$master.PRM | awk '{printf("%d",int($3))}')
    rep_id=$(grep SC_clock_start ../SLC/$aligned.PRM | awk '{printf("%d",int($3))}')
    cd $ref_id"_"$rep_id
    echo " "
    echo "GEOCODE.bash - START"
    rm raln.grd ralt.grd
    if [ $topo_phase == 1 ]; then
      rm trans.dat
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

# end
