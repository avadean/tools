
alias_file="/home/dean/.bash_aliases" ;
queue_file="/home/dean/tools/files/castep_queue.txt" ;

[ ! -f "$alias_file" ] && echo CASCHECK cannot find alias file && exit ;
[ ! -f "$queue_file" ] && echo CASCHECK cannot find queue file && exit ;


for arg in "$@" ; do
  shift
  case "$arg" in
    "--help"   ) set -- "$@" "-h"   ;;
    "--no-run" ) set -- "$@" "-n"   ;;
    "--quiet"  ) set -- "$@" "-q"   ;;
    *          ) set -- "$@" "$arg" ;;
  esac
done


print_help=false ;
no_run=false ;
quiet=false ;
while getopts ":hnq" opt ; do
  case ${opt} in
    h ) # Print help and exit.
      print_help=true ;
    ;;
    n ) # Don't run any available CASTEP calculations.
      no_run=true ;
    ;;
    q ) # Check to submit calculations quietly.
      quiet=true ;
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
  echo 'Usage: cascheck OPTION... [KEYWORD]...' ;
  echo ;
  echo 'Check queued and running CASTEP calculations.' ;
  echo ;
  echo '-h, --help     prints this help and exits' ;
  echo '-n, --no-run   does not run any queued CASTEP calculations' ;
  exit 0 ;
fi


IDs=( `\pgrep castep` ) ;
num_running=${#IDs[@]} ;
num_queued=`cat "$queue_file" | wc -l` ;


if ! $no_run ; then
  if [ $num_queued -gt 0 ] ; then
    if [ $num_running -lt 3 ] ; then # Criteria for starting jobs whilst some are running.
      data=( `head -1 "$queue_file"` ) ;

      prefix=${data[0]} ;
      direct=${data[1]} ;

      cd "$direct" ;
      . "$alias_file" ;
      #mpirun castep.mpi "$prefix" & #2>/dev/null
      castep.mpi "$prefix" & #2>/dev/null

      sed -i '1d' "$queue_file" ;

      echo " $prefix run started in $direct"

      num_queued=$[$num_queued-1]
      num_running=$[$num_running+1]

      IDs=( `\pgrep castep` ) ;
    fi
  fi
fi


if ! $quiet ; then
  if [ $num_running -gt 0 ] || [ $num_queued -gt 0 ] ; then
    echo ;
    echo "Summary      ->" ;
    echo " $num_queued jobs queued." ;
    echo " $num_running running." ;
  else
    exit 0 ;
  fi


  [ $num_running -gt 0 ] && echo && echo "Running jobs ->"
  for ID in "${IDs[@]}" ; do
    direc=`pwdx "$ID"` ;
    cmmnd=`ps "$ID" | \grep --only-matching --color=always --extended-regexp "castep(\.mpi|\.serial)? +\w+$"` ;
    echo " $direc $cmmnd" ;
  done


  [ $num_queued -gt 0 ] && echo && echo "Queued  jobs ->" ;
  while read line ; do
    direct=${line[0]} ;
    prefix=${line[1]} ;
    echo -e "\e[0;32m${prefix}\e[0m $direct" ;
  done < "$queue_file"


  ( [ $num_running -gt 0 ] || [ $num_queued -gt 0 ] ) && echo ;
fi


#output=`ps -auxwwwf | \grep "castep" | \grep --invert-match "grep"` ;


#[ "$output" ] && echo 'USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND' && echo "$output" | \grep --color=auto --extended-regexp "castep(\.mpi|\.serial)? +\w+$" ;
