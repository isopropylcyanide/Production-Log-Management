#!/usr/bin/env bash

# <description>
#
# Usage:
#  $ ./prod-monitor-filter [- l maxLogsPerDay] [- m month] [-d date] [-y year] [-p prod-log-file-local]
# * maxLogsPerDay: How many logs do you need per day
# * month: Month for which logs need
# * date: date for which logs need to be created in the given month
# * year: Year for which logs need to be created
# * prod-log-file-local: local copy of the latest prod logs

# Find current date, month and time, if not passed in as params.
MAX_LOGS_PER_DAY='2'
CUR_MONTH=` date | awk '{print \$2}' | sed 's/,//' `
CUR_DATE_MONTH=` date | awk '{print \$3}' | sed 's/,//' `
IS_DATE_SET='0'
CUR_YEAR=`date | awk '{print \$4}' | sed 's/,//' `
PROD_LOG_FILE='tmp/por_c0001413.log'
LOG_LOCAL_HISTORY_FILE="archived-$CUR_MONTH-$CUR_YEAR.log"

# Helpful indication for the user to use the script properly
# -l log
# -d date
# -m month
# -y year
# -p prod
function usage(){
    echo -e "Usage: $0 [-l <maxlogs-per-day:number>] [-m <month:number>] [-d <date:number>] " 
    echo -e " [-y <year:number>] [-p <log-file:string>] "
    exit 1;
}

# Parse for the  getopt
while getopts ":l:m:d:y:p" opt; do
  case $opt in
    l)
        MAX_LOGS_PER_DAY=${OPTARG}
      ;;
    m)
        CUR_MONTH=${OPTARG}
      ;;
    d)
        CUR_DATE_MONTH=${OPTARG}
        IS_DATE_SET=1
      ;;
    y)
        CUR_YEAR=${OPTARG}
      ;;
    p)
        PROD_LOG_FILE=${OPTARG}
      ;;
    \?)
      usage
      ;;
  esac
done

   
# Get max number of days for a month: $1
function getmaxDaysForMonth(){
    _MONTH=$1
    case $_MONTH in
        "Jan") MONTH_NO=1 ;;
        "Feb") MONTH_NO=2 ;;
        "Mar") MONTH_NO=3 ;;
        "Apr") MONTH_NO=4 ;;
        "May") MONTH_NO=5 ;;
        "Jun") MONTH_NO=6 ;;
        "Jul") MONTH_NO=7 ;;
        "Aug") MONTH_NO=8 ;;
        "Sep") MONTH_NO=9 ;;
        "Oct") MONTH_NO=10 ;;
        "Nov") MONTH_NO=11 ;;
        "Dec") MONTH_NO=12 ;;
        *) MONTH_NO=2 ;;
    esac
    echo  `date -d "$MONTH_NO/1 + 1 month - 1 day" "+%d"`
}

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
            # echo -e " Need to fetch $LEFTOVER_LOG_COUNT more log/s for $MONTH_DATE_TEXT"
            # fetch all health logs from prod logs by date
            fetchDesiredNumberOfLogsFromProd $LEFTOVER_LOG_COUNT "$MONTH_DATE_TEXT"
    fi
}


# CRUX OF The APPLICATION: MODIFY the log return Algorithm to persist data as reqd
# Fetch desired number of logs: $1 matching the text: $2
# Get both logs in AM/PM with priority of PM over AM if only one is required
function fetchDesiredNumberOfLogsFromProd(){
    _REQ_LOGS=$1
    _MONTH_DATE_TEXT=$2
    AM_LOG_COUNT=`expr $_REQ_LOGS / 2`
    PM_LOG_COUNT=`expr $_REQ_LOGS - $AM_LOG_COUNT`
    AM_LOGS=`cat $PROD_LOG_FILE | grep -i ".*$_MONTH_DATE_TEXT.*<Info> <Health>" | sed -rn "s/.*($_MONTH_DATE_TEXT.*AM GMT).*<([0-9]+.*)>/\1\t\2/p" | shuf -n $AM_LOG_COUNT`
    PM_LOGS=`cat $PROD_LOG_FILE | grep -i ".*$_MONTH_DATE_TEXT.*<Info> <Health>" | sed -rn "s/.*($_MONTH_DATE_TEXT.*PM GMT).*<([0-9]+.*)>/\1\t\2/p" | shuf -n $PM_LOG_COUNT`
    echo -e " $AM_LOGS\n $PM_LOGS\n"
}

# Fetch logs for a particular month:$1
# If month specified has occured before, loop till the entirety of its days
function fetchLogsForMonth(){
    _MONTH=$1
    _ACTUAL_CUR_MONTH=`date | awk '{print \$2}' | sed 's/,//' `
    if [ $_ACTUAL_CUR_MONTH == $CUR_MONTH ]
        then
            _DATE_TO_LOOP="$CUR_DATE_MONTH" 
        else
            _DATE_TO_LOOP=$(getmaxDaysForMonth "$CUR_MONTH")
    fi

    if [ $IS_DATE_SET -eq '0' ]
        then
            echo -e " Checking logs for $_MONTH $CUR_YEAR uptil current date"
            echo -e "******************"
            for i in $(seq 1 $_DATE_TO_LOOP)
                do
                    fetchLogsForDate $_MONTH $i
                echo -e "******************"
            done
    else    
        echo -e " Checking logs for $_MONTH $CUR_DATE_MONTH $CUR_YEAR"
        echo -e "******************"
        fetchLogsForDate $_MONTH $CUR_DATE_MONTH
    fi
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