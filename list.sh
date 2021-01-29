#!/bin/bash

check=$(\ls -l . | \grep -c ^d)

if [ $check == 0 ]
	then
		echo "No directories to list."
	else
		echo "DIR     ITEMS     SIZE"

		for i in */ ; do
			cd $i ;
			count=$(\ls | wc -l) ;
            #size=$(du -hs)
			echo "${i:0:3}     $count         $size" ;
			cd ../
		done
fi


