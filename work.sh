#!/bin/bash

###########################################
###              VARIABLES              ###
###########################################

script_this_script="/home/dean/tools/work.sh"

file_output=`mktemp` #"/home/dean/tools/files/output.txt"
file_IDs="/home/dean/tools/files/IDs.txt"
file_UUIDs="/home/dean/tools/files/UUIDs.txt"
file_summary_temp="/home/dean/tools/files/summary_temp_file.txt"
file_info="info"
file_commits="commits"
file_commit_IDs="IDs"
file_commit_prefix="commit_"
file_task_IDs="IDs"
file_task_prefix="task_"
file_save_IDs="IDs"
file_save_prefix="save_"
file_save_indicator=".save_indicator"
file_history_IDs="IDs"
file_history_prefix="history_"
file_knowledge_IDs="IDs"
file_knowledge_prefix="knowledge_"
file_summaries_IDs="IDs"
file_summary_prefix="summary_"
file_log_IDs="IDs"
file_log="log"

dir_tools="/home/dean/tools/"
dir_work="/home/dean/work/"
dir_work_len=$(echo -n $dir_work | wc -c)
dir_contents=".work"
dir_commits="commits"
dir_commits_saves_prefix="files_"
dir_tasks="tasks"
dir_saves="saves"
dir_saves_files_prefix="files_"
dir_save_temp="proj_save_temp"
dir_history="history"
dir_knowledge="knowledge"
dir_proj_backups="/home/dean/tools/files/project_backups/"
dir_daily_summaries="/home/dean/tools/files/daily_summaries/"
dir_log="/home/dean/tools/files/logs/"
dir_log_prefix="log_"
dir_log_save_prefix="files_"

char_separator=":"
char_bullet="-"

str_bisector="--"

col_fore_proj=$[5] ###
col_fore_date=$[5] ###
col_fore_dir=$[34]
col_fore_commits=$[32]
col_fore_tasks=$[36]
col_fore_saves=$[35]
col_fore_err=$[91]
col_fore_deadline_overdue=$[31]
col_fore_deadline_urgent=$[31]
col_fore_deadline_moderate=$[33]
col_fore_deadline_minor=$[32]
col_fore_deadline_none=$[32]
col_fore_history=$[93]
col_fore_knowledge=$[95]
col_fore_knowledge_category=$[33]
col_fore_knowledge_location=$[94]
col_fore_log=$[5] ###
col_fore_list=$[5] ###

col_back_proj=$[166] ###
col_back_date=$[111] ###
col_back_dir=$[49]
col_back_commits=$[49]
col_back_tasks=$[49]
col_back_saves=$[49]
col_back_err=$[49]
col_back_deadline_overdue=$[49]
col_back_deadline_urgent=$[49]
col_back_deadline_moderate=$[49]
col_back_deadline_minor=$[49]
col_back_deadline_none=$[49]
col_back_history=$[49]
col_back_knowledge=$[49]
col_back_knowledge_category=$[49]
col_back_knowledge_location=$[49]
col_back_log=$[92] ###
col_back_list=$[125] ###

format_proj=$[38] ###
format_date=$[38] ###
format_dir=$[0]
format_commits=$[0]
format_tasks=$[0]
format_tasks=$[0]
format_err=$[5]
format_deadline_overdue=$[5]
format_deadline_urgent=$[0]
format_deadline_moderate=$[0]
format_deadline_minor=$[0]
format_deadline_none=$[0]
format_history=$[0]
format_knowledge=$[0]
format_knowledge_category=$[0]
format_knowledge_location=$[0]
format_log=$[38] ###
format_list=$[38] ###

deadline_urgent=$[3] # Number of days.
deadline_urgent_sec=$[$deadline_urgent * 24 * 60 * 60]
deadline_moderate=$[7] # Number of days.
deadline_moderate_sec=$[$deadline_moderate * 24 * 60 * 60]

err_dir_not_proj="Directory is not a project. Use add option to add project."

proj_char_lim=$[10]
desc_char_lim=$[125]




###########################################
###               OPTIONS               ###
###########################################

for arg in "$@" ; do
  shift
  case "$arg" in
    #"--help") set -- "$@" "-h" ;;
    #"--current") set -- "$@" "-c" ;;
    "--no-zero-knowledge") set -- "$@" "-K" ;;
    "--suppress") set -- "$@" "-s" ;;
    *       ) set -- "$@" "$arg" ;;
  esac
done

# Define variable defaults before options.
no_suppress=true
no_zero_knowledge=false

# Accepts options.
while getopts ":hsK" opt ; do
  case ${opt} in
    s ) # Suppress output.
      no_suppress=false
    ;;
    K ) # No output for projects with zero knowledge.
      no_zero_knowledge=true
    ;;
    \? )
      echo "Invalid option [$OPTARG]: type "q -help" for help." >> "$file_output"
    ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" >> "$file_output"
    ;;
  esac
done

# If no options provided.
[ $OPTIND != 1 ] && shift $((OPTIND-1)) ;




###########################################
###              FUNCTIONS              ###
###########################################

#--------------------------------------------------------#
# Finds the attribute of the keyword ($2) in a file ($1) #
#   $1 : file                                            #
#   $2 : keyword                                         #
# Include the ^ in the keyword.                          #
#   E.g. if the file looks like,                         #
# |  attribute : 5 |                                     #
#   then use get_attribute "file_name" "^  attribute"    #
#--------------------------------------------------------#
function get_attribute {
  attribute_string=$(grep "$2" $1) ;
  echo "${attribute_string#*$char_separator }" ;
}

#--------------------------------------------------------#
# Returns the string with required spaces for echoing    #
#   $1 : string to be echoed                             #
#   $2 : desired length of string                        #
#--------------------------------------------------------#
function echo_set_length {
  if [ ${#1} -lt "$2" ] ; then
    num_spaces=$[$2 - ${#1}] ;
    spaces=$(printf "%0.s " $(seq 1 $num_spaces)) ;
    echo "$1$spaces" ;
  else
    echo "${1:0:$2}" ;
  fi
}


#--------------------------------------------------------#
# For the summary and check keywords                     #
#   $1 : index                                           #
#--------------------------------------------------------#
function info_for_summary {
  proj_deadline=$(get_attribute $file_info "^deadline Epoch") ;
  if [ -z $proj_deadline ] ; then proj_deadline=$[9999999999] ; fi  # Hard code to put projects without deadline at the end of the work summary.
  array_projs+=("$(pwd)") ;
  array_deadlines+=("$proj_deadline") ;
  echo "$1 $char_separator $proj_deadline" >> $file_summary_temp ;
  cd ../ ;
  bash $script_this_script update ;
}


#--------------------------------------------------------#
# Creates a history save in the project and in the daily #
# summary                                                #
#   $1 : Type of save                                    #
#--------------------------------------------------------#
function history_save {
  orig_pwd=$(pwd)
  history_ID=$[$(tail -1 $file_history_IDs) + 1] ; echo "$history_ID" >> $file_history_IDs ;
  history_file="$orig_pwd/$file_history_prefix$history_ID" ;

  cd ../ ;
    project=$(get_attribute $file_info "^name") ;
    location=$(get_attribute $file_info "^location") ;
  cd $orig_pwd ;

  summaries_dir="$dir_daily_summaries$(date "+%Y%m%d")"
  if [ -d "$summaries_dir" ] ; then
    cd "$summaries_dir" ;
    summary_ID=$[$(tail -1 $file_summaries_IDs) + 1] ;
    echo "$summary_ID" >> $file_summaries_IDs ;
  else
    mkdir "$summaries_dir" ;
    cd "$summaries_dir" ;
    echo "1" > $file_summaries_IDs ;
    summary_ID=$[1] ;
  fi
  summary_file="$file_summary_prefix$summary_ID" ;

  echo "ID            $char_separator $summary_ID" >> $summary_file ;
  echo "ID            $char_separator $history_ID" >> $history_file ;

  arr_files=( "$history_file" "$summary_file" ) ;

  case $1 in "commit_add"|"task_add"|"task_hold"|"task_resume"|"task_done"|"knowledge_add")
    description=$4 #$(echo_set_length "$4" $desc_char_lim) ;
    case ${#2} in "1") spaces="  " ;;
                  "2") spaces=" " ;;
                  "3") spaces="" ;;
    esac
    ;;
  esac

  case $1 in
    "commit_add" ) # $2 is the commit_ID. $3 is the date created in Epoch. $4 is the commit.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator Added \e[${format_commits};${col_fore_commits};${col_back_commits}mcommit\e[0m $2.$spaces        \e[${format_list};${col_fore_list};${col_back_list}m$description\e[0m" >> $file ;
      done
      date_created_human=$(date --date="@$3") ;
      date_created_comp=$3 ;
    ;;

    "task_add" ) # $2 is the task_ID. $3 is the date created in Epoch. $4 is the task.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator Added \e[${format_tasks};${col_fore_tasks};${col_back_tasks}mtask\e[0m $2.$spaces          \e[${format_list};${col_fore_list};${col_back_list}m$description\e[0m" >> $file ;
      done
      date_created_human=$(date --date="@$3") ;
      date_created_comp=$3 ;
    ;;

    "task_hold" ) # $2 is the task_ID. $3 is the date created in Epoch. $4 is the task.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_tasks};${col_fore_tasks};${col_back_tasks}mTask\e[0m $2 set to on hold.$spaces \e[${format_list};${col_fore_list};${col_back_list}m$description\e[0m" >> $file ;
      done
      date_created_human=$(date --date="@$3") ;
      date_created_comp=$3 ;
    ;;

    "task_resume" ) # $2 is the task_ID. $3 is the date created in Epoch. $4 is the task.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_tasks};${col_fore_tasks};${col_back_tasks}mTask\e[0m $2 set to resume.$spaces  \e[${format_list};${col_fore_list};${col_back_list}m$description\e[0m" >> $file ;
      done
      date_created_human=$(date --date="@$3") ;
      date_created_comp=$3 ;
    ;;

    "task_done" ) # $2 is the task_ID. $3 is the date created in Epoch. $4 is the task.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_tasks};${col_fore_tasks};${col_back_tasks}mTask\e[0m $2 set to complete.$spaces\e[${format_list};${col_fore_list};${col_back_list}m$description\e[0m" >> $file ;
      done
      date_created_human=$(date --date="@$3") ;
      date_created_comp=$3 ;
    ;;

    "save" ) # $2 is the save ID. $3 is the date created in Epoch. $4 is the save name.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_saves};${col_fore_saves};${col_back_saves}mSaved\e[0m project in save number $2 ($4)." >> $file ;
      done
      date_created_human=$(date --date="@$3") ;
      date_created_comp=$3 ;
    ;;

    "add" ) # $2 is the date created in Epoch.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_proj};${col_fore_proj};${col_back_proj}mProject\e[0m added." >> $file ;
      done
      date_created_human=$(date --date="@$2") ;
      date_created_comp=$2 ;
    ;;

    "completed" ) # $2 is the date created in Epoch.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_proj};${col_fore_proj};${col_back_proj}mProject\e[0m completed." >> $file ;
      done
      date_created_human=$(date --date="@$2") ;
      date_created_comp=$2 ;
    ;;

    "hold" ) # $2 is the date created in Epoch.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_proj};${col_fore_proj};${col_back_proj}mProject\e[0m put on hold." >> $file ;
      done
      date_created_human=$(date --date="@$2") ;
      date_created_comp=$2 ;
    ;;

    "ongoing" ) # $2 is the date created in Epoch.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_proj};${col_fore_proj};${col_back_proj}mProject\e[0m set to ongoing." >> $file ;
      done
      date_created_human=$(date --date="@$2") ;
      date_created_comp=$2 ;
    ;;

    "learning" ) # $2 is the date created in Epoch.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_proj};${col_fore_proj};${col_back_proj}mProject\e[0m set to learning." >> $file ;
      done
      date_created_human=$(date --date="@$2") ;
      date_created_comp=$2 ;
     ;;

    "resume" ) # $2 is the date created in Epoch.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_proj};${col_fore_proj};${col_back_proj}mProject\e[0m resumed." >> $file ;
      done
      date_created_human=$(date --date="@$2") ;
      date_created_comp=$2 ;
    ;;

    "remove" ) # $2 is the date created in Epoch.
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_proj};${col_fore_proj};${col_back_proj}mProject\e[0m removed." >> $file ;
      done
      date_created_human=$(date --date="@$2") ;
      date_created_comp=$2 ;
    ;;

    "knowledge_add" ) # $2 is the knowledge ID. $3 is the date created in Epoch. $4 is the knowledge
      for file in "${arr_files[@]}" ; do
        echo -e "description   $char_separator \e[${format_knowledge};${col_fore_knowledge};${col_back_knowledge}mKnowledge\e[0m $2 added.$spaces     \e[${format_list};${col_fore_list};${col_back_list}m$description\e[0m" >> $file ;
      done
      date_created_human=$(date --date="@$3") ;
      date_created_comp=$3 ;
    ;;
  esac

  echo "project       $char_separator $project" >> $summary_file ;
  echo "location      $char_separator $location" >> $summary_file ;

  for file in "${arr_files[@]}" ; do
    echo "created human $char_separator $date_created_human" >> $file ;
    echo "created Epoch $char_separator $date_created_comp" >> $file ;
  done

  cd $orig_pwd ;

}


