#!/bin/bash


echo "#"
echo "# This is an example configuration file for p2p_processing.bash"
echo "#"
echo "# all the comments or explanations are marked by "\""#"\" 
echo "# The parameters in this configuration file is distinguished by their first word so "
echo "# user should follow the naming of each parameter."
echo "# the parameter name, "\""="\"" sign, parameter value should be separated by space "\"" "\"". "
echo "# leave the parameter value blank if using default value. "
echo "# "
echo "# DO NOT DIRECTLY COMMENT PARAMTERS WITH "\""#"\"" \!\!\!"
echo "# THIS WILL DUPLICATE PARAMETERS AND CAUSE TROUBLE \!\!\!"
echo "# "
echo "  "
echo "#####################"
echo "# processing stage  #"
echo "#####################"
echo "# 1 - start from preprocess"
echo "# 2 - start from align SLC images"
echo "# 3 - start from make topo_ra "
echo "# 4 - start from make and filter interferograms "
echo "# 5 - start from unwrap phase"
echo "# 6 - start from geocode  "
echo "proc_stage = 1"
echo "skip_stage = "
echo ""
echo "##################################"
echo "#   parameters for preprocess    #"
echo "#   - pre_proc.bash               #"
echo "##################################"
echo "# num of patches"
echo "num_patches = "
echo ""
echo "# earth radius "
echo "earth_radius ="
echo ""
echo "# near_range"
echo "near_range = "
echo ""
echo "# Doppler centroid "
echo "fd1 = "
echo ""
echo "# apply spectral diversity to remove burst discontinuity"
echo "spec_div = 0"
echo "# spectral diversity mode, run align_tops_esd.bash to figure out the mode specification"
echo "spec_mode = 1"
echo ""



echo "################################################"
echo "#   parameters for focus and align SLC images  #"
echo "#   - align.bash                                #"
echo "################################################"
echo "# region to cut in radar coordinates (leave it blank if process the whole image)"
echo "# example 300/5900/0/25000"
echo "region_cut ="
echo ""
echo "#"
echo "#####################################"
echo "#   parameters for make topo_ra     #"
echo "#   - dem2topo_ra.bash               #"
echo "#####################################"
echo "# subtract topo_ra from the phase"
echo "#  (1 -- yes; 0 -- no)"
echo "topo_phase = 1"
echo "# if above parameter = 1 then one should have put dem.grd in topo/"
echo ""
echo "# topo_ra shift (1 -- yes; 0 -- no)"

echo ""
echo "####################################################"
echo "#   parameters for make and filter interferograms  #"
echo "#   - intf.bash                                     #"
echo "#   - filter.bash                                   #"
echo "####################################################"
echo "# switch the master and aligned when doing intf. "
echo "# put "\""1"\"" if assume master as repeat and aligned as reference "
echo "# put "\""0"\"" if assume master as reference and aligned as repeat [Default]"
echo "# phase = repeat phase - reference phase"
echo "switch_master = 0"
echo ""
echo "# filters "
echo "# look at the filter/ folder to choose other filters"
echo "# for tops processing, to force the decimation factor"
echo "# recommended range decimation to be 8, azimuth decimation to be 2"

echo "filter_wavelength = 200"

echo ""
echo "# decimation of images "
echo "# decimation control the size of the amplitude and phase images. It is either 1 or 2."
echo "# Set the decimation to be 1 if you want higher resolution images."
echo "# Set the decimation to be 2 if you want images with smaller file size."
echo "# "

echo "range_dec = 8"
echo "azimuth_dec = 2"

echo "#"
echo "# compute phase gradient, make decimation to 1 above and filter wavelength small for better quality"
echo "#"
echo "compute_phase_gradient = 0"
echo "#"
echo "# make ionospheric phase corrections using split spectrum method"
echo "correct_iono = 0"
echo "iono_filt_rng = 1.0"
echo "iono_filt_azi = 1.0"
echo "iono_dsamp = 1"
echo "# "
echo "# set the following parameter to skip ionospheric phase estimation"
echo "iono_skip_est = 1 "
echo "#"
echo "#####################################"
echo "#   parameters for unwrap phase     #"
echo "#   - snaphu.bash                    #"
echo "#####################################"
echo "# correlation threshold for snaphu.bash (0~1)"
echo "# set it to be 0 to skip unwrapping."
echo "threshold_snaphu = 0"
echo ""
echo "# interpolate masked or low coherence pixels with their nearest neighbors, 1 means interpolate, "
echo "# others or blank means using original phase, see snaphu.bash and snaphu_interp.bash for details"
echo "# this could be very slow in case a large blank area exist"
echo "near_interp = 0"
echo ""
echo "# mask the wet region (Lakes/Oceans) before unwrapping (1 -- yes; else -- no)"
echo "mask_water = 1"
echo ""
echo "#"
echo "# Allow phase discontinuity in unrapped phase. This is needed for interferograms having sharp phase jumps."
echo "# defo_max = 0 - used for smooth unwrapped phase such as interseismic deformation"
echo "# defo_max = 65 - will allow a phase jump of 65 cycles or 1.82 m of deformation at C-band"
echo "#"
echo "defomax = 0"
echo ""
echo "#####################################"
echo "#   parameters for geocode          #"
echo "#   - geocode.bash                   #"
echo "#####################################"
echo "# correlation threshold for geocode.bash (0< threshold <=1), set 0 to skip"
echo "threshold_geocode = .10"
echo ""