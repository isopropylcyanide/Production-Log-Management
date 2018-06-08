# Production log filter script #
### Shell script to monitor production server logs and store the result in a file. ###
- - - -

#### Motivation: ####
    To automate the monotonous task of monitoring the logs from a production/test server. 
    SSHing into the remote server eats up valuable time and resources
    Basic commands such as df, top, etc can be easily appended to the script.
    Filtering of logs using sed, awk and grep to only get the required information.
    

This project consistd of two scripts each of which takes in appropriate arguments as denoted by its usage pattern.

- - - -

### prod-monitoring.sh ###
```
$ ./prod-monitor.sh [-u user] [-p pwd] [-f force-refresh] [-l logs-per-day] [- m month] [-d date] [-y year]
   
# * -u user: user having access to the prod system
# * -p passwd: passwd of the user having access to the prod system
# * -f force-refresh: specify if logs have to be pulled from scratch
# * -l maxLogsPerDay: How many logs do you need per day
# * -m month: Month for which logs need
# * -d date: date for which logs need to be created in the given month
# * -y year: Year for which logs need to be created
```
- - - -

 ### Usage scenarios ###
 *To fetch logs for Jun 7*
 ```
 $ ./prod-monitor.sh -d 5 -m Jun
     ******************
     Production log monitor script started
     Admin user: sn470454
     Monitor server: c0001413.prod.cloud.fedex.com
     Monitor directory: /var/fedex/por/logs/weblogic/por_c0001413.log
     Log month: Jun/2018
     Log date: 5
     Logs requested per day: 2
     ******************

     System up and running as of Fri Jun  8 07:44:07 GMT 2018

     Reusing previous logs. Force flag disabled
     Displaying log results
     Checking logs for Jun 5 
     ******************
     Jun 5, 2018 9:50:11 AM GMT	20% of the total memory in the server is free. 
     Jun 5, 2018 3:33:11 PM GMT	75% of the total memory in the server is free. 
     Size of /opt/fedex: 55%
     Size of /var/fedex: 57%
     CPU Usage as reported on the server: 0%
     ******************
 ```
 
 *To fetch logs for entire Jun given the current date is 7th June*
 ```
 $ ./prod-monitor-filter.sh -m Jun 

     Checking logs for Jun 2018 uptil current date
     ******************
     Logs already filled for Jun 1,
     ******************
     Logs already filled for Jun 2,
     ******************
     Logs already filled for Jun 3,
     ******************
     Logs already filled for Jun 4,
     ******************
     Logs already filled for Jun 5,
     ******************
     Logs already filled for Jun 6,
     ******************
     Logs already filled for Jun 7,
     ******************
 ```
 
 
 
