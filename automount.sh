#!/bin/bash

# Add ignore for EFI and Small Mount Points

PART=$1
FS_LABEL=`lsblk -o name,label | grep ${PART} | awk '{print $2}'`
UUID=`lsblk -o name,uuid | grep ${PART} | awk '{print $2}'`

mkdir /media/${UUID}
/usr/bin/mount /dev/${PART} /media/${UUID} -o umask=000,noatime,sync

if [ $? -eq 0 ]
then
  echo "Mounted /dev/$PART to /media/$UUID" | tee /dev/kmsg
else
  echo "Failed to mount /dev/$PART deleting /media/$UUID" | tee /dev/kmsg
  rm -fr /media/${UUID}
fi
