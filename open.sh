
[ $# == 0 ] && { echo 'No file(s) to open.' ; exit 2 ; } ;

err=false

for file in "$@" ; do
    if [ -f "$file" ] ; then
        xdg-open "$file" > /dev/null 2>&1 &
        disown ;
    else
        echo "$file not an acceptable file." ;
        err=true
    fi
done

$err && exit 1 || exit 0 ;

