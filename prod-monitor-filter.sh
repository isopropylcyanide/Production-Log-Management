#!/usr/bin/env bash

# <description>
#
# Usage:
#  $ ./prod-monitor-filter [month] [year] [prod-log-file-local]
# * month: Month for which logs need
# * year: Year for which logs need to be created
# * prod-log-file-local: local copy of the latest prod logs

# Find current date, month and time, if not passed in as params.
CUR_MONTH=${1:-` date | awk '{print \$2}' | sed 's/,//' `}
CUR_DATE_MONTH=` date | awk '{print \$3}' | sed 's/,//' `
CUR_YEAR=${2:-`date | awk '{print \$4}' | sed 's/,//' `}
MAX_LOGS_PER_DAY='2'
PROD_LOG_FILE='tmp/por_c0001413.log'
LOG_LOCAL_HISTORY_FILE="archived-$CUR_MONTH-$CUR_YEAR.log"


# Fetch logs for a particular for month:$1 and date:$2 
# If the num instances is 0, fill two more logs preferably separated by 10 or more hours
# If the num instances is 1, fill one more logs preferably separated by 10 or more hours
# If the num instances is 2, continue
function fetchLogsForDate(){
    _MONTH=$1
    _DATE=$2
    MONTH_DATE_TEXT="$_MONTH $_DATE,"
    NUMINSTANCES=`grep -c "$MONTH_DATE_TEXT" $LOG_LOCAL_HISTORY_FILE`
    if [ $NUMINSTANCES -ge $MAX_LOGS_PER_DAY ]
        then
            echo " Logs already filled for $MONTH_DATE_TEXT"
    elif [ $NUMINSTANCES -lt $MAX_LOGS_PER_DAY ]
        then
            LEFTOVER_LOG_COUNT=`expr $MAX_LOGS_PER_DAY - $NUMINSTANCES`
            echo " Need to fetch $LEFTOVER_LOG_COUNT more log/s for $MONTH_DATE_TEXT"
            # fetch all health logs from prod logs by date
            echo `fetchDesiredNumberOfLogsFromProd $LEFTOVER_LOG_COUNT $MONTH_DATE_TEXT`
    fi
    echo ******************
    echo
}

# Fetch logs for a particular month:$1
function fetchLogsForMonth(){
    _MONTH=$1
    echo " Checking log for $_MONTH $CUR_YEAR"
    for i in $(seq 1 $CUR_DATE_MONTH)
    do
        fetchLogsForDate $_MONTH $i
    done
}

# Fetch desired number of logs: $1 matching the text: $2
function fetchDesiredNumberOfLogsFromProd(){
    _REQ_LOGS=$1
    _MONTH_DATE_TEXT=$2
    PENDING_LOGS=`cat $PROD_LOG_FILE | grep -i "$_MONTH_DATE_TEXT.*<Info> <Health>" | shuf -n $_REQ_LOGS`
    echo $PENDING_LOGS
}

# if current log doesn't exist, exit
if [ ! -f $PROD_LOG_FILE ]
    then
        echo " Prod log file $PROD_LOG_FILE is missing"
        exit 1
    else
        echo " Found prod log file at $PROD_LOG_FILE"
fi

# if history exists, good else create it
if [ -f $LOG_LOCAL_HISTORY_FILE ]
    then
        echo " Local log present. Further logs will be appended"
    else
        echo " Local log archive absent. Creating $LOG_LOCAL_HISTORY_FILE"
        touch $LOG_LOCAL_HISTORY_FILE
fi

# for each day of month m, i, from 1 till today, check the number of instances of m i

echo
fetchLogsForMonth $CUR_MONTH
exit