#!/bin/bash
#
# Deletes comments from host and services no longer in critical status.
#
# Author: Marco Ramos, <mramos@co.sapo.pt>
# Date: 24/03/2006
#

# Global Vars
NAGIOS_CMD='/usr/local/nagios/var/rw/nagios.cmd'
DOWNTIME_LOG='/usr/local/nagios/var/downtime.log'
SERVICES_STATUS='/usr/local/nagios/var/status.log'
COMMENTS_LOG='/usr/local/nagios/var/comment.log'
CURRENT_DATE=`/bin/date +%s`

GREP_CMD='/bin/grep'
AWK_CMD='/usr/bin/awk'
SORT_CMD='/usr/bin/sort'
UNIQ_CMD='/usr/bin/uniq'
ECHO_CMD='/bin/echo'
SLEEP_CMD='/bin/sleep'

# Remove no longer used host comments
HOST_COMMENTS=`$GREP_CMD HOST_COMMENT $COMMENTS_LOG | $AWK_CMD -F\; '{print $3}'`
for i in $HOST_COMMENTS
do
  x=`$GREP_CMD \;$i\; $SERVICES_STATUS | $GREP_CMD HOST | $AWK_CMD -F\; '{print $2}'`
  if [ ! -z $x ]
  then
    id=`$GREP_CMD HOST_COMMENT $COMMENTS_LOG | $GREP_CMD $i | $GREP_CMD -v "Nagios Process" | $AWK_CMD -F\; '{print $2}'`
    for j in $id
    do
      $ECHO_CMD "Removing host comment $j"
      $ECHO_CMD "[$CURRENT_DATE] DEL_HOST_COMMENT;$j" >> $NAGIOS_CMD
      $SLEEP_CMD 1
    done
  fi
done


# Remove service comments
SERVICE_COMMENTS=`$GREP_CMD SERVICE_COMMENT $COMMENTS_LOG | $AWK_CMD -F\; '{print $2}' | $SORT_CMD | $UNIQ_CMD`
for i in $SERVICE_COMMENTS
do
  host=`$GREP_CMD \;$i\; $COMMENTS_LOG | $AWK_CMD -F\; '{print $3}'`
  service=`$GREP_CMD \;$i\; $COMMENTS_LOG | $AWK_CMD -F\; '{print $4}'`
  x=`$GREP_CMD \;$host\; $SERVICES_STATUS | $GREP_CMD "\;$service\;" | $AWK_CMD -F\; '{print $4}'`
  if [ "$x" != "CRITICAL" ]
  then
    $ECHO_CMD "Removing comments on service $service of host $host"
    $ECHO_CMD "[$CURRENT_DATE] DEL_ALL_SVC_COMMENTS;$host;$service" >> $NAGIOS_CMD
    $SLEEP_CMD 1
  fi
done

