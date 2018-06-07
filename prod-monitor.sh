#!/usr/bin/env bash

# PRODUCTION MONITORING SHELL SCRIPT
# Author: Aman Garg
# First release: 05/06/2018
# Shell script to monitor production server logs and store the result in a file 
# It scps the file to a temporary directory. Based on the action of commands that are stored in another actionfile,
# the results are generated. An action could be as anwehere from grep, mv, cp to dd
# Usage:
#  $ ./prod-monitor.sh [user] [passwd] [logs-per-day] [month] [date] [year] 

# * user: user having access to the prod system
# * passwd: passwd of the user having access to the prod system
# * maxLogsPerDay: How many logs do you need per day
# * month: Month for which logs need
# * date: date for which logs need to be created in the given month
# * year: Year for which logs need to be created
PROD_LOG_FILE=${1:-'por_c0001413.log'}
PROD_ACCESS_USERNAME=${2:-"sn470454"}
PROD_ACCESS_PWD=${3:-"SkSkSk88"}

# Default prod settings if no positional arguments are supplied
PROD_URL=${4:-'c0001413.prod.cloud.fedex.com'}
PROD_LOG_DIR=${5:-'/var/fedex/por/logs/weblogic'}

# temp directory to hold the log
LOG_TMP_DIR='tmp'
FORCE_REFRESH='1'

# Parse for the  getopt
while getopts ":f" opt; do
  case $opt in
    f)
        FORCE_REFRESH='1'
      ;;
    \?)
      echo " Invalid option: -$OPTARG" 
      ;;
  esac
done

echo -e "\n **Prod monitor script started**"

echo " Admin user: $PROD_ACCESS_USERNAME"
echo " Monitor server: $PROD_URL"
echo " Monitor directory: $PROD_LOG_DIR/$PROD_LOG_FILE"
echo -e " *******************************\n"

# If this dir exists, then a log is in process. 
if [ -d $LOG_TMP_DIR ]
    then
        if [ ! $FORCE_REFRESH == '0' ]
            then
                echo " Force refresh enabled! Log file will be newly created" 
                rm -rf $LOG_TMP_DIR
                echo -e " Cleaning directory $LOG_TMP_DIR"
                mkdir -p $LOG_TMP_DIR
                echo -e " Created $LOG_TMP_DIR directory\n"
        fi
    else
        echo -e " No previous running instance of the script found."
        mkdir -p $LOG_TMP_DIR
        echo -e " Created tmp directory\n"
fi



# Get current date and timm
SYSTEM_DATE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL date 2>&1)
echo -e " System up and running as of $SYSTEM_DATE\n"

# SCP the directory to /tmp/file
if [ ! $FORCE_REFRESH == '0' ]
    then
        echo -e " Trying to scp log file into the output log directory"
        sshpass -p $PROD_ACCESS_PWD scp -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL:$PROD_LOG_DIR/$PROD_LOG_FILE $LOG_TMP_DIR
        echo -e " Successfully downloaded the log file\n"
    else   
        echo -e " Reusing previous logs. Force flag enabled"
fi

# Call the log script and pipe the output to a variable
FORMATTED_LOG_VALUE="$(bash prod-monitor-filter.sh)"
echo -e " Displaying log results " 
echo -e "$FORMATTED_LOG_VALUE"

# Report the size of /opt/fedex
OPT_FEDEX_DIR='/opt/fedex'
OPT_FEDEX_SIZE_CMD=" df -h  $OPT_FEDEX_DIR | awk NR==3 | awk '{print \$4}' "
OPT_FEDEX_SIZE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL $OPT_FEDEX_SIZE_CMD 2>&1)
echo -e " Size of $OPT_FEDEX_DIR: $OPT_FEDEX_SIZE"

# Report the size of /var/fedex
VAR_FEDEX_DIR='/var/fedex'
VAR_FEDEX_SIZE_CMD=" df -h  $VAR_FEDEX_DIR | awk NR==3 | awk '{print \$4}' "
VAR_FEDEX_SIZE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL $VAR_FEDEX_SIZE_CMD 2>&1)
echo -e " Size of $VAR_FEDEX_DIR: $VAR_FEDEX_SIZE"

# Report the cpu used by the process java
CPU_USAGE_CMD=" ps -p \$(pgrep java | awk NR==1) -o %cpu | awk NR==2 | awk '{print $1}' "
CPU_USAGE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL $CPU_USAGE_CMD 2>&1)
echo -e " CPU Usage as reported on the server: $CPU_USAGE%\n"


