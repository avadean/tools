# Git diff a castep file in castep-adean repository.


# Options.
for arg in "$@" ; do
  shift
  case "$arg" in
    "--help") set -- "$@" "-h" ;;
    "--diff") set -- "$@" "-d" ;;
    *       ) set -- "$@" "$arg" ;;
  esac
done


# Define variable defaults before options.
help=false ;
diff=false ;


# Accepts options.
while getopts ":hd" opt ; do
  case ${opt} in
    h ) # help.
      help=true ;
    ;;
    d ) # diff output instead of df.
      diff=true ;
    ;;
    \? )
      echo "Invalid option [$OPTARG]: add "--help" for help." ;
    ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" ;
    ;;
  esac
done


# If no options provided.
[ $OPTIND != 1 ] && shift $((OPTIND-1)) ;


# Help.
if $help ; then
  echo 'Usage: casdf OPTION... [KEYWORD]...' ;
  echo ;
  echo 'Print diff in castep repository for all or single file.' ;
  echo ;
  echo '-h, --help     prints this help and exits' ;
  echo '-d, --diff     uses diff method rather than df' ;

  exit 0 ;
fi


# Define variables for main program.
castep_adean="/home/dean/work/castep-adean/"
fundamental="${castep_adean}Source/Fundamental/"
functional="${castep_adean}Source/Functional/"
utility="${castep_adean}Source/Utility/"


# Go to repository.
cd "$castep_adean" ;


# Word-diff option.
$diff && worddiff="none" || worddiff="color"


# Default to diff all repository if no file specified.
[ -z "${1}" ] && { \git diff --word-diff="${worddiff}" ; exit 0 ; } ;


# Get all possible files.
options=( "${fundamental}${1}.f90"  "${functional}${1}.f90"  "${utility}${1}.f90"
          "${fundamental}${1}.F90"  "${functional}${1}.F90"  "${utility}${1}.F90" ) ;


# Diff specified file.
for file in "${options[@]}" ; do
    [ -f "${file}" ] && { \git diff --word-diff="${worddiff}" "${file}" ; exit 0 ; } ;
done


# Haven't exited yet so must have errored.
echo "Cannot find file relating to ${1}" ;
exit 1 ;

