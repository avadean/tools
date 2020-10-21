
IDs=( `\pgrep castep` ) ;

#[ ${#IDs[@]} -gt 0 ] && echo 'some header i could add'

for ID in "${IDs[@]}" ; do
  direc=`pwdx "$ID"` ;
  cmmnd=`ps "$ID" | \grep --only-matching --color=always --extended-regexp "castep(\.mpi|\.serial)? +\w+$"` ;
  echo "$direc $cmmnd" ;
done


#output=`ps -auxwwwf | \grep "castep" | \grep --invert-match "grep"` ;

#[ "$output" ] && echo 'USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND' && echo "$output" | \grep --color=auto --extended-regexp "castep(\.mpi|\.serial)? +\w+$" ;
