#!/bin/bash

###########################################
###              VARIABLES              ###
###########################################

# General.
alias_to_script="calc"

# Scripts.
script_this_script="/home/dean/tools/calc_manager/main.sh"
script_check_param="/home/dean/tools/calc_manager/check_param.py"
script_check_cell=""
script_sort_param="/home/dean/tools/calc_manager/sort_param.py"
script_sort_cell=""
script_update_param="/home/dean/tools/calc_manager/update_param.py"
script_update_cell=""

# Files.
file_mol_cell_temp="/home/dean/tools/files/cell_template_molecule.txt"
file_mol_param_temp="/home/dean/tools/files/param_template_molecule.txt"
file_cry_cell_temp="/home/dean/tools/files/cell_template_crystal.txt"
file_cry_param_temp="/home/dean/tools/files/param_template_crystal.txt"

# Directories.
dir_backup_cell="/home/dean/tools/calc_manager/backups/cell/"
dir_backup_param="/home/dean/tools/calc_manager/backups/param/"

# Error descriptions.
err_param_exist="Param file already exists... Exiting."
err_cell_exist="Cell file already exists... Exiting."
err_input_exist="Cell and/or param file(s) already exist... Exiting."
err_param_excess="Two or more param files found... Exiting."
err_cell_excess="Two or more cell files found... Exiting."
err_input_excess="Two or more cell and/or param files found... Exiting."
err_param_zero="No param file found... Exiting."
err_cell_zero="No cell file found... Exiting."
err_input_zero="No cell or param file(s) found... Exiting."




###########################################
###              FUNCTIONS              ###
###########################################

function check_param_exist { ( [[ $(ls | grep ".param"$) ]] && true ) || false ; }
function check_cell_exist { ( [[ $(ls | grep ".cell"$ | grep -v "out.cell"$) ]] && true ) || false ; }
function check_input_exist { ( ( check_param_exist || check_cell_exist ) && true ) || false ; }

function check_param_excess { ( [[ $(ls | grep ".param"$ | wc -l) -gt 1 ]] && true ) || false ; }
function check_cell_excess { ( [[ $(ls | grep ".cell"$ | grep -v "out.cell"$ | wc -l) -gt 1 ]] && true ) || false ; }
function check_input_excess { ( ( [[ $(ls | grep ".param"$ | wc -l) -gt 1 ]] || [[ $(ls | grep ".cell"$ | grep -v "out.cell"$ | wc -l) -gt 1 ]] ) && true ) || false ; }

function check_param_zero { ( [[ -z $(ls | grep ".param"$) ]] && true ) || false ; }
function check_cell_zero { ( [[ -z $(ls | grep ".cell"$ | grep -v "out.cell"$) ]] && true ) || false ; }

function get_param_file {
    check_param_excess && exit 1 ;  # Error code of 1 for excess of param files.
    check_param_zero && exit 2 ;    # Error code of 2 for zero param files.
    echo $(ls | grep ".param"$) ;
}

function get_cell_file {
    check_cell_excess && exit 1 ;   # Error code of 1 for excess of cell files.
    check_cell_zero && exit 2 ;     # Error code of 2 for zero cell files.
    echo $(ls | grep ".cell"$ | grep -v "out.cell"$) ;
}




###########################################
###               OPTIONS               ###
###########################################

# Convert long options to short options.
for arg in "$@" ; do
  shift ;
  case "$arg" in
    "--help"    ) set -- "$@" "-h" ;;
    "--no-sort" ) set -- "$@" "-S" ;;
    "--no-check") set __ "$@" "-C" ;;
    "--"*       ) set -- "$@" "-${arg:2:${#arg}}" ;;
    *           ) set -- "$@" "$arg" ;;
  esac
done

# Pre-set variables to defaults before options.
show_help=false
sort_files=true
check_files=true

# Accept options.
while getopts ":hSC" opt ; do
  case ${opt} in
    h ) show_help=true ;;
    S ) sort_files=false ;;
    C ) check_files=false ;;
    \? )
      echo "Invalid option [$OPTARG]: type \"$alias_to_script --help\" for help." ;
      exit 1 ;
    ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" ;
      exit 1 ;
    ;;
  esac
done

# If no options provided.
[ $OPTIND != 1 ] && shift $((OPTIND-1)) ;




