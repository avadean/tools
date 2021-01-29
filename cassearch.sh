#!/bin/bash

for arg in "$@" ; do
  shift
  case "$arg" in
    "--help"      ) set -- "$@" "-h"   ;;
    "--subroutine") set -- "$@" "-s"   ;;
    "--function"  ) set -- "$@" "-f"   ;;
    "--interface" ) set -- "$@" "-i"   ;;
    "--no-locate" ) set -- "$@" "-L"   ;;
    *             ) set -- "$@" "$arg" ;;
  esac
done

print_help=false ;
subroutine_search=true ;
function_search=true ;
interface_search=true ;
no_locate=false ;
while getopts ":hgsfL" opt ; do
  case ${opt} in
    h ) # Print help and exit.
      print_help=true ;
    ;;
    g ) # Just grep.
      subroutine_search=false ;
      function_search=false ;
      interface_search=false ;
    ;;
    s ) # Subroutine only search.
      function_search=false ;
      interface_search=false ;
    ;;
    f ) # Function only search.
      subroutine_search=false ;
      interface_search=false
    ;;
    i ) # Interface only search.
      subroutine_search=false ;
      function_search=false ;
    ;;
    L ) # Do not locate.
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
    echo '-f, --function       searches and locates functions only'
    echo '-s, --subroutine     searches and locates subroutines only' ;
    echo '-i, --interface      searches and locates interfaces only'
    echo '-g, --grep           just greps the files' ;
    echo '-h, --help           prints this help and exits' ;
    echo '-L, --no-locate      will not vim into subroutine if found' ;
    exit 0 ;
fi



if $subroutine_search ; then
    if $no_locate ; then
        for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "subroutine\s+${1}\s*\(" "$i" ; done ;
    else
        temp_file=`mktemp` ;

        for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp "subroutine\s+${1}\s*\(" "$i" ; done >> $temp_file ;

        num_lines_sub=`cat $temp_file | wc -l` ;
        if [[ $num_lines_sub == 1 ]] ; then
            file_to_open=`cat $temp_file | head -1 | cut -f1 -d:` ;
            line_num=`cat $temp_file | head -1 | cut -f2 -d:` ;
            vim +$line_num $file_to_open ;

            exit 0 ;
        else
            for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "subroutine\s+${1}\s*\(" "$i" ; done ;
        fi
    fi
fi



if $function_search ; then
    if $no_locate ; then
         for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "function\s+${1}\s*\(" "$i" ; done ;
     else
         temp_file=`mktemp` ;

         for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp "function\s+${1}\s*\(" "$i" ; done >> $temp_file ;

         num_lines_func=`cat $temp_file | wc -l` ;
         if [[ $num_lines_func == 1 ]] ; then
             file_to_open=`cat $temp_file | head -1 | cut -f1 -d:` ;
             line_num=`cat $temp_file | head -1 | cut -f2 -d:` ;
             vim +$line_num $file_to_open ;

             exit 0 ;
         else
             for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "function\s+${1}\s*\(" "$i" ; done ;
         fi
     fi
fi



if $interface_search ; then
    if $no_locate ; then
        for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "interface\s+${1}\b" "$i" ; done ;
    else
        temp_file=`mktemp` ;

        for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp "interface\s+${1}\b" "$i" ; done >> $temp_file ;

        num_lines_inter=`cat $temp_file | wc -l` ;
        if [[ $num_lines_inter == 1 ]] ; then
            file_to_open=`cat $temp_file | head -1 | cut -f1 -d:` ;
            line_num=`cat $temp_file | head -1 | cut -f2 -d:` ;
            vim +$line_num $file_to_open ;

            exit 0 ;
        else
            for i in * ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "interface\s+${1}\b" "$i" ; done ;
        fi
    fi
fi



if ( ! $subroutine_search && ! $function_search && ! $interface_search ) || [[ $((num_lines_sub+num_lines_func+num_lines_inter)) == 0 ]] ; then
    for i in * ; do [ -f "$i" ] && \grep --line-number --with-filename --color=auto "${1}" "${i}" ; done
fi



exit 0 ;