#--------------------------------------------------------#
# Creates a log save in the daily summary                #
#   $1 : log ID                                          #
#   $2 : log                                             #
#   $3 : date created in Epoch                           #
#--------------------------------------------------------#
function log_save {
  summaries_dir="$dir_daily_summaries$(date "+%Y%m%d")"
  if [ -d "$summaries_dir" ] ; then
    cd "$summaries_dir" ;
    summary_ID=$[$(tail -1 $file_summaries_IDs) + 1] ;
    echo "$summary_ID" >> $file_summaries_IDs ;
  else
    mkdir "$summaries_dir" ;
    cd "$summaries_dir" ;
    echo "1" > $file_summaries_IDs ;
    summary_ID=$[1] ;
  fi

  case ${#1} in "1") spaces="  " ;;
                "2") spaces=" " ;;
                "3") spaces="" ;;
  esac

  summary_file="$file_summary_prefix$summary_ID" ;
  date_created_human=$(date --date="@$3") ;
  date_created_comp=$3 ;

  echo "ID            $char_separator $summary_ID" >> $summary_file ;
  echo -e "description   $char_separator Added \e[${format_log};${col_fore_log};${col_back_log}mlog\e[0m $1.            \e[${format_list};${col_fore_list};${col_back_list}m$2\e[0m" >> $summary_file ;
  echo "project       $char_separator N/A" >> $summary_file ;
  echo "location      $char_separator N/A" >> $summary_file ;
  echo "created human $char_separator $date_created_human" >> $summary_file ;
  echo "created Epoch $char_separator $date_created_comp" >> $summary_file ;
}




case $1 in

###########################################
###                HELP                 ###
###########################################
  "help" )
    echo 'usage: work -options [argument]' >> $file_output ;
    echo '        ""           [help]..............................print this help' >> $file_output ;

    echo -e "\e[${format_proj};${col_fore_proj};${col_back_proj}m" >> $file_output ;
    echo '        ""           [summary] [option]..................summary of projects that are:' >> $file_output ;
    echo '        ""               ""    [-|active]..................active' >> $file_output ;
    echo '        ""               ""    [ongoing]...................ongoing' >> $file_output ;
    echo '        ""               ""    [hold]......................on hold' >> $file_output ;
    echo '        ""               ""    [completed].................completed' >> $file_output ;
    echo '        ""           [check].............................summary of project of pwd' >> $file_output ;
    echo '        ""           [startup]...........................list of things done when last worked, knowledge of the day and option to see active projects' >> $file_output ;
    echo '        ""           [today].............................list of things done today and knowledge of the day' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo -e "\e[${format_commits};${col_fore_commits};${col_back_commits}m" >> $file_output ;
    echo '        ""           [commit] [option]...................commit actions for pwd:' >> $file_output ;
    echo '        ""              ""    [add] [files] [dirs].........add a commit with files and dirs' >> $file_output ;
    echo '        ""              ""    [list].......................list commits' >> $file_output ;
    echo '        ""              ""    [get commit_num].............get files/dirs of commit commit_num' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo -e "\e[${format_tasks};${col_fore_tasks};${col_back_tasks}m" >> $file_output ;
    echo '        ""           [task] [option].....................task actions for pwd:' >> $file_output ;
    echo '        ""             ""   [add]..........................add a task' >> $file_output ;
    echo '        ""             ""   [hold|resume|done task_num]....set task task_num to on hold, active or completed' >> $file_output ;
    echo '        ""             ""   [list] [option]................list:' >> $file_output ;
    echo '        ""             ""     ""   [-].......................active tasks' >> $file_output ;
    echo '        ""             ""     ""   [all].....................all tasks' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo -e "\e[${format_knowledge};${col_fore_knowledge};${col_back_knowledge}m" >> $file_output ;
    echo '        ""           [knowledge] [option]................knowledge actions:' >> $file_output ;
    echo '        ""                ""     [add].....................add a knowledge for pwd' >> $file_output ;
    echo '        ""                ""     [list]....................list knowledge for pwd' >> $file_output ;
    echo '        ""                ""     [all].....................list all knowledge for all projects' >> $file_output ;
    echo '        ""                ""     [search search_terms].....search knowledge for search_terms' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo -e "\e[${format_saves};${col_fore_saves};${col_back_saves}m" >> $file_output ;
    echo '        ""           [save] [option].....................save actions for pwd:' >> $file_output ;
    echo '        ""             ""   [-]............................create save of current state' >> $file_output ;
    echo '        ""             ""   [list].........................list previous saves' >> $file_output ;
    echo '        ""             ""   [get save_num].................get dir of files/dirs of save save_num' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo -e "\e[${format_proj};${col_fore_proj};${col_back_proj}m" >> $file_output ;
    echo '        ""           [add]...............................add project to pwd' >> $file_output ;
    echo '        ""           [resume]............................resume project in pwd' >> $file_output ;
    echo '        ""           [ongoing]...........................set project to ongoing in pwd' >> $file_output ;
    echo '        ""           [learning]..........................set project to learning in pwd' >> $file_output ;
    echo '        ""           [hold]..............................set project to on hold in pwd' >> $file_output ;
    echo '        ""           [complete]..........................set project to completed in pwd' >> $file_output ;
    echo '        ""           [remove]............................remove project in pwd (creates a backup)' >> $file_output ;
    echo '        ""           [update] [option]...................update actions for pwd:' >> $file_output ;
    echo '        ""              ""    [-]..........................complete update of project' >> $file_output ;
    echo '        ""              ""    [commits]....................update only commits' >> $file_output ;
    echo '        ""              ""    [tasks]......................update only tasks' >> $file_output ;
    echo '        ""              ""    [knowledge]..................update only knowledge' >> $file_output ;
    echo '        ""              ""    [deadline] [option]..........deadline actions:' >> $file_output ;
    echo '        ""              ""        ""     [-].................set deadline' >> $file_output ;
    echo '        ""              ""        ""     [remove]............remove deadline' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo -e "\e[${format_history};${col_fore_history};${col_back_history}m" >> $file_output ;
    echo '        ""           [history]...........................list history for pwd' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo -e "\e[${format_log};${col_fore_log};${col_back_log}m" >> $file_output ;
    echo '        ""           [log] [option] .....................log options:' >> $file_output ;
    echo '        ""            ""   [-].............................get log from past 7 days' >> $file_output ;
    echo '        ""            ""   [add] [files] [dirs]............add a log with files and dirs' >> $file_output ;
    echo '        ""            ""   [list] [num] [specifier]........get logs up to num specifier ago' >> $file_output ;
    echo '        ""            ""   [get]...........................get log information in pwd' >> $file_output ;
    echo -e "\e[0m" >> $file_output ;

    echo 'options:' >> $file_output ;
    echo '        -s, --suppress                 suppress output' >> $file_output ;
    echo '        -K, --no-zero-knowledge        suppress output for projects with zero knowledge' >> $file_output ;
  ;;



