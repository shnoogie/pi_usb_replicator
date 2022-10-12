#!/bin/bash

SOURCE_DIRECTORY=/var/usb/data/
MOUNT_FOLDER=$1
PID_FILENAME="syncfiles"
PID_PATH=/var/run/
PID_FILE="${PID_PATH}${PID_FILENAME}.pid"
DEVICE_RE="/media/*"
PID_RE=syncfiles_*.pid

echo "SYNC IN PROGRESS" | tee /dev/kmsg

if test -f "$PID_FILE"
then
	echo "Another sync process running, killing it." | tee /dev/kmsg
	RUNNING_PID=`cat "$PID_FILE"`
	pkill -P $RUNNING_PID
	rm -f $PID_FILE
fi

full_sync () {
	echo "$$" > "$PID_FILE"

	for FILE in ${PID_PATH}${PID_RE}
	do
		if [ "${PID_PATH}${PID_RE}" != "$FILE" ]
		then
			RUNNING_PID=`cat "$FILE"`
			pkill -P $RUNNING_PID
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
    UUID_PID_FILE="${PID_PATH}${PID_FILENAME}_${MOUNT_FOLDER}.pid"
    MOUNT_PATH="/media/${MOUNT_FOLDER}"

    if test -f "$UUID_PID_FILE"
    then
	echo "Another sync process running for ${MOUNT_FOLDER}, exiting." | tee /dev/kmsg
    	exit 1
   # elif test -f "$PID_FILE"
   # then
   # 	echo "Another sync process running, exiting." | tee /dev/kmsg
   # 	exit 1
    fi

	echo "$$" > "$UUID_PID_FILE"
	rsync -ac --delete "${SOURCE_DIRECTORY}" "${MOUNT_PATH}"
	echo "Running targeted rsync on ${MOUNT_FOLDER}" | tee /dev/kmsg
	rm "${PID_PATH}${PID_FILENAME}_${MOUNT_FOLDER}.pid"
}

main () {
	if [ -z ${MOUNT_FOLDER} ]
	then
	    full_sync
	else
	    targeted_sync
	fi
}

main


if ! test -f "$PID_FILE"
then
	echo "SYNC ENDED" | tee /dev/kmsg
fi
