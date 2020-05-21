#!/bin/bash

check=$(ls -l . | grep -c ^d)

if [ $check == 0 ]
	then
		echo "No directories to list."
	else
		echo "DIR     ITEMS"

		for i in */ ; do
			cd $i ;
			count=$(ls | wc -l) ;
			echo "${i:0:3}     $count" ;
			cd ../
		done
fi