###########################################
###        SUMMARY | SUM | CHECK        ###
###########################################
  "summary" | "sum" | "check" )
    orig_pwd=$(pwd) ;

    # Get array of projects
    if [ "$1" = "summary" ] || [ "$1" = "sum" ] ; then
      index=$[0] ;
      for i in $(find $dir_work -path "*/$dir_contents") ; do
        cd $i ;
        proj_status=$(get_attribute $file_info "^status") ;
        if ( [ "$proj_status" = "active" ] && ( [ "$2" = "active" ] || [ -z "$2" ] ) ) ||
           ( [ "$proj_status" = "on hold" ] && [ "$2" = "hold" ] ) ||
           ( [ "$proj_status" = "ongoing" ] && [ "$2" = "ongoing" ] ) ||
           ( [ "$proj_status" = "learning"  ] && [ "$2" = "learning"  ] ) ||
           ( [ "$proj_status" = "completed" ] && [ "$2" = "completed" ] ) ||
           [ "$2" = "all" ] ; then #&& [ ! -f $file_save_indicator ] ; then
          info_for_summary $index ;
          index=$[$index + 1] ;
        fi
      done
      echo "${#array_projs[@]} project(s)." >> $file_output ;
    elif [ "$1" = "check" ] ; then
      if [ -d $dir_contents ] ; then cd $dir_contents ;
        info_for_summary 0 # Dummy index of 0.
      else
        echo $err_dir_not_proj >> $file_output ;
      fi
    fi

