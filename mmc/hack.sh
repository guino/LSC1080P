#!/bin/sh

# Only run once
if [ ! -e /tmp/hack ]; then
 touch /tmp/hack
 # Is dgiot already running ?
 DGIOT=$(/mnt/busybox pidof dgiot)
 # If not running (modified flash), run it
 if [ "$DGIOT" == "" ]; then
  cd /usr/bin
  ./daemon&
  if [ -e /mnt/dgiot ]; then
   cd /mnt
  fi
  ./dgiot&
 fi
 # Run custom.sh on SD card every 10 seconds (like we do on other devices)
 (while true; do /mnt/custom.sh; sleep 10; done ) < /dev/null >& /dev/null &
fi
# Return 0 if we have a custom dgiot (so app_init.sh in firmware doesn't run it again)
if [ -e /mnt/dgiot ]; then
 exit 0
fi
# Return 1 so app_init.sh in firmware runs the firmware version of dgiot
exit 1
# Exit codes are ignored when starting tools from telnet
