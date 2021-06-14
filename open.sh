
[ $# == 0 ] && echo 'No file(s) to open.' && exit 1 ;

for file in "$@" ; do
    if [ -f "$file" ] ; then
        xdg-open "$file" > /dev/null 2>&1 &
        disown ;
    else
        echo "$file not an acceptable file." ;
    fi
done