#    for i in "${!array_projs[@]}" ; do cd ${array_projs[$i]} ;
    for i in $(sort -k3 -n $file_summary_temp | cut -f1 --delimiter="$char_separator") ; do   # Check won't come through here if directory is not a project.
      proj_pwd="${array_projs[$i]}" ; cd $proj_pwd ;

      # Get project information.
      proj_ID=$(get_attribute $file_info "^ID") ;
      proj_name=$(get_attribute $file_info "^name") ;
      proj_description=$(get_attribute $file_info "^description") ;
      #proj_last_mod=$(date --date="@$(get_attribute $file_info "^last mod Epoch" )") ;
      proj_last_mod=$(get_attribute $file_info "^last mod human") ;
      proj_deadline_human=$(get_attribute $file_info "^deadline human") ;
      proj_deadline_comp=$(get_attribute $file_info "^deadline Epoch") ;
      proj_location=$(get_attribute $file_info "^location") ;
      proj_num_commits=$(get_attribute $file_info "^num commits") ;
      proj_num_tasks=$(get_attribute $file_info "^num tasks") ;
      proj_num_active_tasks=$(get_attribute $file_info "^num active tasks") ;
      proj_num_knowledge=$(get_attribute $file_info "^num knowledge") ;

      # Get latest commit.
      if [ "$proj_num_commits" -gt "0" ] ; then
        cd $dir_commits ;
          latest_commit_ID=$(for j in $file_commit_prefix* ; do echo $j; done | cut -c $[${#file_commit_prefix}+1]- | sort -n | tail -1) ;
          latest_commit_file="$file_commit_prefix$latest_commit_ID" ;
          latest_commit=$(get_attribute $latest_commit_file "^description") ;

          latest_commit_files="$dir_commits_saves_prefix$file_commit_prefix$latest_commit_ID"
          if [ -d "$latest_commit_files" ] ; then
            cd $latest_commit_files ;
              array_files=( ) ;
              array_dirs=( ) ;
              for j in * ; do
                if [ -f "$j" ] ; then
                  array_files+=( "$j" ) ;
                elif [ -d "$j" ] ; then
                  array_dirs+=( "$j" ) ;
                fi
              done
            cd ../ ;
            #mapfile -t array_files < <( grep "^  file" $latest_commit_file ) ;
            #mapfile -t array_dirs < <( grep "^  dir" $latest_commit_file ) ;
          else
            array_files=( ) ;
            array_dirs=( ) ;
          fi
        cd ../ ;
      fi

      # Output project information.
      if [ "$1" = "summary" ] || [ "$1" = "sum" ] ; then echo >> $file_output ; fi ;
      echo -e "\e[${format_proj};${col_fore_proj};${col_back_proj}m$proj_ID $proj_name\e[0m" >> $file_output ;
      echo "description   $char_separator $proj_description" >> $file_output ;

      if [ "$1" = "check" ] || [ "$2" = "all" ] || [ "$2" = "hold" ] || [ "$2" = "ongoing" ]; then
        proj_status=$(get_attribute $file_info "^status") ;
        echo "status        $char_separator $proj_status" >> $file_output ;
      fi

      echo "location      $char_separator $proj_location" >> $file_output ;
      echo "last modified $char_separator $proj_last_mod" >> $file_output ;

      if [ "$proj_status" = "active" ] || [ "$proj_status" = "on hold" ] || [ "$proj_status" = "ongoing" ] ; then
        if [ -z $proj_deadline_comp ] ; then # None.
          echo -e "deadline      $char_separator \e[${format_deadline_none};${col_fore_deadline_none};${col_back_deadline_none}mNone\e[0m" >> $file_output ;
        else
          date_now_comp=$(date +"%s") ;
          sec_to_deadline=$[$proj_deadline_comp - $date_now_comp]
          if [ $sec_to_deadline -lt 0 ] ; then # Overdue.
            echo -e "deadline      $char_separator \e[${format_deadline_overdue};${col_fore_deadline_overdue};${col_back_deadline_overdue}m$proj_deadline_human\e[0m" >> $file_output ;
          elif [ $sec_to_deadline -lt $deadline_urgent_sec ] ; then # Urgent.
            echo -e "deadline      $char_separator \e[${format_deadline_urgent};${col_fore_deadline_urgent};${col_back_deadline_urgent}m$proj_deadline_human\e[0m" >> $file_output ;
          elif [ $sec_to_deadline -lt $deadline_moderate_sec ] ; then # Moderate.
            echo -e "deadline      $char_separator \e[${format_deadline_moderate};${col_fore_deadline_moderate};${col_back_deadline_moderate}m$proj_deadline_human\e[0m" >> $file_output ;
          else # Long time away.
            echo -e "deadline      $char_separator \e[${format_deadline_minor};${col_fore_deadline_minor};${col_back_deadline_minor}m$proj_deadline_human\e[0m" >> $file_output ;
          fi
        fi
      fi

      echo "commits       $char_separator $proj_num_commits" >> $file_output ;
      #echo "tasks         $char_separator $proj_num_tasks" >> $file_output ;
      echo "active tasks  $char_separator $proj_num_active_tasks" >> $file_output ;
      echo "knowledge     $char_separator $proj_num_knowledge" >> $file_output ;

      # Output latest commit.
      if [ "$proj_num_commits" -gt "0" ] ; then
        echo -e "\e[${format_commits};${col_fore_commits};${col_back_commits}mlatest commit\e[0m" >> $file_output ;
        echo "  desc  $char_separator $latest_commit" >> $file_output ;
        if [ "${#array_files[@]}" -gt "0" ] ; then
          for j in "${array_files[@]}" ; do echo "   file $char_separator $j" >> $file_output ; done ;
        fi
        if [ "${#array_dirs[@]}" -gt "0" ] ; then
          for j in "${array_dirs[@]}" ; do
            #dir=${j#*$char_separator } ;
            echo -e "   dir  $char_separator \e[${format_dir};${col_fore_dir};${col_back_dir}m$j\e[0m" >> $file_output ;
          done ;
        fi
      fi

      # Output active tasks.
      if [ "$proj_num_active_tasks" -gt "0" ] ; then
        echo -e "\e[${format_tasks};${col_fore_tasks};${col_back_tasks}mtasks\e[0m" >> $file_output ;
        cd $dir_tasks ;
          arr_files=( $(ls -v) ) ;
          for task_file in "${arr_files[@]}" ; do
            if [[ $task_file = "$file_task_prefix"* ]] ; then
              task_status=$(get_attribute $task_file "^status") ;
              if [ "$task_status" = "active" ] ; then
                task_ID=$(get_attribute $task_file "^ID") ;
                task_desc=$(get_attribute $task_file "^description") ;
                echo "  $task_ID$char_separator $task_desc" >> $file_output ;
              fi
            fi
          done
        cd ../ ;
      fi
    done

    > $file_summary_temp ;
    cd $orig_pwd ;
  ;;



###########################################
###           STARTUP | TODAY           ###
###########################################
  "startup" | "today" )
    cd $dir_daily_summaries ;
    arr_dirs=($(ls -v)) ;

    cd ${arr_dirs[-1]} ;
    date_created_comp=$(get_attribute "${file_summary_prefix}1" "^created Epoch") ;
    date=$(date --date="@$date_created_comp" "+%a %d %b %Y") ;
    if [ "$date" = "$(date "+%a %d %b %Y")" ] && [ "$1" = "startup" ] ; then
      cd ../ ; cd ${arr_dirs[-2]} ;
      date_created_comp=$(get_attribute "${file_summary_prefix}1" "^created Epoch") ;
      date=$(date --date="@$date_created_comp" "+%a %d %b %Y") ;
      num_summaries=$(ls . | grep "^$file_summary_prefix" | wc -l) ;
    elif [ "$date" = "$(date "+%a %d %b %Y")" ] && [ "$1" = "today" ] ; then
      num_summaries=$(ls . | grep "^$file_summary_prefix" | wc -l) ;
    elif [ "$date" != "$(date "+%a %d %b %Y")" ] && [ "$1" = "startup" ] ; then
      num_summaries=$(ls . | grep "^$file_summary_prefix" | wc -l) ;
    elif [ "$date" != "$(date "+%a %d %b %Y")" ] && [ "$1" = "today" ] ; then
      num_summaries=$[0] ;
    fi

    echo >> $file_output ;
    if [ "$num_summaries" -gt "0" ] ; then
      if [ "$1" = "startup" ] ; then
        echo "You did $num_summaries thing(s) on $date." >> $file_output ;
      elif [ "$1" = "today" ] ; then
        echo "You have done $num_summaries thing(s) today." >> $file_output ;
      fi


      #for ((i=1;i<=num_summaries;i++)) ; do
      #for history_file in $file_summary_prefix* ; do
      arr_files=( $(ls -v) ) ;
      for summary_file in "${arr_files[@]}" ; do
        if [[ $summary_file = "$file_summary_prefix"* ]] ; then
          summary_description=$(get_attribute $summary_file "^description") ;
          summary_description_spaces=$(echo_set_length "$summary_description" $desc_char_lim) ; # Set to certain length or spaces added.
          summary_project=$(get_attribute $summary_file "^project") ;
          summary_project_spaces=$(echo_set_length "$summary_project" $proj_char_lim) ; # Set to certain length or spaces added.

          echo -e "  \e[${format_proj};${col_fore_proj};${col_back_proj}m$summary_project_spaces\e[0m $summary_description_spaces" >> $file_output ;
        fi
      done
      echo >> $file_output ;
    elif [ "$1" = "today" ] ; then
      echo "You have not done anything today (yet)." >> $file_output ;
      echo >> $file_output ;
    fi

    orig_pwd=$(pwd) ;

    arr_projs=() ; total_knowledge=$[0] ;
    for i in $(find $dir_work -path "*/$dir_contents") ; do
      cd $i ;
        num_knowledge=$(get_attribute $file_info "^num knowledge") ;
        for ((j=1;j<=num_knowledge;j++)) ; do
          arr_projs+=( "$i" ) ;
        done
        total_knowledge=$[$total_knowledge + $num_knowledge] ;
      cd ../
    done

    rand_num=$[RANDOM % $total_knowledge] ;
    cd ${arr_projs[$rand_num]} ;
    project=$(get_attribute $file_info "^name") ;
    num_knowledge=$(get_attribute $file_info "^num knowledge") ;
    cd $dir_knowledge ;
    rand_num=$[1 + RANDOM % $num_knowledge] ;
    knowledge_file="$file_knowledge_prefix$rand_num"
    #knowledge_ID=$(get_attribute $knowledge_file "^ID") ;
    knowledge_category=$(get_attribute $knowledge_file "^category") ;
    knowledge=$(get_attribute $knowledge_file "^description") ;

    echo -e "\e[${format_knowledge};${col_fore_knowledge};${col_back_knowledge}mknowledge of the day\e[0m \e[${format_knowledge_category};${col_fore_knowledge_category};${col_back_knowledge_category}m$knowledge_category\e[0m in \e[${format_proj};${col_fore_proj};${col_back_proj}m$project\e[0m" >> $file_output ;
    echo "  $knowledge" >> $file_output ;
    echo >> $file_output ;

  ;;



###########################################
###               COMMIT                ###
###########################################
  "commit" )
    if [ -d $dir_contents ] ; then

      case $2 in

        "add" )
          proj_pwd=$(pwd)

          # Get arrays of committed files and directories.
          array_files=() ; array_dirs=() ;
          shift 2 ;
          while [ -n "$1" ] ; do
            if [ -f "$1" ] ; then
              array_files+=("$1")
            else
              if [ -d "$1" ] ; then
                array_dirs+=("$1")
              else
                echo "No such file or directory $1."
              fi
            fi
            shift ;
          done

          cd $dir_contents ;
            cd $dir_commits ;
              # Get commit.
              read -ep 'Please enter a commit description: ' commit ;
              while [[ $commit = *"$char_separator"* ]] || [[ $commit = *"$str_bisector"* ]]; do
                read -ep 'That is not a valid input, please enter another description: ' commit ;
              done

              # Commit number.
              commit_ID=$[$(tail -1 $file_commit_IDs) + 1] ; echo "$commit_ID" >> $file_commit_IDs ;
              commit_file="$file_commit_prefix$commit_ID" ;
              date_created_comp=$(date +"%s") ;
              date_created_human=$(date --date="@$date_created_comp") ;

              # Save committed files and directories.
              if [ $[${#array_files[@]} + ${#array_dirs[@]}] -gt "0" ] ; then
                commit_save_dir="$dir_commits_saves_prefix$commit_file"
                mkdir $commit_save_dir ;
                for i in "${array_files[@]}" ; do
                  cp "$proj_pwd/$i" $commit_save_dir ;
                done
                for i in "${array_dirs[@]}" ; do
                  cp -r "$proj_pwd/$i" $commit_save_dir ;
                done
              fi

              # Output commit information.
              echo "ID            $char_separator $commit_ID" >> $commit_file ;
              #echo "status        $char_separator active" >> $commit_file ;
              echo "description   $char_separator $commit" >> $commit_file ;
              echo "created human $char_separator $date_created_human" >> $commit_file ;
              echo "created Epoch $char_separator $date_created_comp" >> $commit_file ;

              # Files.
              for i in "${array_files[@]}" ; do echo "  file $char_separator $i" >> $commit_file ; done ;

              # Directories.
              for i in "${array_dirs[@]}" ; do echo "  dir  $char_separator $i" >> $commit_file ; done ;
              echo "Number $commit_ID commit created." >> $file_output ;
            cd ../ ;

            cd $dir_history ;
              history_save commit_add $commit_ID $date_created_comp "$commit" ;
            cd ../ ;

          cd ../ ;

          bash $script_this_script update commits ;

          until [[ $accepted = "yes"* ]] ; do
          read -ep 'Would you like to add this as a log? ' response ;
          case "${response,,}" in
            yes|yesh|yep|y|yh|ye|yea|yeep|yas|yass|yeah|true|positive|affirm|affirmative|alright|"go on then"|"go on"|fine|fineeeeeee)
              accepted="yes"
            ;;

            no|nah|n|nope|yeetnt|NOOOOOOOOOOO|noo|narp|negative|false|incorrect|incorrection)
              accepted="yesnt"
            ;;

            *)
              accepted=""
            ;;
          esac
          done

          if [[ $accepted = "yes" ]] ; then
            bash $script_this_script log addcommit "$commit" ${array_files[@]} ${array_dirs[@]}
          fi
        ;;

        "list" )
          cd $dir_contents/$dir_commits ;

          num_commits=$(ls . | grep "^$file_commit_prefix" | wc -l) ;

          if [ "$num_commits" -gt "0" ] ; then
            arr_files=( $(ls -v) ) ;
            for commit_file in "${arr_files[@]}" ; do
              if [[ $commit_file = "$file_commit_prefix"* ]] ; then
                array_files=() ; array_dirs=() ;
                commit_ID=$(get_attribute $commit_file "^ID") ;
                commit=$(get_attribute $commit_file "^description") ;

                commit_files="$dir_commits_saves_prefix$file_commit_prefix$commit_ID"
                if [ -d "$commit_files" ] ; then
                  cd $commit_files ;
                    for j in * ; do
                      if [ -f "$j" ] ; then
                        array_files+=( "$j" ) ;
                      elif [ -d "$j" ] ; then
                        array_dirs+=( "$j" ) ;
                      fi
                    done
                  cd ../ ;
                fi

                #mapfile -t array_files < <( grep "^  file" $commit_file ) ;
                #mapfile -t array_dirs < <( grep "^  dir" $commit_file ) ;

                echo -e "\e[${format_commits};${col_fore_commits};${col_back_commits}mcommit $commit_ID\e[0m" >> $file_output ;
                echo "  desc $char_separator $commit" >> $file_output ;

                if [ "${#array_files[@]}" -gt "0" ] ; then
                  for j in "${array_files[@]}" ; do
                    echo "  file $char_separator $j" >> $file_output ;
                  done ;
                fi

                if [ "${#array_dirs[@]}" -gt "0" ] ; then
                  for j in "${array_dirs[@]}" ; do
                    # Need to obtain dir so can have separate colouring in echo.
                    dir=${j#*$char_separator } ;
                    echo -e "  dir  $char_separator \e[${format_dir};${col_fore_dir};${col_back_dir}m$dir\e[0m" >> $file_output ;
                  done ;
                fi

                echo >> $file_output ;
              fi
            done
          else
            echo "There are no commits for this project." >> $file_output ;
          fi
        ;;

        "get" ) # Retrieves files and directories saved for a specific commit.

          if [ -z $3 ] ; then
            echo "Please supply a commit number to get." >> $file_output ;
          else
            if [[ $[$3] != $3 ]] ; then
              echo "Please supply the commit number as an integer only." >> $file_output ;
            else
              commit_save_pwd="$(pwd)/$dir_contents/$dir_commits/$dir_commits_saves_prefix$file_commit_prefix$3" ;
              commit_save_dir="$dir_commits_saves_prefix$file_commit_prefix$3/"

              if [ -d $commit_save_pwd ] ; then
                if [ -d $commit_save_dir ] ; then
                  echo "$commit_save_dir directory already exists." >> $file_output ;
                else
                  cp -r $commit_save_pwd . ;
                  echo "Files and directories for commit $3 retrieved in directory $commit_save_dir." >> $file_output ;
                fi
              else
                echo "Commit $3 does not exist." >> $file_output ;
              fi

            fi
          fi

        ;;

        * )
          echo "Not a valid commit option. Please use add, get or list." >> $file_output ;
        ;;

      esac
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###                TASK                 ###
###########################################
  "task" )
    if [ -d $dir_contents ] ; then cd $dir_contents/$dir_tasks ;

      case $2 in

        "add" )
          # Get task.
          read -ep 'Please enter a task description: ' task ;
          while [[ $task = *"$char_separator"* ]] || [[ $task = *"$str_bisector"* ]] ; do
            read -ep 'That is not a valid input, please enter another description: ' task ;
          done

          # Task ID.
          task_ID=$[$(tail -1 $file_task_IDs) + 1] ; echo "$task_ID" >> $file_task_IDs ;
          task_file="$file_task_prefix$task_ID" ;
          date_created_comp=$(date +"%s") ;
          date_created_human=$(date --date="@$date_created_comp") ;

          echo "ID            $char_separator $task_ID" >> $task_file ;
          echo "status        $char_separator active" >> $task_file ;
          echo "description   $char_separator $task" >> $task_file ;
          echo "created human $char_separator $date_created_human" >> $task_file ;
          echo "created Epoch $char_separator $date_created_comp" >> $task_file ;

          echo "Number $task_ID task created." >> $file_output ;

          cd ../ ;

          cd $dir_history ;
            history_save task_add $task_ID $date_created_comp "$task" ;
          cd ../ ;

          cd ../ ;

          bash $script_this_script update tasks ;
        ;;

        "hold" | "resume" | "done" )
          if [ -z $3 ] ; then
            echo "Please supply a task number to be set to $2." >> $file_output ;
          else
            if [[ $[$3] != $3 ]] ; then
              echo "Please supply the task number as an integer only." >> $file_output ;
            else
              if [ -f "$file_task_prefix$3" ] ; then
                case $2 in
                  "hold"   ) new_status="on hold" ; history_arg="task_hold"  ;;
                  "resume" ) new_status="active" ; history_arg="task_resume" ;;
                  "done"   ) new_status="complete" ; history_arg="task_done" ;;
                esac
                sed -i "s|status .*|status        $char_separator $new_status|g" $file_task_prefix$3 ;
                echo "Task $3 is now $new_status." >> $file_output ;
                task=$(get_attribute "$file_task_prefix$3" "^description") ;
                cd ../$dir_history ;
                  history_save $history_arg $3 $(date +"%s") "$task" ;
                cd ../../ ;
                bash $script_this_script update tasks ;
              else
                echo "Task $3 does not exist." >> $file_output ;
              fi
            fi
          fi
        ;;

        "list" )
          if [ "$3" = "all" ] ; then
            num_tasks=$(ls . | grep "^$file_task_prefix" | wc -l)
          else
            num_tasks=$(for i in $file_task_prefix* ; do [ -f "$i" ] && cat $i ; done | grep "^status .*$char_separator active" | wc -l) ;  # Only active ones.
          fi

          if [ "$num_tasks" -gt "0" ] ; then
            arr_files=( $(ls -v) ) ;
            for task_file in "${arr_files[@]}" ; do
              if [[ $task_file = "$file_task_prefix"* ]] ; then
                task_status=$(get_attribute $task_file "^status") ;
                if [ "$3" = "all" ] || [ "$task_status" != "complete" ] ; then
                  task_ID=$(get_attribute $task_file "^ID") ;
                  task=$(get_attribute $task_file "^description") ;

                  echo -e "\e[${format_tasks};${col_fore_tasks};${col_back_tasks}mtask $task_ID\e[0m" >> $file_output ;
                  echo "  status $char_separator $task_status" >> $file_output ;
                  echo "  desc   $char_separator $task" >> $file_output ;
                  echo >> $file_output ;
                fi
              fi
            done
          else
            if [ "$3" = "all" ] ; then
              echo "There are no tasks for this project." >> $file_output ;
            else
              echo "There are no current tasks for this project." >> $file_output ;
            fi
          fi
        ;;

        * )
          echo "Not a valid task option. Please use add, hold, resume, done or list." >> $file_output ;
        ;;

      esac

    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###              KNOWLEDGE              ###
