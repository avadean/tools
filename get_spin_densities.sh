#!/bin/bash

file_output="S.txt"

if [ -z "$1" ] || [ -z "$2" ] ; then
  echo 'Please supply a prefix or suffix for directories. Variable 1 is the pre/suffix and variable 2 is "p" for prefix and "s" for suffix... Stopping.' ;
else
  if [ -f "$file_output" ] ; then
    echo "$file_output output already exists... Stopping." ;
  else
    count=$[0] ;
    if [ "$2" == "p" ] ; then
      for i in "$1"*/ ; do
        if [ -d "$i" ] ; then
          cd $i ;
          if [ -f *".castep" ] ; then
            grep "Integrated |Spin Density|" *.castep | cut -d "=" -f2 >> ../$file_output ;
          fi
          cd ../ ;
          count=$[$[$count] + 1] ;
        fi
      done
    elif [ "$2" == "s" ] ; then
      for i in *"$1"/ ; do
        if [ -d "$i" ] ; then
          cd $i ;
          if [ -f *".castep" ] ; then
            grep "Integrated |Spin Density|" *.castep | cut -d "=" -f2 >> ../$file_output ;
          fi
	  cd ../ ;
	  count=$[$[$count] + 1] ;
	fi
      done
    else
      echo "Only enter p or s for prefix or suffix... Stopping." ;
      exit ;
    fi
    sed -i -e "s|hbar/2||g" $file_output ;
    echo "$count spin densities collected in $file_output."
  fi
fi

