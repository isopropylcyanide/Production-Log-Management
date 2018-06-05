#!/usr/bin/env bash

# <description>
#
# Usage:
#  $ ./prod-monitor-filter [month] [year] [prod-log-file-local]
# * month: Month for which logs need
# * year: Year for which logs need to be created
# * prod-log-file-local: local copy of the latest prod logs

# Find current date, month and time
CUR_MONTH=${1:-` date | awk '{print \$2}' | sed 's/,//' `}
CUR_DATE_MONTH=` date | awk '{print \$3}' | sed 's/,//' `
CUR_YEAR=${2:-`date | awk '{print \$4}' | sed 's/,//' `}

echo "Checking log for $CUR_MONTH $CUR_YEAR"
PROD_LOG_FILE='tmp/por_c0001413.log'
LOG_LOCAL_HISTORY_FILE="archived-$CUR_MONTH-$CUR_YEAR.log"

# if current log doesn't exist, exit
if [ ! -f $PROD_LOG_FILE ]
    then
        echo "Prod log file $PROD_LOG_FILE is missing"
        exit 1
    else
        echo "Found prod log file at $PROD_LOG_FILE"
fi

# if history exists, good else create it
if [ -f $LOG_LOCAL_HISTORY_FILE ]
    then
        echo "Local log present. Further logs will be appended"
    else
        echo "Local log archive absent. Creating $LOG_LOCAL_HISTORY_FILE"
        touch $LOG_LOCAL_HISTORY_FILE
fi

exit