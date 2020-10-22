alias_file="/home/dean/.bash_aliases"
queue_file="/home/dean/tools/files/castep_queue.txt" ;

if [ `cat "$queue_file" | wc -l` -gt 0 ] ; then
  data=( `head -1 "$queue_file"` ) ;

  prefix=${data[0]} ;
  direct=${data[1]} ;

  cd "$direct" ;
  . "$alias_file" ;
  castep.mpi "$prefix" &

  sed -i '1d' "$queue_file" ;
fi
