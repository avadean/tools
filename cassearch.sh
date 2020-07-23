#!/bin/bash

for arg in "$@" ; do
  shift
  case "$arg" in
    "--help"      ) set -- "$@" "-h"   ;;
    "--subroutine") set -- "$@" "-s"   ;;
    "--call"      ) set -- "$@" "-c"   ;;
    "--no-locate" ) set -- "$@" "-L"   ;;
    *             ) set -- "$@" "$arg" ;;
  esac
done

print_help=false ;
subroutine_search=false ;
call_search=false ;
no_locate=false ;
while getopts ":hscL" opt ; do
  case ${opt} in
    h ) # Print help and exit.
      print_help=true ;
    ;;
    s ) # Subroutine search.
      subroutine_search=true ;
    ;;
    c ) # Call search.
      call_search=true ;
    ;;
    L ) # Do not locate subroutine.
      no_locate=true ;
    ;;
    \? )
      echo "Invalid option [$OPTARG]." ;
    ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" ;
    ;;
  esac
done

[ $OPTIND != 1 ] && shift $((OPTIND-1)) ;

if $print_help ; then
    echo 'Usage: cassearch OPTION... [KEYWORD]...' ;
    echo ;
    echo 'Search for keywords in the files in the current directory.' ;
    echo 'Options optimised best for use in the CASTEP source code.' ;
    echo ;
    echo '-c, --call           searches files for calls of the keyword' ;
    echo '-h, --help           prints this help and exits' ;
    echo '-L, --no-locate      will not vim into subroutine if found, redundant without --subroutine' ;
    echo '-s, --subroutine     searches files for subroutine and locates using vim' ;
    exit 0 ;
fi


if $subroutine_search ; then
    temp_file=`mktemp` ;
    for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp "subroutine\s+${1}\s*\(" "$i" ; done >> $temp_file ;

    num_lines=`cat $temp_file | wc -l` ;
    if [[ $num_lines == 1 ]] ; then
        file_to_open=`cat $temp_file | head -1 | cut -f1 -d:` ;
        line_num=`cat $temp_file | head -1 | cut -f2 -d:` ;
        [ $no_locate ] || vim +$line_num $file_to_open ;

        exit 0 ;
    else
        for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "subroutine\s+${1}\s*\(" "$i" ; done ;
    fi
else
    for i in * ; do [ -f "$i" ] && \grep --line-number --with-filename --color=auto "${1}" "${i}" ; done
fi

exit 0 ;
