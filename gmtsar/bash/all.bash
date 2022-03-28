#!/bin/bash
#
# process Sentinel-1A TOPS data
# read three consectutive scenes spanning the same time interval
# make two inteferograms and then double difference them
# to see grounding lines in polar regions, for example the Ross Ice Shelf
# results of two interferograms are under directories merge1 and merge2 respectively
# double difference results (phase_diff.grd) are in the doublediff folder

alias rm='rm -f'
#
if [ $# -ne 7 ]; then
  echo ""
  echo "Usage: all.bash Master.SAFE Master.EOF Aligned.SAFE Aligned.EOF config.s1a.txt polarization parallel"
  echo ""
  echo "Example: all.bash S1A_IW_SLC__1SDV_20150607T014936_20150607T015003_006261_00832E_3626.SAFE S1A_OPER_AUX_POEORB_OPOD_20150615T155109_V20150525T225944_20150527T005944.EOF S1A_IW_SLC__1SSV_20150526T014935_20150526T015002_006086_007E23_679A.SAFE S1A_OPER_AUX_POEORB_OPOD_20150627T155155_V20150606T225944_20150608T005944.EOF config.s1a.txt vv 1"
  echo ""
  echo "    Place the .SAFE file in the raw folder, DEM in the topo folder"
  echo "    During processing, F1, F2, F3 and merge folder will be generated"
  echo "    Final results will be placed in the merge folder, with phase"
  echo "    corr [unwrapped phase]."
  echo "    polarization=vv vh hh or hv "
  echo "    parallel=0-sequential  1-parallel "
  echo ""
  exit 1
fi
# start
#
# set polarization
pol=$6
echo $pol
#
# set processing mode seq
#
seq=$7
echo $seq
#:<<supercalifragilisticexpialidocious
#
# determine file names
#
pth=$(pwd)
cd raw/$1
f1s1=$(ls */*iw1*$pol*xml | awk '{print substr($1,12,length($1)-15)}')
f2s1=$(ls */*iw2*$pol*xml | awk '{print substr($1,12,length($1)-15)}')
f3s1=$(ls */*iw3*$pol*xml | awk '{print substr($1,12,length($1)-15)}')
cd ../$3
f1s2=$(ls */*iw1*$pol*xml | awk '{print substr($1,12,length($1)-15)}')
f2s2=$(ls */*iw2*$pol*xml | awk '{print substr($1,12,length($1)-15)}')
f3s2=$(ls */*iw3*$pol*xml | awk '{print substr($1,12,length($1)-15)}')
cd $pth

#
# organize files
#
mkdir F1
mkdir F1/raw F1/topo
cd F1
sed "s/.*threshold_geocode.*/threshold_geocode = 0/g" ../$5 | sed "s/.*threshold_snaphu.*/threshold_snaphu = 0/g" >$5
cd topo
ln -s ../../topo/dem.grd .

cd ../raw
ln -s ../topo/dem.grd .
ln -s ../../raw/$1/*/$f1s1.xml .
ln -s ../../raw/$1/*/$f1s1.tiff .
ln -s ../../raw/$2 .
ln -s ../../raw/$3/*/$f1s2.xml .
ln -s ../../raw/$3/*/$f1s2.tiff .
ln -s ../../raw/$4 .
cd ../..

mkdir F2
mkdir F2/raw F2/topo
cd F2
sed "s/.*threshold_geocode.*/threshold_geocode = 0/g" ../$5 | sed "s/.*threshold_snaphu.*/threshold_snaphu = 0/g" >$5
cd topo
ln -s ../../topo/dem.grd .
cd ../raw
ln -s ../topo/dem.grd .
ln -s ../../raw/$1/*/$f2s1.xml .
ln -s ../../raw/$1/*/$f2s1.tiff .
ln -s ../../raw/$2 .
ln -s ../../raw/$3/*/$f2s2.xml .
ln -s ../../raw/$3/*/$f2s2.tiff .
ln -s ../../raw/$4 .
cd ../..

mkdir F3
mkdir F3/raw F3/topo
cd F3
sed "s/.*threshold_geocode.*/threshold_geocode = 0/g" ../$5 | sed "s/.*threshold_snaphu.*/threshold_snaphu = 0/g" >$5
cd topo
ln -s ../../topo/dem.grd .
cd ../raw
ln -s ../topo/dem.grd .
ln -s ../../raw/$1/*/$f3s1.xml .
ln -s ../../raw/$1/*/$f3s1.tiff .
ln -s ../../raw/$2 .
ln -s ../../raw/$3/*/$f3s2.xml .
ln -s ../../raw/$3/*/$f3s2.tiff .
ln -s ../../raw/$4 .
cd ../..

#
# process data
#
if [ $seq -eq 0 ]; then
    cd F1/raw
    align_tops.bash $f1s1 $2 $f1s2 $4 dem.grd
    s1pre1=$(echo $f1s1 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    s2pre1=$(echo $f1s2 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    cd ../../F2/raw
    align_tops.bash $f2s1 $2 $f2s2 $4 dem.grd
    s1pre2=$(echo $f2s1 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    s2pre2=$(echo $f2s2 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    cd ../../F3/raw
    align_tops.bash $f3s1 $2 $f3s2 $4 dem.grd
    s1pre3=$(echo $f3s1 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    s2pre3=$(echo $f3s2 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    cd ../../F1
    p2p_S1_TOPS.bash $s1pre1 $s2pre1 $5
    cd ../F2
    p2p_S1_TOPS.bash $s1pre2 $s2pre3 $5
    cd ../F3
    p2p_S1_TOPS.bash $s1pre3 $s2pre3 $5
    cd ..

elif [ $seq -eq 1 ]; then
    cd F1/raw
    align_tops.bash $f1s1 $2 $f1s2 $4 dem.grd >&log &
    s1pre1=$(echo $f1s1 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    s2pre1=$(echo $f1s2 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')

    cd ../../F2/raw
    align_tops.bash $f2s1 $2 $f2s2 $4 dem.grd >&log &
    s1pre2=$(echo $f2s1 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    s2pre2=$(echo $f2s2 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')

    cd ../../F3/raw
    align_tops.bash $f3s1 $2 $f3s2 $4 dem.grd >&log &
    s1pre3=$(echo $f3s1 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')
    s2pre3=$(echo $f3s2 | awk '{ print "S1_"substr($1,16,8)"_"substr($1,25,6)"_F"substr($1,7,1)}')

    wait
    cd ../../F1
    p2p_S1_TOPS.bash $s1pre1 $s2pre1 $5 >&log &
    cd ../F2
    p2p_S1_TOPS.bash $s1pre2 $s2pre2 $5 >&log &
    cd ../F3
    p2p_S1_TOPS.bash $s1pre3 $s2pre3 $5 >&log &
    cd ..
    wait
else

    echo "Invalid mode"
    exit
fi

#supercalifragilisticexpialidocious
#
# merge_unwrap_geocode
#

mkdir merge
cd merge
ln -s ../$5 .
ln -s ../topo/dem.grd .
ln -s ../F1/intf/*/gauss* .
if [ -f tmp.filelist ]; then
    rm tmp.filelist
fi
pth1=$(ls ../F1/intf/*/*PRM | awk NR==1'{print $1}' | awk -F"/" '{for (i=1;i<NF;i++) printf("%s/",$i)}')
prm1s1=$(ls ../F1/intf/*/*PRM | awk NR==1'{print $1}' | awk -F"/" '{print $NF}')
prm1s2=$(ls ../F1/intf/*/*PRM | awk NR==2'{print $1}' | awk -F"/" '{print $NF}')
echo $pth1":"$prm1s1":"$prm1s2 >tmp.filelist

pth2=$(ls ../F2/intf/*/*PRM | awk NR==1'{print $1}' | awk -F"/" '{for (i=1;i<NF;i++) printf("%s/",$i)}')
prm2s1=$(ls ../F2/intf/*/*PRM | awk NR==1'{print $1}' | awk -F"/" '{print $NF}')
prm2s2=$(ls ../F2/intf/*/*PRM | awk NR==2'{print $1}' | awk -F"/" '{print $NF}')
echo $pth2":"$prm2s1":"$prm2s2 >>tmp.filelist

pth3=$(ls ../F3/intf/*/*PRM | awk NR==1'{print $1}' | awk -F"/" '{for (i=1;i<NF;i++) printf("%s/",$i)}')
prm3s1=$(ls ../F3/intf/*/*PRM | awk NR==1'{print $1}' | awk -F"/" '{print $NF}')
prm3s2=$(ls ../F3/intf/*/*PRM | awk NR==2'{print $1}' | awk -F"/" '{print $NF}')
echo $pth3":"$prm3s1":"$prm3s2 >>tmp.filelist

merge_unwrap_geocode_tops.bash tmp.filelist $5
cd ..