###########################################
  "knowledge" )
      case $2 in
        "add" )
          if [ -d $dir_contents ] ; then cd $dir_contents/$dir_knowledge ;
            # Get knowledge.
            read -ep 'Please enter a knowledge description: ' knowledge ;
            while [[ $knowledge = *"$char_separator"* ]] || [[ $knowledge = *"$str_bisector"* ]] ; do
              read -ep 'That is not a valid input, please enter another description: ' knowledge ;
            done

            # Get category.
            read -ep 'Please enter a knowledge category: ' category ;
            while [[ $category = *"$char_separator"* ]] || [[ $category = *"$str_bisector"* ]] ; do
              read -ep 'That is not a valid input, please enter another description: ' category ;
            done

            while [[ -n "${category// }" ]] ; do
              array_categories+=("$category;") ;
              read -ep 'Please enter another knowledge category (leave blank to stop): ' category ;
              while [[ $category = *"$char_separator"* ]] || [[ $category = *"$str_bisector"* ]] ; do
                read -ep 'That is not a valid input, please enter another description (leave blank to stop): ' category ;
              done
            done

            knowledge_ID=$[$(tail -1 $file_knowledge_IDs) + 1] ; echo "$knowledge_ID" >> $file_knowledge_IDs ;
            knowledge_file="$file_knowledge_prefix$knowledge_ID"
            date_created_comp=$(date +"%s") ;
            date_created_human=$(date --date="@$date_created_comp") ;

            echo "ID            $char_separator $knowledge_ID" >> $knowledge_file ;
            echo "description   $char_separator $knowledge" >> $knowledge_file ;
            echo "category      $char_separator ${array_categories[@]}" >> $knowledge_file ;
            echo "created human $char_separator $date_created_human" >> $knowledge_file ;
            echo "created Epoch $char_separator $date_created_comp" >> $knowledge_file ;

            echo "Number $knowledge_ID knowledge created." >> $file_output ;

            cd ../ ;

            cd $dir_history ;
              history_save knowledge_add $knowledge_ID $date_created_comp "$knowledge" ;
            cd ../ ;

            cd ../ ;

            bash $script_this_script update knowledge ;
          else
            echo $err_dir_not_proj >> $file_output ;
          fi
        ;;

        "list" )
          if [ -d $dir_contents ] ; then cd $dir_contents/$dir_knowledge ;
            num_knowledge=$(ls . | grep "^$file_knowledge_prefix" | wc -l) ;

            if [ "$num_knowledge" -gt "0" ] ; then
              arr_files=( $(ls -v) ) ;
              for knowledge_file in "${arr_files[@]}" ; do
                if [[ $knowledge_file = "$file_knowledge_prefix"* ]] ; then

                  knowledge_ID=$(get_attribute $knowledge_file "^ID") ;
                  knowledge=$(get_attribute $knowledge_file "^description") ;
                  knowledge_category=$(get_attribute $knowledge_file "^category") ;

                  if $no_zero_knowledge ; then # For use in work knowledge all.
                    echo -e "\e[${format_knowledge};${col_fore_knowledge};${col_back_knowledge}mknowledge\e[0m \e[${format_knowledge_category};${col_fore_knowledge_category};${col_back_knowledge_category}m$knowledge_category\e[0m in \e[${format_proj};${col_fore_proj};${col_back_proj}m$4\e[0m in \e[${format_dir};${col_fore_dir};${col_back_dir}m$5\e[0m" >> $file_output ;
                  else
                    echo -e "\e[${format_knowledge};${col_fore_knowledge};${col_back_knowledge}mknowledge $knowledge_ID\e[0m \e[${format_knowledge_category};${col_fore_knowledge_category};${col_back_knowledge_category}m$knowledge_category\e[0m" >> $file_output ;
                  fi

                  echo "          $knowledge" >> $file_output ;
                  echo >> $file_output ;

                fi
              done
            else
              if ! $no_zero_knowledge ; then
                echo "There is no knowledge for this project." >> $file_output ;
              fi
            fi
          else
            echo $err_dir_not_proj >> $file_output ;
          fi
        ;;

        "all" )
          orig_pwd=$(pwd) ;

          for i in $(find $dir_work -path "*/$dir_contents") ; do
            cd $i/
              proj_name=$(get_attribute $file_info "^name") ;
              proj_location=$(get_attribute $file_info "^location") ;
            cd ../
            bash $script_this_script --no-zero-knowledge knowledge list "$proj_name" "$proj_location" ;
          done
        ;;

        "search" )
          shift 2 ;   # To ignore the "knowledge" and "search" arguments passed into script.
          search_terms=( "$@" )
          for i in $(find $dir_work -path "*/$dir_contents") ; do
            cd $i/ ; proj_name=$(get_attribute $file_info "^name") ; proj_location=$(get_attribute $file_info "^location") ; cd $dir_knowledge ;
            for knowledge_file in $file_knowledge_prefix* ; do
              match=$[0] ;
              if [ -f "$knowledge_file" ] ; then
                knowledge_category=$(get_attribute $knowledge_file "^category") ;
                knowledge_desc=$(get_attribute $knowledge_file "^description") ;
                for j in "${search_terms[@]}" ; do
                  if [[ "${knowledge_category,,}" = *"${j,,}"* ]] || [[ "${knowledge_desc,,}" = *"${j,,}"* ]] ; then match=$[1] ; fi
                done
              fi
              if [ $match == $[1] ] ; then
                knowledge_ID=$(get_attribute $knowledge_file "^ID") ;
                knowledge=$(get_attribute $knowledge_file "^description") ;
                echo -e "\e[${format_knowledge};${col_fore_knowledge};${col_back_knowledge}mknowledge $knowledge_ID\e[0m \e[${format_knowledge_category};${col_fore_knowledge_category};${col_back_knowledge_category}m$knowledge_category\e[0m in \e[${format_proj};${col_fore_proj};${col_back_proj}m$proj_name\e[0m in \e[${format_dir};${col_fore_dir};${col_back_dir}m$proj_location\e[0m" >> $file_output ;
                echo "          $knowledge" >> $file_output ;
                echo >> $file_output ;
              fi
            done
          done

        ;;

        * )
          echo "Not a valid task option. Please use add, list, all or search." >> $file_output ;
        ;;
      esac
  ;;



