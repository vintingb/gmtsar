#!/bin/bash
#       $Id$
#
#  Xiaopeng Tong FEB 4 2010
#
# Make the interferogram.
#
#  Matt Wei May 4 2010, ENVISAT
#
# add in TSX, Jan 10 2014
alias rm='rm -f'
gmt set IO_NC4_CHUNK_SIZE classic
#
#
if [ $# -lt 2 ]; then
  errormessage:
  echo ""
  echo "Usage: intf.bash ref.PRM rep.PRM [-topo topogrd] [-model modelgrd]"
  echo ""
  echo " The dimensions of topogrd and modelgrd should be compatible with SLC file."
  echo ""
  echo "Example: intf.bash IMG-HH-ALPSRP055750660-H1.0__A.PRM IMG-HH-ALPSRP049040660-H1.0__A.PRM -topo topo_ra.grd"
  echo ""
  exit 1
fi
#
# which satellite
#
SC=$(grep SC_identity $1 | awk '{print $3}')
if [ $SC -eq 1 ] || [ $SC -eq 2 ] || [ $SC -eq 4 ] || [ $SC -eq 6 ] || [ $SC -eq 5 ]; then
  cp $2 $2"0"
  cp $1 $1"0"
  SAT_baseline $1 $2 | tail -n9 >>$2
  SAT_baseline $1 $1 | grep height >>$1
elif [ $SC -gt 6 ]; then
  cp $2 $2"0"
  cp $1 $1"0"
  SAT_baseline $1 $2 | tail -n9 >>$2
  SAT_baseline $1 $1 | grep height >>$1
else
  echo "Incorrect satellite id in prm file"
  exit 0
fi

#
# form the interferogram optionally using topo_ra and modelphase
#
if [ $# -eq 2 ] || [ $# -eq 4 ] || [ $# -eq 6 ]; then
  echo "intf.bash"
  echo "running phasediff..."
  phasediff $*
else
  goto errormessage
fi
mv $1"0" $1
mv $2"0" $2
