#!/bin/bash
#
alias rm='rm -f'
#
if [ $# -lt 1 ]; then
  echo " "
  echo "Usage: cleanup.bash directory "
  echo " "
  echo " directory could be: raw, SLC, topo, intf, or all "
  echo " "
  echo "Example: cleanup.bash all"
  echo " "
  exit 1
fi
#
#
if [ $1 == all ]; then
  echo ""
  echo "clean up all"
  rm -rf SLC
  rm -rf intf
  rm -f raw/*.PRM*
  rm -f raw/*.raw
  rm -f raw/*.LED
  rm -f raw/*.SLC
  cd topo
  ls | grep -v dem.grd | xargs rm -f
  cd ..
  echo ""
fi
if [ $1 == raw ]; then
  echo ""
  echo "clean up raw/ folder"
  rm -f raw/*.PRM*
  rm -f raw/*.raw
  rm -f raw/*.LED
  echo ""
fi
if [ $1 == SLC ]; then
  echo ""
  echo "clean up SLC/ folder"
  rm -rf SLC/*
  echo ""
fi
if [ $1 == intf ]; then
  echo ""
  echo "clean up intf/ folder"
  rm -rf intf/*
  echo ""
fi
if [ $1 == topo ]; then
  echo ""
  echo "clean up topo/ folder"
  cd topo
  ls | grep -v dem.grd | xargs rm -f
  cd ..
  echo ""
fi
