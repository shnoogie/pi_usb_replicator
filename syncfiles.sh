#!/bin/bash

SOURCE_DIRECTORY=/var/usb/data/
DEVICE_UUID=$1
PID_FILENAME="syncfiles"
PID_PATH=/var/run/
PID_FILE="${PID_PATH}${PID_FILENAME}.pid"

if test -f "$PID_FILE"
then
	echo "Another sync process running, exiting."
    exit 1
fi

full_sync () {
	# full sync stops all other syncs and runs a sync on every connected drive
	# check to see if a drive was connected at the end
	echo "full sync"
}

targeted_sync () {
	UUID_PID_FILE="${PID_FILENAME}_${DEVICE_UUID}.pid"

	if test -f "$UUID_PID_FILE"
	then
		echo "Another sync process running for ${DEVICE_UUID}, exiting."
    	exit 1
    elif test -f "$PID_FILE"
    then
    	echo "Another sync process running, exiting."
    	exit 1
	fi

	MOUNT_PATH="/media/${DEVICE_UUID}"
	echo "$$" > "${PID_PATH}syncfiles_${DEVICE_UUID}.pid"
	rsync -ac --delete "${SOURCE_DIRECTORY}" "${MOUNT_PATH}"

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

#rm /var/run/syncfiles.pid
