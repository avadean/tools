#!/bin/bash

[ "$1" == "subroutine_search" ] && sub="subroutine " && shift ;

for i in * ; do
    [ -f "$i" ] && \grep -nH --color=auto "$sub$1" "$i" ;
done

exit 0 ;