###########################################
###                SAVE                 ###
###########################################
  "save" )
    if [ -d $dir_contents ] ; then
      echo "Save feature contains rm and mv commands so has been disabled."
      ###case $2 in
      ###  "" )
      ###    read -ep 'Please enter a save name (leave blank if not needed): ' save_name ;
      ###    while [[ $save_name = *"$char_separator"* ]] || [[ $save_name = *"$str_bisector"* ]] ; do
      ###      read -ep 'That is not a valid input, please enter another name: ' save_name ;
      ###    done

      ###    proj_pwd=$(pwd) ;
      ###    save_temp_dir="$dir_tools/$dir_save_temp"
      ###    save_ID_file="$dir_contents/$dir_saves/$file_save_IDs"
      ###    if [ -d $save_temp_dir ] ; then
      ###      echo "Cannot save project as a directory called $dir_save_temp already exists in $dir_tools." >> $file_output ;
      ###    else
      ###      save_ID=$[$(tail -1 $save_ID_file) + 1] ; echo "$save_ID" >> $save_ID_file ;
      ###      save_created_comp=$(date +"%s") ;
      ###      save_created_human=$(date --date="@$save_created_comp") ;

      ###      save_file="$proj_pwd/$dir_contents/$dir_saves/$file_save_prefix$save_ID"
      ###      save_dir="$proj_pwd/$dir_contents/$dir_saves/$dir_saves_files_prefix$file_save_prefix$save_ID"

      ###      echo "ID            $char_separator $save_ID" >> $save_file ;
      ###      echo "name          $char_separator $save_name" >> $save_file ;
      ###      echo "created human $char_separator $save_created_human" >> $save_file ;
      ###      echo "created Epoch $char_separator $save_created_comp" >> $save_file ;

      ###      cp -r $proj_pwd $save_temp_dir ;
      ###      mv $save_temp_dir $save_dir ; # Do NOT shorten this and the above line into one step, BAD THINGS WILL HAPPEN
      ###      cd $save_dir ; rm -r $dir_contents ; #touch $file_save_indicator ; # Used to add save indicator (now not needed) to save folder and also removes project contents folder.
      ###      echo "Save number $save_ID complete." >> $file_output ;
      ###      cd $proj_pwd/$dir_contents/$dir_history ;
      ###        history_save save $save_ID $save_created_comp "${save_name:-"no name"}" ;
      ###      cd ../../ ;
      ###    fi
      ###  ;;

      ###  "list" ) # List saves with save date.
      ###    proj_pwd=$(pwd) ;
      ###    num_saves=$(ls $proj_pwd/$dir_contents/$dir_saves | grep "^$file_save_prefix" | wc -l) ;

      ###    cd $proj_pwd/$dir_contents/$dir_saves ;
      ###    if [ "$num_saves" -gt "0" ] ; then
      ###      arr_files=( $(ls -v) ) ;
      ###      for save_file in "${arr_files[@]}" ; do
      ###        if [[ $save_file = "$file_save_prefix"* ]] ; then
      ###          save_ID=$(get_attribute $save_file "^ID") ;
      ###          save_name=$(get_attribute $save_file "^name") ;
      ###          save_date=$(get_attribute $save_file "^created human") ;

      ###          echo -e "\e[${format_saves};${col_fore_saves};${col_back_saves}msave $save_ID\e[0m" >> $file_output ;
      ###          echo "  name   $char_separator ${save_name:-"no name"}" >> $file_output ;
      ###          echo "  date   $char_separator $save_date" >> $file_output ;
      ###          echo >> $file_output ;
      ###        fi
      ###      done
      ###    else
      ###      echo "There are no current saves for this project." >> $file_output ;
      ###    fi
      ###  ;;

      ###  "get" ) # Retrieves files and directories for save.

      ###    if [ -z $3 ] ; then
      ###      echo "Please supply a save number to get." >> $file_output ;
      ###    else
      ###      if [[ $[$3] != $3 ]] ; then
      ###        echo "Please supply the save number as an integer only." >> $file_output ;
      ###      else
      ###        proj_pwd=$(pwd) ;
      ###        saves_dir="$proj_pwd/$dir_contents/$dir_saves/" ; # Directory where saves are held.
      ###        save_dir="$proj_pwd/$dir_contents/$dir_saves/$dir_saves_files_prefix$file_save_prefix$3" ; #Directory of files for specified save.
      ###        save_dir_new="$proj_pwd/$dir_saves_files_prefix$file_save_prefix$3" ;
      ###        save_name=$(get_attribute $saves_dir/$file_save_prefix$3 "^name") ;
      ###        if [ -d $save_dir ] ; then
      ###          if [ -d $save_dir_new ] ; then
      ###            echo "$save_dir_new directory already exists in project directory." >> $file_output ;
      ###          else
      ###            cp -r $save_dir $save_dir_new ;
      ###            echo "Files and directories for save $3 (${save_name:-"no name"}) retrieved in directory $save_dir_new." >> $file_output ;
      ###          fi
      ###        else
      ###          echo "Save $3 does not exist." >> $file_output ;
      ###        fi
      ###      fi
      ###    fi
      ###  ;;

      ###  * )
      ###    echo "Not a valid save option. Please use list, get or no option." >> $file_output ;
      ###  ;;
      ###esac
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###                 ADD                 ###
###########################################
  "add" )  # Add folder as a project.
    if [ -d $dir_contents ] ; then
      echo "Directory already a project. Use update option to update directory." >> $file_output ;
    else
      # Get project info.
      proj_pwd=$(pwd) ;
      proj_ID=$[$(tail -1 $file_IDs) + 1] ; echo "$proj_ID" >> $file_IDs ;
      proj_created_comp=$(date +"%s") ;
      proj_created_human=$(date --date="@$proj_created_comp") ;
      proj_last_mod_comp=$(find $proj_pwd -not -path "*/$dir_contents*" -exec stat {} --printf="%Y\n" \; | sort -nr | head -n 1) ;
      proj_last_mod_human=$(date --date="@$proj_last_mod_comp")
      #proj_last_mod_date=$(find $proj_pwd -not -path "*/$dir_contents*" -printf "%TY-%Tm-%Td\n" | sort -n | tail -1) ;
      #proj_last_mod_time=$(find $proj_pwd -not -path "*/$dir_contents*" -printf "%TT\n" | sort -n | tail -1) ;
      proj_location=$(echo "${proj_pwd:$dir_work_len}/")   #-1})
      num_files=$(find $proj_pwd -mindepth 1 -type f -not -path "*/$dir_contents*" | wc -l) ;
      num_dir=$(find $proj_pwd -mindepth 1 -type d -not -path "*/$dir_contents*" | wc -l) ;

      # Get project name.
      read -ep 'Please enter a project name: ' proj_name ;
      while [[ $proj_name = *"$char_separator"* ]] || [[ $proj_name = *"$str_bisector"* ]] ; do
        read -ep 'That is not a valid input, please enter another name: ' proj_name ;
      done

      # Get project description.
      read -ep 'Please enter a project description: ' proj_desc ;
      while [[ $proj_desc = *"$char_separator"* ]] || [[ $proj_desc = *"$str_bisector"* ]] ; do
        read -ep 'That is not a valid input, please enter another description: ' proj_desc ;
      done

      mkdir $dir_contents ; cd $dir_contents ;

        # Project info.
        touch $file_info ;
        #echo "UUID          $char_separator $(uuidgen)" >> $file_info ;
        echo "ID                 $char_separator $proj_ID" >> $file_info ;
        echo "name               $char_separator $proj_name" >> $file_info ;
        echo "description        $char_separator $proj_desc" >> $file_info ;
        echo "created human      $char_separator $proj_created_human" >> $file_info ;
        echo "created Epoch      $char_separator $proj_created_comp" >> $file_info ;
        echo "last mod human     $char_separator $proj_last_mod_human" >> $file_info ;
        echo "last mod Epoch     $char_separator $proj_last_mod_comp" >> $file_info ;
        #echo "date last modified $char_separator $proj_last_mod_date" >> $file_info ;
        #echo "time last modified $char_separator $proj_last_mod_time" >> $file_info ;
        echo "deadline human     $char_separator " >> $file_info ;
        echo "deadline Epoch     $char_separator " >> $file_info ;
        echo "status             $char_separator active" >> $file_info ;
        echo "directory          $char_separator $proj_pwd" >> $file_info ;
        echo "location           $char_separator $proj_location" >> $file_info ;
        echo "num files          $char_separator $num_files" >> $file_info ;
        echo "num dir            $char_separator $num_dir" >> $file_info ;
        echo "num commits        $char_separator 0" >> $file_info ;
        echo "num tasks          $char_separator 0" >> $file_info ;
        echo "num active tasks   $char_separator 0" >> $file_info ;
        echo "num knowledge      $char_separator 0" >> $file_info ;

        # Project commits.
        mkdir $dir_commits ;
        cd $dir_commits ;
          echo "0" > $file_commit_IDs ;
        cd ../

        # Project tasks.
        mkdir $dir_tasks ;
        cd $dir_tasks ;
          echo "0" > $file_task_IDs ;
        cd ../

        # Project saves.
        mkdir $dir_saves ;
        cd $dir_saves ;
          echo "0" > $file_save_IDs ;
        cd ../

        # Project history.
        mkdir $dir_history ;
        cd $dir_history ;
          echo "0" > $file_history_IDs ;
          history_save add $proj_created_comp ;
        cd ../

        # Project knowledge.
        mkdir $dir_knowledge ;
        cd $dir_knowledge ;
          echo "0" > $file_knowledge_IDs ;
        cd ../
      cd ../
    fi
  ;;



