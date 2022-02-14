# Git diff a castep file in castep-adean repository.

castep_adean="/home/dean/work/castep-adean/"
fundamental="${castep_adean}Source/Fundamental/"
functional="${castep_adean}Source/Functional/"
utility="${castep_adean}Source/Utility/"

cd "$castep_adean" ;

[ -z "${1}" ] && { \git diff --word-diff=color ; exit 0 ; } ;

options=( "${fundamental}${1}.f90"  "${functional}${1}.f90"  "${utility}${1}.f90"
          "${fundamental}${1}.F90"  "${functional}${1}.F90"  "${utility}${1}.F90" ) ;

for file in "${options[@]}" ; do
    [ -f "${file}" ] && { \git diff --word-diff=color "${file}" ; exit 0 ; } ;
done

echo "Cannot find file relating to ${1}" ;
exit 1 ;

