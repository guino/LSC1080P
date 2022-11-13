#!/bin/sh

# Check if port 8080 is open (http after script is executed)
IP=$1
timeout 1 telnet $IP 8080 >& /dev/null
# Port not open (refused connection), run script
if [ $? -eq 1 ]; then
 ( sleep 1; echo "root"; sleep 1; echo "dgiot010"; sleep 1; echo "/mnt/hack.sh"; sleep 1; echo "exit" ) | telnet $IP >& /dev/null
 if [ $? -eq 0 ]; then
  echo "Initialized!"
  exit 0
 else
  echo "Initialization failed!"
  exit 1
 fi
else
 echo "Already initialized (or disconnected)."
 exit 2
fi
