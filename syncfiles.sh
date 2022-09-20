#!/bin/bash

SOURCE_DIRECTORY=/var/usb/data/
MOUNT_PATH=$1
PID_FILE=/var/run/syncfiles.pid

if test -f "$PID_FILE"
then
	echo "Another sync process running, exiting."
    exit 1
fi

full_sync () {
  echo "full sync"
}

targeted_sync () {
  rsync -ac --delete "${SOURCE_DIRECTORY}" $MOUNT_PATH
}

main () {

	if [ -z ${MOUNT_PATH} ]
	then
	    full_sync
	else
	    targeted_sync
	fi
}

main

#rm /var/run/syncfiles.pid
