#!/usr/bin/env bash

# PRODUCTION MONITORING SHELL SCRIPT
# Author: Aman Garg
# First release: 05 Jun 2018
# Shell script to monitor production server logs and store the result in a file 
# It scps the file to a temporary directory. Based on the action of commands that are stored in another actionfile,
# the results are generated. An action could be as anwehere from grep, mv, cp to dd
# Usage:
#  $ ./prod-monitor.sh [-u user] [-p passwd] [-f force-refresh] [-l maxLogsPerDay] [- m month] [-d date] [-y year] [-p prod-log-file-local]

# * user: user having access to the prod system
# * passwd: passwd of the user having access to the prod system
# * force-refresh: specify if logs have to be pulled from scratch
# * maxLogsPerDay: How many logs do you need per day
# * month: Month for which logs need
# * date: date for which logs need to be created in the given month
# * year: Year for which logs need to be created
# * prod-log-file-local: local copy of the latest prod logs
PROD_LOG_FILE='por_c0001413.log'
PROD_ACCESS_USERNAME="sn470454"
PROD_ACCESS_PWD="SkSkSk88"

# Default prod settings if no positional arguments are supplied
PROD_URL='c0001413.prod.cloud.fedex.com'
PROD_LOG_DIR='/var/fedex/por/logs/weblogic'

# temp directory to hold the log
PROD_LOG_TMP_DIR='tmp'
LOCAL_LOG_TMP_DIR='log'
FORCE_REFRESH='0'
IS_DATE_SET='0'
MAX_LOGS_PER_DAY='2'
CUR_MONTH=` date | awk '{print \$2}' | sed 's/,//' `
CUR_DATE_MONTH=` date | awk '{print \$3}' | sed 's/,//' `
CUR_YEAR=`date | awk '{print \$4}' | sed 's/,//' `
PROD_LOG_FILE_LOCAL=$PROD_LOG_TMP_DIR/$PROD_LOG_FILE
LOG_LOCAL_HISTORY_FILE="$LOCAL_LOG_TMP_DIR/archived-$CUR_MONTH-$CUR_YEAR.log"

# Helpful indication for the user to use the script properly
# -u user
# -p passwd
# -f force refresh
# -l max logs per day
# -d date
# -m month
# -y year
# -h help
function usage(){
    echo -e "Usage: $0 [-u <username:string>] [-p <passwd:string>] [-f <force-refresh:1/0>] [-l <maxlogs-per-day:number>] [-m <month:number>] [-d <date:number>] " 
    echo -e " [-y <year:number>]"
    exit 1;
}
# Parse for the  getopt
while getopts ":u:p:f:l:m:d:y:h" opt; do
  case $opt in
    u)
        PROD_ACCESS_USERNAME=${OPTARG};;
    p)
        PROD_ACCESS_PWD=${OPTARG};;
    f)
        FORCE_REFRESH=${OPTARG};;
    l)
        MAX_LOGS_PER_DAY=${OPTARG};;
    m)
        CUR_MONTH=${OPTARG}
        LOG_LOCAL_HISTORY_FILE="$LOCAL_LOG_TMP_DIR/archived-$CUR_MONTH-$CUR_YEAR.log";;
    d)
        CUR_DATE_MONTH=${OPTARG}
        LOG_LOCAL_HISTORY_FILE="$LOCAL_LOG_TMP_DIR/archived-$CUR_MONTH-$CUR_YEAR.log"
        IS_DATE_SET='1';;
    y)
        CUR_YEAR=${OPTARG};;
    h)
        usage;;
    \?)
        echo -e "Invalid argument specified."
        echo -e "Type $0 -h to view help"
        exit 1;;
  esac
done

echo -e " *******************************"
echo -e " Production log monitor script started"
echo " Admin user: $PROD_ACCESS_USERNAME"
echo " Monitor server: $PROD_URL"
echo " Monitor directory: $PROD_LOG_DIR/$PROD_LOG_FILE"
echo " Log month: $CUR_MONTH/$CUR_YEAR"
[[ $IS_DATE_SET -eq '0' ]] && echo " Log date not set. Showing for entire month so far" || echo " Log date: $CUR_DATE_MONTH"
echo " Logs requested per day: $MAX_LOGS_PER_DAY"
echo -e " *******************************\n"

