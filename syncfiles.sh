#!/bin/bash

SOURCE_DIRECTORY=/var/usb/data/
DEVICE_UUID=$1
PID_FILENAME="syncfiles"
PID_PATH=/var/run/
PID_FILE="${PID_PATH}${PID_FILENAME}.pid"
DEVICE_RE="/media/*"

echo "SYNC IN PROGRESS" | tee /dev/kmsg

if test -f "$PID_FILE"
then
	echo "Another sync process running, exiting." | tee /dev/kmsg
    exit 1
fi

full_sync () {
	echo "$$" > "$PID_FILE"

	for FILE in ${PID_PATH}${PID_RE}
	do
		if [ "${PID_PATH}${PID_RE}" != "$FILE" ]
		then
			RUNNING_PID=`cat "$FILE"`
			kill -n 9 $RUNNING_PID
			rm -f "$FILE"
			echo "Killed $FILE" | tee /dev/kmsg
		fi
	done

	for DEVICE in $DEVICE_RE; do
		if [ "$DEVICE_RE" != "$DEVICE" ]
		then
			echo "Running rsync on ${DEVICE}" | tee /dev/kmsg
			nohup rsync -ac --delete "${SOURCE_DIRECTORY}" "${DEVICE}" &
		fi
	done
	
	wait

	rm "$PID_FILE"
}

targeted_sync () {
    UUID_PID_FILE="${PID_PATH}${PID_FILENAME}_${DEVICE_UUID}.pid"
    MOUNT_PATH="/media/${DEVICE_UUID}"

    if test -f "$UUID_PID_FILE"
    then
	echo "Another sync process running for ${DEVICE_UUID}, exiting." | tee /dev/kmsg
    	exit 1
    elif test -f "$PID_FILE"
    then
    	echo "Another sync process running, exiting." | tee /dev/kmsg
    	exit 1
    fi

	echo "$$" > "$UUID_PID_FILE"
	rsync -ac --delete "${SOURCE_DIRECTORY}" "${MOUNT_PATH}"
	echo "Running targeted rsync on ${DEVICE_UUID}" | tee /dev/kmsg
	rm "${PID_PATH}${PID_FILENAME}_${DEVICE_UUID}.pid"
}

main () {
	if [ -z ${DEVICE_UUID} ]
	then
	    full_sync
	else
	    targeted_sync
	fi
}

main

echo "SYNC ENDED" | tee /dev/kmsg