###########################################
###               ON HOLD               ###
###########################################
  "hold" )  # Set a project on hold.
    if [ -d $dir_contents ] ; then
      cd $dir_contents ;
        sed -i "s|status .*|status             $char_separator on hold|g" $file_info ;
        date_created_comp=$(date +"%s") ;
        cd $dir_history ;
          history_save hold $date_created_comp ;
        cd ../
      cd ../
      echo "Project set to on hold." >> $file_output ;
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###               ONGOING               ###
###########################################
  "ongoing" ) # Set a project as ongoing.
    if [ -d $dir_contents ] ; then
      cd $dir_contents ;
        sed -i "s|status .*|status             $char_separator ongoing|g" $file_info ;
        date_created_comp=$(date +"%s") ;
        cd $dir_history ;
          history_save ongoing $date_created_comp ;
        cd ../
      cd ../
      echo "Project set to ongoing." >> $file_output ;
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###              LEARNING               ###
###########################################
  "learning" ) # Set a project as learning.
    if [ -d $dir_contents ] ; then
      cd $dir_contents ;
        sed -i "s|status .*|status             $char_separator learning|g" $file_info ;
        date_created_comp=$(date +"%s") ;
         cd $dir_history ;
           history_save learning $date_created_comp ;
         cd ../
       cd ../
       echo "Project set to learning." >> $file_output ;
     else
       echo $err_dir_not_proj >> $file_output ;
     fi
   ;;



###########################################
###               RESUME                ###
###########################################
  "resume" )  # Resume a project.
    if [ -d $dir_contents ] ; then
      cd $dir_contents ;
        sed -i "s|status .*|status             $char_separator active|g" $file_info ;
        date_created_comp=$(date +"%s") ;
        cd $dir_history ;
          history_save resume $date_created_comp ;
        cd ../
      cd ../
      echo "Project set to active." >> $file_output ;
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###              COMPLETE               ###
###########################################
  "complete" )  # Complete a project.
    if [ -d $dir_contents ] ; then
      bash $script_this_script --suppress update deadline remove ;
      cd $dir_contents ;
        sed -i "s|status .*|status             $char_separator completed|g" $file_info ;
        date_created_comp=$(date +"%s") ;
        cd $dir_history ;
          history_save completed $date_created_comp ;
        cd ../
      cd ../
      echo "Project now completed." >> $file_output ;
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###               UPDATE                ###
###########################################
  "update" )
    if [ -d $dir_contents ] ; then
      case $2 in
        "knowledge" )
          proj_pwd=$(pwd) ;
          num_knowledge=$(ls $proj_pwd/$dir_contents/$dir_knowledge | grep "^$file_knowledge_prefix" | wc -l) ;
          cd $dir_contents ;
            sed -i "s|num knowledge .*|num knowledge      $char_separator $num_knowledge|g" $file_info ;
          cd ../
        ;;

        "deadline" )
          case $3 in
            "remove" )
              cd $dir_contents ;
                sed -i "s|deadline human .*|deadline human     $char_separator |g" $file_info ;
                sed -i "s|deadline Epoch .*|deadline Epoch     $char_separator |g" $file_info ;
                echo "Deadline removed." >> $file_output ;
              cd ../ ;
            ;;

            "" )
              read -ep 'Please enter a year: ' year ;
              while [[ $[$year] != $year ]] ; do
                read -ep 'That is not a valid input, please enter again: ' year ;
              done

              read -ep 'Please enter a month: ' month ;
              while [[ $[$month] != $month ]] ; do
                read -ep 'That is not a valid input, please enter again: ' month ;
              done

              read -ep 'Please enter a day: ' day ;
              while [[ $[$day] != $day ]] ; do
                read -ep 'That is not a valid input, please enter again: ' day ;
              done

              read -ep 'Please enter an hour: ' hour ;
              while [[ $[$hour] != $hour ]] ; do
                read -ep 'That is not a valid input, please enter again: ' hour ;
              done

              read -ep 'Please enter a minute: ' min ;
              while [[ $[$min] != $min ]] ; do
                read -ep 'That is not a valid input, please enter again: ' min ;
              done

              deadline_comp=$(date --date="${month}/${day}/${year} ${hour}:${min}:00" +"%s") ;
              deadline_human=$(date --date="@${deadline_comp}") ;

              cd $dir_contents ;
                sed -i "s|deadline human .*|deadline human     $char_separator $deadline_human|g" $file_info ;
                sed -i "s|deadline Epoch .*|deadline Epoch     $char_separator $deadline_comp|g" $file_info ;
              cd ../ ;
            ;;

            * )
              echo 'Not a valid deadline option. Please use "work update deadline" or "work update deadline remove".' >> $file_output ;
            ;;
          esac
        ;;

        "commits" )
          proj_pwd=$(pwd) ;
          num_commits=$(ls $proj_pwd/$dir_contents/$dir_commits | grep "^$file_commit_prefix" | wc -l) ;

          cd $dir_contents ;
            sed -i "s|num commits .*|num commits        $char_separator $num_commits|g" $file_info ;
          cd ../ ;
        ;;

        "tasks" )
          proj_pwd=$(pwd) ;
          num_tasks=$(ls $proj_pwd/$dir_contents/$dir_tasks | grep "^$file_task_prefix" | wc -l) ;
          num_active_tasks=$(for i in $proj_pwd/$dir_contents/$dir_tasks/$file_task_prefix* ; do [ -f "$i" ] && cat $i ; done | grep "^status .*$char_separator active" | wc -l) ;

          cd $dir_contents ;
            sed -i "s|num tasks .*|num tasks          $char_separator $num_tasks|g" $file_info ;
            sed -i "s|num active tasks .*|num active tasks   $char_separator $num_active_tasks|g" $file_info ;
          cd ../ ;
        ;;

        "" )
          proj_pwd=$(pwd) ;
          #proj_last_mod_comp=$(find $proj_pwd -not -path "*/$dir_contents*" -exec stat {} --printf="%Y\n" \; | sort -nr | head -n 1) ;
          proj_last_mod_comp=$(find $proj_pwd -not -path "*/$dir_contents*" -printf "%T@\n" | sort -n | tail -n 1) ;
          proj_last_mod_human=$(date --date="@$proj_last_mod_comp")
          #proj_last_mod_date=$(find $proj_pwd -not -path "*/$dir_contents*" -printf "%TY-%Tm-%Td\n" | sort -n -r | head -n 1) ;
          #proj_last_mod_time=$(find $proj_pwd -not -path "*/$dir_contents*" -printf "%TT\n" | sort -n -r | head -n 1) ;
          #proj_last_mod=$(find $proj_pwd -not -path "*/$dir_contents*" -exec stat {} --printf="%y\n" \; | sort -n -r | head -n 1) ;
          proj_location=$(echo "${proj_pwd:$dir_work_len}/")   #-1})
          num_files=$(find $proj_pwd -mindepth 1 -type f -not -path "*/$dir_contents*" | wc -l) ;
          num_dir=$(find $proj_pwd -mindepth 1 -type d -not -path "*/$dir_contents*" | wc -l) ;
          num_commits=$(ls $proj_pwd/$dir_contents/$dir_commits | grep "^$file_commit_prefix" | wc -l) ;
          num_tasks=$(ls $proj_pwd/$dir_contents/$dir_tasks | grep "^$file_task_prefix" | wc -l) ;
          num_active_tasks=$(for i in $proj_pwd/$dir_contents/$dir_tasks/$file_task_prefix* ; do [ -f "$i" ] && cat $i ; done | grep "^status .*$char_separator active" | wc -l) ;
          num_knowledge=$(ls $proj_pwd/$dir_contents/$dir_knowledge | grep "^$file_knowledge_prefix" | wc -l) ;

          cd $dir_contents ;
            sed -i "s|last mod human .*|last mod human     $char_separator $proj_last_mod_human|g" $file_info ;
            sed -i "s|last mod Epoch .*|last mod Epoch     $char_separator $proj_last_mod_comp|g" $file_info ;
            #sed -i "s|date last modified .*|date last modified $char_separator $proj_last_mod_date|g" $file_info ;
            #sed -i "s|time last modified .*|time last modified $char_separator $proj_last_mod_time|g" $file_info ;
            sed -i "s|directory .*|directory          $char_separator $proj_pwd|g" $file_info ;
            sed -i "s|location .*|location           $char_separator $proj_location|g" $file_info ;
            sed -i "s|num files .*|num files          $char_separator $num_files|g" $file_info ;
            sed -i "s|num dir .*|num dir            $char_separator $num_dir|g" $file_info ;
            sed -i "s|num commits .*|num commits        $char_separator $num_commits|g" $file_info ;
            sed -i "s|num tasks .*|num tasks          $char_separator $num_tasks|g" $file_info ;
            sed -i "s|num active tasks .*|num active tasks   $char_separator $num_active_tasks|g" $file_info ;
            sed -i "s|num knowledge .*|num knowledge      $char_separator $num_knowledge|g" $file_info ;
          cd ../
        ;;

        * )
          echo 'Not a valid update option. Please use "work update" or "work update __VAR__" where __VAR__ is tasks, commits, knowledge or deadline.' >> $file_output ;
        ;;
      esac
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###                 LOG                 ###
###########################################
  "log" )
    case $2 in
      "add"|"addcommit" )
        if [ "$2" == "addcommit" ] ; then
          from_commit="true"
          shift 2 ;
          log="$1" ;
          shift ;
        else
          shift 2 ;
        fi

        # Get arrays of logged files and directories.
        array_files=() ; array_dirs=() ;
        while [ -n "$1" ] ; do
          if [ "$1" != "$file_log" ] ; then
            if [ -f "$1" ] ; then
              array_files+=("$1")
            else
              if [ -d "$1" ] ; then
                array_dirs+=("$1")
              else
                echo "No such file or directory $1."
              fi
            fi
          else
            echo "Ignoring file $1."
          fi
          shift ;
        done

        if [ -z "$from_commit" ] ; then
          read -ep 'Please enter a log description: ' log ;
          while [[ $log = *"$char_separator"* ]] || [[ $log = *"$str_bisector"* ]]; do
            read -ep 'That is not a valid input, please enter another description: ' log ;
          done
        fi

        log_ID=$[$(tail -1 $dir_log$file_log_IDs) + 1] ; echo "$log_ID" >> "$dir_log$file_log_IDs" ;
        log_save_dir="$dir_log$dir_log_prefix$log_ID"
        date_created_comp=$(date +"%s") ;
        date_created_human=$(date --date="@$date_created_comp") ;
        curr_pwd=$(pwd) ;
        cd $dir_log ; mkdir $log_save_dir ; cd $log_save_dir ; touch $file_log ;

        if [ $[${#array_files[@]} + ${#array_dirs[@]}] -gt "0" ] ; then
          for i in "${array_files[@]}" ; do
            cp "$curr_pwd/$i" . ;
          done
          for i in "${array_dirs[@]}" ; do
            cp -r "$curr_pwd/$i" . ;
          done
        fi

        # Output log information.
        echo "ID            $char_separator $log_ID" >> $file_log ;
        echo "description   $char_separator $log" >> $file_log ;
        echo "created human $char_separator $date_created_human" >> $file_log ;
        echo "created Epoch $char_separator $date_created_comp" >> $file_log ;

        # Files.
        for i in "${array_files[@]}" ; do echo "  file $char_separator $i" >> $file_log ; done ;

        # Directories.
        for i in "${array_dirs[@]}" ; do echo "  dir  $char_separator $i" >> $file_log ; done ;
        echo "Number $log_ID log created." >> $file_output ;

        log_save $log_ID "$log" $date_created_comp ;
      ;;

      "list"|"" )
        if [[ $[$3] = $3 ]] || [ -z $3 ] ; then
          if [ -z "$3" ] ; then
            sec_ago=$[1] ;
          else
            sec_ago=$[$3]
          fi
          case $4 in
            s|sec|secs|second|seconds )
              unit="second" ;
            ;;
            m|min|mins|minute|minutes )
              sec_ago=$[$sec_ago * 60] ;
              unit="minute" ;
            ;;
            h|hr|hrs|hour|hours )
              sec_ago=$[$sec_ago * 60 * 60] ;
              unit="hour" ;
            ;;
            d|day|days )
              sec_ago=$[$sec_ago * 60 * 60 * 24] ;
              unit="day" ;
            ;;
            w|wk|week|weeks|"" )
              sec_ago=$[$sec_ago * 60 * 60 * 168] ;
              unit="week" ;
            ;;
            mon|month|months )
              sec_ago=$[$sec_ago * 60 * 60 * 24 * 31] ;
              unit="month" ;
            ;;
            y|yr|yrs|year|years )
              sec_ago=$[$sec_ago * 60 * 60 * 24 * 365] ;
              unit="year" ;
            ;;
            * )
              echo "Not a valid time option, please use seconds, minutes, hours, days, weeks, months or years." >> $file_output ;
          esac

          cd $dir_log ;
          arr_dirs=( $(ls -v) ) ;

          if [ -z "$3" ] ; then
            echo "Logs in the past week." >> $file_output ;
          else
            echo "Logs in the past $3 $unit(s)." >> $file_output ;
          fi

          log_count=$[0] ;
          for log_dir in "${arr_dirs[@]}" ; do
            if [[ $log_dir = "$dir_log_prefix"* ]] ; then
              cd $log_dir ;
                date_created_comp=$(get_attribute $file_log "^created Epoch") ;
                if [ $[$(date "+%s") - $sec_ago] -le $date_created_comp ] ; then
                  log_count=$[$log_count + 1] ;
                  echo >> $file_output ;

                  log_ID=$(get_attribute $file_log "^ID") ;
                  log=$(get_attribute $file_log "^description") ;
                  date_created_human=$(get_attribute $file_log "^created human") ;

                  arr_files=() ; arr_dirs=() ;
                  for j in * ; do
                    if [ "$j" != "$file_log" ] ; then
                      if [ -f "$j" ] ; then
                        arr_files+=( "$j" ) ;
                      elif [ -d "$j" ] ; then
                        arr_dirs+=( "$j" ) ;
                      fi
                    fi
                  done

                  echo -e "\e[${format_log};${col_fore_log};${col_back_log}mlog $log_ID\e[0m \e[${format_date};${col_fore_date};${col_back_date}m$date_created_human\e[0m" >> $file_output ;
                  echo "  $log" >> $file_output ;
                  if [ "${#arr_dirs[@]}" -gt "0" ] ; then
                    for j in "${arr_dirs[@]}" ; do
                      echo -e "  dir  $char_separator \e[${format_dir};${col_fore_dir};${col_back_dir}m${j}\e[0m" >> $file_output ;
                    done ;
                  fi
                  if [ "${#arr_files[@]}" -gt "0" ] ; then
                    for j in "${arr_files[@]}" ; do
                      echo "  file $char_separator ${j}" >> $file_output ;
                    done
                  fi
                  echo >> $file_output ;
                fi
              cd ../ ;
            fi
          done
          if [ "$log_count" == "0" ] ; then
            > $file_output ;
            if [ -z "$3" ] ; then
              echo "There are no logs in the past week." >> $file_output ;
            else
              echo "There are no logs in the past $3 $unit(s)." >> $file_output ;
            fi
          fi
        else
          echo "Please supply input as an integer only." >> $file_output ;
        fi
      ;;

      "get" ) # Retrieves files and directories saved for a specific log.

        if [ -z $3 ] ; then
          echo "Please supply a log number to get." >> $file_output ;
        else
          if [[ $[$3] != $3 ]] ; then
            echo "Please supply the log number as an integer only." >> $file_output ;
          else
            log_save_dir="$(pwd)/$dir_log_save_prefix$dir_log_prefix$3"
            log_dir="$dir_log/$dir_log_prefix$3" ;

            if [ -d $log_dir ] ; then
              num_files=$[$(ls -1 $log_dir | wc -l)-1] ;
              if [ "$num_files" -gt "0" ] ; then
                cp -r $log_dir $log_save_dir ; #./$dir_log_save_prefix$dir_log_prefix$3 ;
                echo "Files and directories for log $3 retrieved in directory $log_save_dir." >> $file_output ;
              else
                echo "No files or directories entered for log $3." >> $file_output ;
              fi
            else
              echo "Log $3 does not exist." >> $file_output ;
            fi

          fi
        fi

      ;;

      * )
        echo "Not a valid log option. Please use add, list or get." >> $file_output ;
      ;;
    esac
  ;;



