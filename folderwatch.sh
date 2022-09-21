#!/bin/bash
while inotifywait -qq -r --exclude '.*\.part' -e moved_to -e create -e delete /var/usb/data/
do
	echo "Changes detected syncing USBs" | tee /dev/kmsg
	/usr/local/bin/syncfiles.sh
done
