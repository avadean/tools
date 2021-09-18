#!/bin/bash

num=13

function printDirCount {
    printf "%-${num}s     %s     %s\n" "${1:0:${num}}" "$2" ;
}

#dir="DIR"
#items="ITEMS"
#spaces=$(( ($num - ${#dir}) / 2 ))
#HEADER=$(printf "%-${spaces}s%-${spaces}s" "$dir" "$items")
HEADER="     DIR         ITEMS"


if (( $# == 0 )) ; then
    count=$(\ls -l . | \grep --count "^d") ;

    (( $count == 0 )) && { echo "No directories to list." ; exit 1 ; } ;

    echo "$HEADER" ;

    for i in */ ; do
        count=$(\ls "$i" | wc -l) ;
        printDirCount "$i" "$count" ;
    done
else
    origDir=$(pwd) ;

    # Check if there are any non-empty directories first.
    for dir in "$@" ; do
        [ -d "$dir" ] || continue ;
        count=$(\ls -l "$dir" | \grep --count "^d") ;

        # If there are some non-empty directories then have a header.
        (( $count != 0 )) && { printf "  " ; echo "$HEADER" ; break ; } ;
    done

    # Now the main loop to output the results.
    for dir in "$@" ; do
        [ -d "$dir" ] || { echo "Skipping $dir as not a directory." ; continue ; } ;

        echo "${dir}:" ;

        (( $count == 0 )) && { echo "  No directories to list." ; continue ; } ;

        cd "$dir" ;

        for i in */ ; do
            count=$(\ls "$i" | wc -l) ;
            printf "  " ;
            printDirCount "$i" "$count" ;
        done

        cd "$origDir" ;
    done
fi

