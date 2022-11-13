#!/bin/sh
if [ ! -e /tmp/customrun ]; then
 echo custom > /tmp/customrun
 mnt/busybox httpd -c /mnt/httpd.conf -h /mnt/ -p 8080
 if [ -e /mnt/log_parser.sh ]; then
  DGIOT=$(/mnt/busybox pidof dgiot)
  /mnt/busybox mkfifo /tmp/log
  /mnt/reredirect -m /tmp/log $DGIOT > /tmp/redir.log
  /mnt/log_parser.sh /dev/null < /tmp/log &
 fi
 #/mnt/offline.sh &
fi
if [ ! -e /tmp/cleanup`date +%Y%m%d` ]; then
 rm -rf /tmp/cleanup*
 touch /tmp/cleanup`date +%Y%m%d`
 /mnt/cgi-bin/cleanup.cgi > /tmp/cleanup.log
fi
