#!/bin/bash

if [ "$2" = "" ]
	then
		echo "No language type specified."
	else
		if [ -e $1 ]
			then
				echo "This file already exists."
			else
				case "$2" in

					"p")
						cat ~/tools/files/script_template_python.txt > "$1" ;;

					"b")
						cat ~/tools/files/script_template_bash.txt > "$1" ;;

					"n")
						cat ~/tools/files/script_template_numpy.txt > "$1" ;;

					*)
						echo "Language specified does not exist." ;
						exit ;;
				esac

				chmod +x "$1" ;
		fi
fi


