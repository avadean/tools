#!/bin/bash

[ -z "$1" ] && echo Please supply phrase to search for. && exit 1 ;

for arg in "$@" ; do
  shift
  case "$arg" in
    "--help"      ) set -- "$@" "-h"   ;;
    "--subroutine") set -- "$@" "-s"   ;;
    "--function"  ) set -- "$@" "-f"   ;;
    "--interface" ) set -- "$@" "-i"   ;;
    "--file"      ) set -- "$@" "-F"   ;;
    "--no-locate" ) set -- "$@" "-L"   ;;
    *             ) set -- "$@" "$arg" ;;
  esac
done

print_help=false ;
subroutine_search=true ;
function_search=true ;
interface_search=true ;
file_search=true ;
no_locate=false ;
while getopts ":hgsfiFL" opt ; do
  case ${opt} in
    h ) # Print help and exit.
      print_help=true ;
    ;;
    g ) # Just grep.
      subroutine_search=false ;
      function_search=false ;
      interface_search=false ;
      file_search=false ;
    ;;
    s ) # Subroutine only search.
      function_search=false ;
      interface_search=false ;
      file_search=false ;
    ;;
    f ) # Function only search.
      subroutine_search=false ;
      interface_search=false ;
      file_search=false ;
    ;;
    i ) # Interface only search.
      subroutine_search=false ;
      function_search=false ;
      file_search=false ;
    ;;
    F ) # File only search.
      subroutine_search=false ;
      function_search=false ;
      interface_search=false ;
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
    echo 'Search for functions, subroutines, interfaces or files.' ;
    echo 'Options best for use in the CASTEP source code.' ;
    echo ;
    echo '-f, --function       searches and locates functions only'
    echo '-s, --subroutine     searches and locates subroutines only' ;
    echo '-i, --interface      searches and locates interfaces only'
    echo '-g, --grep           just greps the files' ;
    echo '-h, --help           prints this help and exits' ;
    echo '-L, --no-locate      will not vim into subroutine if found' ;

    exit 0 ;
fi



function vim_or_cat_file {
    if [[ "$2" == 1 ]] ; then
        file_to_open=`cat "$1" | head -1 | cut -f1 -d:` ;
        line_num=`cat "$1" | head -1 | cut -f2 -d:` ;
        vim +$line_num $file_to_open ;
        exit 0 ;
    else
        cat "$1" ;
    fi
}



func_dir="/home/dean/work/castep-adean/Source/Functional/"
fund_dir="/home/dean/work/castep-adean/Source/Fundamental/"
util_dir="/home/dean/work/castep-adean/Source/Utility/"
castep_file="/home/dean/work/castep-adean/Source/castep.f90"

files=( "$castep_file" `for file in $(ls $func_dir) ; do echo "$func_dir$file" ; done` `for file in $(ls $fund_dir) ; do echo "$fund_dir$file" ; done` `for file in $(ls $util_dir) ; do echo "$util_dir$file" ; done` ) ;



if $subroutine_search ; then
    if $no_locate ; then
        for i in ${files[@]} ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "subroutine\s+${1}\s*\(" "$i" ; done ;
    else
        temp_file=`mktemp` ;

        for i in ${files[@]} ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "subroutine\s+${1}\s*\(" "$i" ; done >> $temp_file ;

        num_lines_sub=`cat $temp_file | wc -l` ;
        vim_or_cat_file "$temp_file" "$num_lines_sub"
    fi
fi



if $function_search ; then
    if $no_locate ; then
         for i in ${files[@]} ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "function\s+${1}\s*\(" "$i" ; done ;
     else
         temp_file=`mktemp` ;

         for i in ${files[@]} ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "function\s+${1}\s*\(" "$i" ; done >> $temp_file ;

         num_lines_func=`cat $temp_file | wc -l` ;
         vim_or_cat_file "$temp_file" "$num_lines_func"
     fi
fi



if $interface_search ; then
    if $no_locate ; then
        for i in ${files[@]} ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "interface\s+${1}\b" "$i" ; done ;
    else
        temp_file=`mktemp` ;

        for i in ${files[@]} ; do [ -f "${i}" ] && \grep --line-number --with-filename --extended-regexp --color=auto "interface\s+${1}\b" "$i" ; done >> $temp_file ;

        num_lines_inter=`cat $temp_file | wc -l` ;
        vim_or_cat_file "$temp_file" "$num_lines_inter"
    fi
fi



if $file_search ; then
    files_found=( ) ;
    num_files_found=$((0))
    for i in ${files[@]} ; do
        if [[ $i == *"${1}"*".f90" ]] || [[ $i == *"${1}"*".F90" ]] ; then
            files_found+=( "$i" )
            num_files_found=$((num_files_found+1))
        fi
    done
    if [[ "$num_files_found" == 1 ]] && ! $no_locate ; then
        vim "${files_found[0]}"
    else
        for file in "${files_found[@]}" ; do
            echo "$file" ;
        done
    fi
fi



if ( ! $subroutine_search && ! $function_search && ! $interface_search && ! $file_search ) || [[ $((num_lines_sub+num_lines_func+num_lines_inter+num_files_found)) == 0 ]] ; then
    for i in ${files[@]} ; do [ -f "$i" ] && \grep --line-number --with-filename --color=auto "${1}" "${i}" ; done
fi



exit 0 ;