###########################################
###               HISTORY               ###
###########################################
  "history" )
    if [ -d $dir_contents ] ; then
      cd $dir_contents/$dir_history ;
        num_history=$(ls . | grep "^$file_history_prefix" | wc -l) ;

        if [ "$num_history" -gt "0" ] ; then
          #for ((i=1;i<=num_history;i++)) ; do
          history_files=( $(ls -v) ) ;
          for history_file in ${history_files[@]} ; do
            if [ "$history_file" != "$file_history_IDs" ] ; then
              #history_file="$file_history_prefix$i" ;
              history_ID=$(get_attribute $history_file "^ID") ;
              history_description=$(get_attribute $history_file "^description") ;
              date_created_human=$(get_attribute $history_file "^created human") ;

              echo -e "\e[${format_history};${col_fore_history};${col_back_history}mhistory $history_ID\e[0m" >> $file_output ;
              echo "  desc    $char_separator $history_description" >> $file_output ;
              echo "  created $char_separator $date_created_human" >> $file_output ;
              echo >> $file_output ;
            fi
          done
        else
          echo "There is no history for this project." >> $file_output ;
        fi
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###               REMOVE                ###
###########################################
  "remove" )
    if [ -d $dir_contents ] ; then
      bash $script_this_script --suppress save
      proj_ID=$(get_attribute $dir_contents/$file_info "^ID") ;

      cd $dir_contents/$dir_history ;
        date_created_comp=$(date +"%s") ;
        history_save remove $date_created_comp ;
      cd ../../ ;

      mv $dir_contents $dir_proj_backups/$proj_ID ;
      echo "Back up of project saved to $dir_proj_backups" >> $file_output ;
    else
      echo $err_dir_not_proj >> $file_output ;
    fi
  ;;



###########################################
###                 EE                  ###
###########################################
  * )
    echo 'Incorrect option supplied. Please use "work help" for help.' >> $file_output ;
  ;;
esac




$no_suppress && cat "$file_output" ;
> "$file_output" ;

#[[ $# != 0 ]] && echo >> "$file_output" && echo "Ignored $# argument(s): $@" >> "$file_output"

# Post cat commands.
case $1 in
  "startup" )

  until [[ $accepted = "print_"* ]] ; do
    read -ep 'Would you like to see your active projects? ' response ;
    case "${response,,}" in
      yes|yesh|yeh|yep|y|ya|yh|ye|yea|yeep|yees|yis|yiss|yeepy|yeepies|yas|yass|yeah|true|positive|affirm|affirmative|alright|"go on then"|"go on"|fine|fineeeeeee|jagshemash)
        accepted="print_true"
      ;;

      no|nah|n|nope|noh|nein|yesbutno|yeetnt|nooooooooooo|noo|narp|negative|false|incorrect|incorrection|"definitely not"|"go away"|cba|bye)
        accepted="print_false"
      ;;

      *)
        accepted=""
      ;;
    esac
  done

  if [[ $accepted = "print_true" ]] ; then
    bash $script_this_script summary ;
  fi
  echo ;
  ;;
esac

