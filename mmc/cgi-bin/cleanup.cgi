#!/bin/sh
echo -e "Content-type: text/plain\r"
echo -e "\r"
DAYS=90
YEAR=$(date +%Y)
/mnt/busybox find /mnt/DCIM/$YEAR/ -type d -mtime +$DAYS -exec echo rm -rf {} \; -exec rm -rf {} \;
YEAR=$((YEAR-1))
if [ -e /mnt/DCIM/$YEAR/ ]; then
 /mnt/busybox find /mnt/DCIM/$YEAR/ -type d -mtime +$DAYS -exec echo rm -rf {} \; -exec rm -rf {} \;
fi