# If this dir exists, then a log is in process. 
if [ -d $PROD_LOG_TMP_DIR ]
    then
        if [ ! $FORCE_REFRESH == '0' ]
            then
                echo " Force refresh enabled! Log file will be newly created" 
                rm -rf $PROD_LOG_TMP_DIR
                echo -e " Cleaning directory $PROD_LOG_TMP_DIR"
                mkdir -p $PROD_LOG_TMP_DIR
                echo -e " Created $PROD_LOG_TMP_DIR directory\n"
        fi
    else
        echo -e " No previous running instance of the script found."
        mkdir -p $PROD_LOG_TMP_DIR
        echo -e " Created tmp directory\n"
fi

# Get current date and timm
SYSTEM_DATE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL date 2>&1)
echo -e " System up and running as of $SYSTEM_DATE\n"

# SCP the directory to /tmp/file
if [ ! $FORCE_REFRESH == '0' ]
    then
        echo -e " Trying to scp log file into the output log directory"
        sshpass -p $PROD_ACCESS_PWD scp -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL:$PROD_LOG_DIR/$PROD_LOG_FILE $PROD_LOG_TMP_DIR
        echo -e " Successfully downloaded the log file\n"
    else   
        echo -e " Reusing previous logs. Force flag disabled"
fi

# Call the log script and pipe the output to a variable
if [ ! $IS_DATE_SET -eq '1' ]
    then
        FORMATTED_LOG_VALUE="$(bash prod-monitor-filter.sh -l $MAX_LOGS_PER_DAY -m $CUR_MONTH -y $CUR_YEAR -e $PROD_LOG_FILE_LOCAL)"
        echo -e "$FORMATTED_LOG_VALUE" >> $LOG_LOCAL_HISTORY_FILE
    else
        FORMATTED_LOG_VALUE="$(bash prod-monitor-filter.sh -l $MAX_LOGS_PER_DAY -m $CUR_MONTH -d $CUR_DATE_MONTH -y $CUR_YEAR -e $PROD_LOG_FILE_LOCAL)"
        echo -e "$FORMATTED_LOG_VALUE" >> $LOG_LOCAL_HISTORY_FILE
fi
echo -e " Displaying log results " 
echo -e "$FORMATTED_LOG_VALUE"

# Report the size of /opt/fedex
OPT_FEDEX_DIR='/opt/fedex'
OPT_FEDEX_SIZE_CMD=" df -h  $OPT_FEDEX_DIR | awk NR==3 | awk '{print \$4}' "
OPT_FEDEX_SIZE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL $OPT_FEDEX_SIZE_CMD 2>&1)
echo -e " Size of $OPT_FEDEX_DIR: $OPT_FEDEX_SIZE"
echo -e " Size of $OPT_FEDEX_DIR: $OPT_FEDEX_SIZE" >> $LOG_LOCAL_HISTORY_FILE

# Report the size of /var/fedex
VAR_FEDEX_DIR='/var/fedex'
VAR_FEDEX_SIZE_CMD=" df -h  $VAR_FEDEX_DIR | awk NR==3 | awk '{print \$4}' "
VAR_FEDEX_SIZE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL $VAR_FEDEX_SIZE_CMD 2>&1)
echo -e " Size of $VAR_FEDEX_DIR: $VAR_FEDEX_SIZE"
echo -e " Size of $VAR_FEDEX_DIR: $VAR_FEDEX_SIZE" >> $LOG_LOCAL_HISTORY_FILE

# Report the cpu used by the process java
CPU_USAGE_CMD=" top -b -n2 | grep java | tail -n 1 | awk '{print \$9}' "
CPU_USAGE=$(sshpass -p $PROD_ACCESS_PWD ssh -o StrictHostKeyChecking=no $PROD_ACCESS_USERNAME@$PROD_URL $CPU_USAGE_CMD 2>&1)
echo -e " CPU Usage as reported on the server: $CPU_USAGE%\n"
echo -e " CPU Usage as reported on the server: $CPU_USAGE%\n"  >> $LOG_LOCAL_HISTORY_FILE


