#!/bin/bash

PART=$1
MOUNT_POINT=`mount | grep ${PART} | cut -d ' ' -f 3`

/usr/bin/umount ${MOUNT_POINT}
rm -fr ${MOUNT_POINT}

echo "Unmounted /dev/$PART from $MOUNT_POINT" | tee /dev/kmsg
