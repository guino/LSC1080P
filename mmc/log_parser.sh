#!/bin/sh

#DEBUG_FILE=/mnt/output.log
DEBUG_FILE=$1

# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

main() {
    IFS='$\n'
    echo -n "" > $DEBUG_FILE
    while true; do
        read -r BUF;
        if [ $? -ne 0 ]; then
            sleep 1;
            continue
        fi
        if contains "$BUF" "---do record"; then
	    if [ ! -e /tmp/motion ]; then
		touch /tmp/motion
                #echo "motion detected"
                /mnt/mqtt_pub 10.10.10.92 1883 home/doorbell detected
	    fi
        elif contains "$BUF" "---clear record"; then
            #echo "motion stopped"
            rm -f /tmp/motion
        #else
            #echo "Unknown cmd: $BUF"
        fi
        echo $BUF >> $DEBUG_FILE
    done
}

main
