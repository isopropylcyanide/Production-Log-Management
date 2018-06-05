#!/usr/bin/env bash

# PRODUCTION MONITORING SHELL SCRIPT
# Author: Aman Garg
# First release: 05/06/2018
# Shell script to monitor production server logs and store the result in a file 
# It scps the file to a temporary directory. Based on the action of commands that are stored in another actionfile,
# the results are generated. An action could be as anwehere from grep, mv, cp to dd
# Usage:
#  $ ./prod-monitor.sh param1 param2
# * param1: url of the prod server which is to be monitored
# * param2: absolute path of the log file used to generate results
PROD_ACCESS_USERNAME="sn470454"
PROD_ACCESS_PWD="SkSkSk88"

PROD_URL='c0001413.prod.cloud.fedex.com'
PROD_LOG_FILE_DIR='/var/fedex/por/logs/weblogic'
PROD_LOG_FILE="por_c0001413.log"

# temp directory to hold the log
LOG_TMP_DIR='tmp'

echo -e "\n **Prod monitor script started**\n"

# If this dir exists, then a log is in process. Clean it to continue
if [ -d $LOG_TMP_DIR ]
    then
        echo -e " Previous instance found. Clean directory $LOG_TMP_DIR to continue"
        echo -e " Exiting\n"
        # exit 1
    else
        echo -e " No previous running instance of the script found. Continuing\n"
fi

# SCP the directory to /tmp/file
echo -e " Trying to scp log file into the output log directory"
scp $PROD_ACCESS_USERNAME@$PROD_URL:$PROD_LOG_FILE_DIR/$PROD_LOG_FILE $LOG_TMP_DIR
