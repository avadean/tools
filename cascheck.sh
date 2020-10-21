output=`ps -aux | \grep "castep" | \grep --invert-match "grep"` ;

[ "$output" ] && echo 'USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND' && echo "$output" | \grep --color=auto --extended-regexp "castep(\.mpi|\.serial)? +\w+$" ;