###########################################
###                HELP                 ###
###########################################

# Show help if requested.
if $show_help ; then
  echo "Useage:  $alias_to_script -options command" ;
  echo ;
  echo "Accepted -options are:" ;
  echo "  -h    Print this help." ;
  echo "  -S    No auto-sort of param and cell files." ;
  echo "  -C    No auto-check of param and cell files." ;
  echo ;
  echo "Accepted commands are:" ;
  echo "  create" ;
  echo "  update" ;
  echo ;
  echo "Accepted files are:" ;
  echo "  param" ;
  echo "  cell" ;
  exit 0 ;
fi




###########################################
###              MAIN CODE              ###
###########################################

case $1 in
    "check" )
        ( [ "$2" == "cell" ] || [ "$2" == "param" ] || [ -z $2 ] ) || ( echo "Not a valid check option. Use cell or param or leave blank." && exit 1 ) ;
        case $2 in
            "cell" )
                file_cell=$(get_cell_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_cell_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_cell_zero" && exit 1 ;

                #python $script_check_cell $file_cell ;
                ( [ $? == 0 ] && echo "Cell check complete." ) || echo "Cell check failed."
            ;;

            "param" )
                file_param=$(get_param_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_param_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_param_zero" && exit 1 ;

                python $script_check_param $file_param ;
                ( [ $? == 0 ] && echo "Param check complete." ) || echo "Param check failed."
            ;;

            "" )
                file_cell=$(get_cell_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_cell_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_cell_zero" && exit 1 ;

                file_param=$(get_param_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_param_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_param_zero" && exit 1 ;

                #python $script_check_cell $file_cell ;
                ( [ $? == 0 ] && echo "Cell check complete." ) || echo "Cell check failed."

                python $script_check_param $file_param ;
                ( [ $? == 0 ] && echo "Param check complete." ) || echo "Param check failed."
            ;;
        esac
    ;;

    "create" )
        [ -z $2 ] && echo "Please enter a create option. Use molecule (m) or crystal (c)." && exit 1 ;
        case $2 in
            "m"|"molecule" )
                ( ( [ "$3" == "cell" ] || [ "$3" == "param" ] || [ -z $3 ] ) && echo "Please enter a system prefix:" ) || \
                    ( echo "Not a valid molecule option. Use cell or param or leave blank." && exit 1 ) ;
                read system_prefix ;
                case $3 in
                    "cell" )
                        check_cell_exist && echo "$err_cell_exist" && exit 1 ;
                        cat "$file_mol_cell_temp" > $system_prefix.cell ;
                        ( [ $? == 0 ] && echo "Molecule cell created." ) || echo "Failed to create molecule cell." ;
                    ;;

                    "param" )
                        check_param_exist && echo "$err_param_exist" && exit 1 ;
                        cat "$file_mol_param_temp" > $system_prefix.param ;
                        ( [ $? == 0 ] && echo "Molecule param created." ) || echo "Failed to create molecule param." ;
                    ;;

                    "" )
                        check_input_exist && echo "$err_input_exist" && exit 1 ;
                        cat "$file_mol_cell_temp" > $system_prefix.cell ;
                        ( [ $? == 0 ] && echo "Molecule cell created." ) || echo "Failed to create molecule cell." ;
                        cat "$file_mol_param_temp" > $system_prefix.param ;
                        ( [ $? == 0 ] && echo "Molecule param created." ) || echo "Failed to create molecule param."
                    ;;
                esac
            ;;

            "c"|"crystal" )
                ( ( [ "$3" == "cell" ] || [ "$3" == "param" ] || [ -z $3 ] ) && echo "Please enter a system prefix:" ) || \
                    ( echo "Not a valid crystal option. Use cell or param or leave blank." && exit 1 ) ;
                read system_prefix ;
                case $3 in
                    "cell" )
                        check_cell_exist && echo "$err_cell_exist" && exit 1 ;
                        cat "$file_cry_cell_temp" > $system_prefix.cell ;
                        ( [ $? == 0 ] && echo "Crystal cell created." ) || echo "Failed to create crystal cell." ;
                    ;;

                    "param" )
                        check_param_exist && echo "$err_param_exist" && exit 1 ;
                        cat "$file_cry_param_temp" > $system_prefix.param ;
                        ( [ $? == 0 ] && echo "Crystal param created." ) || echo "Failed to create crystal param." ;
                    ;;

                    "" )
                        check_input_exist && echo "$err_input_exist" && exit 1 ;
                        cat "$file_cry_cell_temp" > $system_prefix.cell ;
                        ( [ $? == 0 ] && echo "Crystal cell created." ) || echo "Failed to create crystal cell." ;
                        cat "$file_cry_param_temp" > $system_prefix.param ;
                        ( [ $? == 0 ] && echo "Crystal param created." ) || echo "Failed to create crystal param." ;
                    ;;
                esac
            ;;

            * )
                echo "Not a valid create option. Use molecule (m) or crystal (c)."
            ;;
        esac
    ;;

    "sort" )
        ( [ "$2" == "cell" ] || [ "$2" == "param" ] || [ -z $2 ] ) || ( echo "Not a valid sort option. Use cell or param or leave blank." && exit 1 ) ;
        case $2 in
            "cell" )
                file_cell=$(get_cell_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_cell_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_cell_zero" && exit 1 ;

                #python $script_sort_cell $file_cell ;
                ( [ $? == 0 ] && echo "Cell sort complete." ) || echo "Cell sort failed."

                $check_files && bash $script_this_script check cell ;
            ;;

            "param" )
                file_param=$(get_param_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_param_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_param_zero" && exit 1 ;

                python $script_sort_param $file_param ;
                ( [ $? == 0 ] && echo "Param sort complete." ) || echo "Param sort failed."

                $check_files && bash $script_this_script check param ;
            ;;

            "" )
                file_cell=$(get_cell_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_cell_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_cell_zero" && exit 1 ;

                file_param=$(get_param_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_param_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_param_zero" && exit 1 ;

                #python $script_sort_cell $file_cell ;
                ( [ $? == 0 ] && "Cell sort complete." ) || echo "Cell sort failed."

                python $script_sort_param $file_param ;
                ( [ $? == 0 ] && "Param sort complete." ) || echo "Param sort failed."

                $check_files && bash $script_this_script check ;
            ;;
        esac
    ;;

    "update" )
        ( [ "$2" == "cell" ] || [ "$2" == "param" ] || [ -z $2 ] ) || ( echo "Not a valid update option. Use cell or param or leave blank." && exit 1 ) ;
        case $2 in
            "cell" )
                [ -z $3 ] && echo "Please enter a block to update... Exiting." && exit 1 ;
                [ -z $4 ] && echo "Please enter a value to update block to... Exiting." && exit 1 ;

                # $3 is param. $4 is its value. $5 is the (optional) unit.
                file_cell=$(get_cell_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_cell_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_cell_excess" && exit 1 ;
                #python $script_update_cell $file_cell $3 $4 $5 ;
                ( [ $? == 0 ] && echo "Cell updated successfully." ) || echo "Failed to update cell."

                $sort_files && bash $script_this_script --no-check "sort" cell ;
                $check_files && bash $script_this_script check cell ;
            ;;

            "param" )
                [ -z $3 ] && echo "Please enter a parameter to update... Exiting." && exit 1 ;
                [ -z $4 ] && echo "Please enter a value to update parameter to... Exiting." && exit 1 ;

                # $3 is param. $4 is its value. $5 is the (optional) unit.
                file_param=$(get_param_file) ; err=$? ;
                [ "$err" == 1 ] && echo "$err_param_excess" && exit 1 ;
                [ "$err" == 2 ] && echo "$err_param_zero" && exit 1 ;
                python $script_update_param $file_param $3 $4 $5 ;
                ( [ $? == 0 ] && echo "Param updated successfully." ) || echo "Failed to update param."

                $sort_files && bash $script_this_script --no-check "sort" param ;
                $check_files && bash $script_this_script check param ;
            ;;
        esac
    ;;
esac



# Sort param and cell files.
#if $sort_files ; then
#  # Check that any .orig files do not exist.
#  #( [[ -f "$file_param.orig" ]] || [[ -f "$file_cell.orig" ]] ) && echo ".orig file already exists... Exiting." && exit 1 ;
#
#  # Back up param and cell files.
#  #cp $file_param "$file_param.orig"
#  #cp $file_cell "$file_cell.orig"
#fi


