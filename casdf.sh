# Git diff a castep file in castep-adean repository.

castep_adean="/home/dean/work/castep-adean/"
fundamental="${castep_adean}Source/Fundamental/"
functional="${castep_adean}Source/Functional/"
utility="${castep_adean}Source/Utility/"

function test_file {
    #[ `\find ${1} -name ${2} | \wc --lines` -gt "0" ] ;

    options=( "${fundamental}${1}.f90"  "${functional}${1}.f90"  "${utility}${1}.f90"
              "${fundamental}${1}.F90"  "${functional}${1}.F90"  "${utility}${1}.F90" ) ;

    for option in ${options} ; do
        [ -f "${option}" ] && { \echo "${option}" ; exit 0 ; } ;
    done

    echo "ERROR" ;
} ;

cd $castep_adean ;

[ -z "${1}" ] && { \git diff --word-diff=color ; exit 0 ; } ;

file=$(test_file "${1}") ;

[ "${file}" == "ERROR" ] && { \echo "Cannot find file relating to ${1}" ; exit 2 ; } ;

\git diff --word-diff=color "${file}"

