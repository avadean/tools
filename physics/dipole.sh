#!/bin/bash

arr_1=() ;
arr_2=() ;

for i in * ; do
	if [[ "$i" == *"-out.cell" ]] ; then
		arr_1+=( "$i" )
	fi
	if [[ "$i" == *".castep" ]] ; then
                arr_2+=( "$i" )
        fi
done

if [ ${#arr_1[@]} != 1 ] || [ ${#arr_2[@]} != 1 ] ; then
	echo "Problem with input files."
else
	/home/dean/tools/dipole.py "${arr_1[0]}" "${arr_2[0]}" ;
fi

