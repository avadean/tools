#!/bin/bash

dir_drive="/media/dean/Seagate Expansion Drive/backups/" # Directory in hard drive that is used for backing up.
dir_to_backup="/home/dean"                               # Directory that will be backed up.
dir_backup_logs="/home/dean/tools/backup_files/"         # Directory where backup files and logs are stored.
file_log="/home/dean/tools/backup_files/backup.log"      # General log of all backups.

d_s=$(date +"%Y%m%d") ;                                  # Date in format: 20200321 meaning 21st March 2020.
dir_destination="$dir_drive$d_s"                         # Destination of backup.
dry_run_log="$dir_backup_logs$d_s"                       # Specific log of current day's backups.

# Check log files exist.
[ ! -d "$dir_backup_logs" ] && touch "/home/dean/BACKUP_FAILED_$d_s" && exit 1 ;
[ ! -f "$file_log" ] && touch "/home/dean/BACKUP_FAILED_$d_s" && exit 1 ;

# Initialise backup.
echo "$(date +"%Y/%m/%d %H:%M:%S") - initialising backup of $dir_to_backup to $dir_destination." >> $file_log ;

# Check directories exist.
[ ! -d "$dir_drive" ] && echo "$(date +"%Y/%m/%d %H:%M:%S") - could not find back up directory $dir_drive." >> $file_log && exit 1 ;
[ ! -d "$dir_to_backup" ] && echo "$(date +"%Y/%m/%d %H:%M:%S") - could not find directory to back up $dir_to_backup." >> $file_log && exit 1 ;

# Make directory in backup location.
mkdir "$dir_destination" ;
# If the directory failed to be created then make a note in the general log and exit.
if [ $? -ne 0 ] ; then
    echo "$(date +"%Y/%m/%d %H:%M:%S") - error when creating $dir_destination in $dir_drive." >> $file_log ;
    exit 1 ;
else
    echo "$(date +"%Y/%m/%d %H:%M:%S") - successfully created $dir_destination in $dir_drive." >> $file_log ;
fi

# Do a dry run of the sync, this will verbosely output what will be copied to the daily log.
echo "$(date +"%Y/%m/%d %H:%M:%S")" >> "$dry_run_log" ;
rsync -avn "$dir_to_backup" "$dir_destination" >> "$dry_run_log" ;
if [ $? -ne 0 ] ; then
    # If the dry run failed then make a note in the specific and general logs and exit.
    echo "ERROR." >> "$dry_run_log" ;
    echo "$(date +"%Y/%m/%d %H:%M:%S") - error in dry run of rsync for $dir_to_backup to $dir_drive." >> $file_log ;
    exit 1 ;
else
    # If multiple backups are ran per day then the verbose output will be separated.
    echo >> "$dry_run_log" ;
    echo >> "$dry_run_log" ;
    echo >> "$dry_run_log" ;
    echo >> "$dry_run_log" ;
    echo >> "$dry_run_log" ;
fi

# Main backup command.
rsync -a "$dir_to_backup" "$dir_destination" ;
if [ $? -ne 0 ] ; then
    # If the main backup command failed then make a note in the general log and exit.
    echo "$(date +"%Y/%m/%d %H:%M:%S") - error when rsyncing $dir_to_backup to $dir_drive." >> $file_log ;
    exit 1 ;
else
    # If all goes well then make a note in the general log and exit.
    echo "$(date +"%Y/%m/%d %H:%M:%S") - success rsyncing $dir_to_backup to $dir_drive." >> $file_log ;
    exit 0 ;
fi

