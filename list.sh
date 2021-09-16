#!/bin/bash

check=$(\ls -l . | \grep --count "^d")

[ $check == 0 ] && { echo No directories to list && exit 1 ; } ;

echo "DIR     ITEMS     SIZE"

for i in */ ; do
  count=$(\ls "$i" | wc -l) ;
  #size=$(du -hs)
  echo "${i:0:3}     $count         $size" ;
done

