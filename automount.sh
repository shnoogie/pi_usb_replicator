#!/bin/bash

PART=$1
FS_LABEL=`lsblk -o name,label | grep ${PART} | awk '{print $2}'`
FS_TYPE=`lsblk -o name,parttypename | grep ${PART} | awk '{print $2}'`
UUID=`lsblk -o name,uuid | grep ${PART} | awk '{print $2}'`
FOLDER_NAME="${PART}-${UUID}"
SEARCH_RE="EFI"

if [[ $FS_TYPE =~ $SEARCH_RE ]]
then
  echo "Ignoring EFI filesystem for /dev/${PART}" | tee /dev/kmsg
  exit 1
fi

mkdir /media/${FOLDER_NAME}
/usr/bin/mount /dev/${PART} /media/${FOLDER_NAME} -o umask=000,noatime,sync

if [ $? -eq 0 ]
then
  echo "Mounted /dev/$PART to /media/$FOLDER_NAME" | tee /dev/kmsg
  /usr/local/bin/syncfiles.sh "$FOLDER_NAME"
else
  echo "Failed to mount /dev/$PART deleting /media/$FOLDER_NAME" | tee /dev/kmsg
  rm -fr /media/${FOLDER_NAME}
fi
