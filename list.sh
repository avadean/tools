#!/bin/bash

num=13

function printDirCount {
    printf "%-${num}s     %s     %s\n" "${1:0:${num}}" "$2" ;
}

function getDirCount {
    echo $(\ls -l "$1" | \grep --count "^d") ;
}

function getFileCount {
    echo $(\ls "$1" | wc --lines) ;
}

#dir="DIR"
#items="ITEMS"
#spaces=$(( ($num - ${#dir}) / 2 ))
#HEADER=$(printf "%-${spaces}s%-${spaces}s" "$dir" "$items")
HEADER="     DIR         ITEMS"


if [[ $1 == "all" ]] ; then
    (( $(getDirCount ".") == 0 )) && { echo "No directories to list." ; exit 1 ; } ;

    arr=( */ ) ;
else
    arr=( $@ ) ;
fi


if (( ${#arr[@]} == 0 )) ; then
    (( $(getDirCount ".") == 0 )) && { echo "No directories to list." ; exit 1 ; } ;

    echo "$HEADER" ;

    for i in */ ; do
        printDirCount "$i" "$(getFileCount "$i")" ;
    done
else
    origDir=$(pwd) ;

    # Check if there are any non-empty directories first.
    for dir in "${arr[@]}" ; do
        [ -d "$dir" ] || continue ;

        # If there are some non-empty directories then have a header.
        (( $(getDirCount "$dir") != 0 )) && { printf "  " ; echo "$HEADER" ; break ; } ;
    done

    # Now the main loop to output the results.
    for dir in "${arr[@]}" ; do
        [ -d "$dir" ] || { echo "Skipping $dir as not a directory." ; continue ; } ;

        echo "${dir}:" ;

        (( $(getDirCount "$dir") == 0 )) && { echo "  No directories to list." ; continue ; } ;

        cd "$dir" ;

        for i in */ ; do
            printf "  " ;
            printDirCount "$i" "$(getFileCount "$i")" ;
        done

        cd "$origDir" ;
    done
fi

