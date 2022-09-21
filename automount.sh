#!/bin/bash

PART=$1
FS_LABEL=`lsblk -o name,label | grep ${PART} | awk '{print $2}'`
FS_TYPE=`lsblk -o name,parttypename | grep ${PART} | awk '{print $2}'`
UUID=`lsblk -o name,uuid | grep ${PART} | awk '{print $2}'`
SEARCH_RE="EFI"

if [[ $FS_TYPE =~ $SEARCH_RE ]]
then
  echo "Ignoring EFI filesystem for /dev/${PART}" | tee /dev/kmsg
  exit 1
fi

mkdir /media/${UUID}
/usr/bin/mount /dev/${PART} /media/${UUID} -o umask=000,noatime,sync

if [ $? -eq 0 ]
then
  echo "Mounted /dev/$PART to /media/$UUID" | tee /dev/kmsg
  /usr/local/bin/syncfiles.sh "$UUID"
else
  echo "Failed to mount /dev/$PART deleting /media/$UUID" | tee /dev/kmsg
  rm -fr /media/${UUID}
fi
