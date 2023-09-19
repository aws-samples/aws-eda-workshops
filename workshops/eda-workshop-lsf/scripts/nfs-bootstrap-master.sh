#!/bin/bash
# Mount NFS file system for LSF install
mkdir -p $NFS_MOUNT_POINT

# Check if the NFS_DNS_NAME is "efs", "FSxN"
if [[ "$NFS_DNS_NAME" == *"efs"* ]]; then
JUNCTION_PATH="/"
NFS_OPTIONS="nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport"
# Check if the NFS_DNS_NAME contains "fsx"
elif [[ "$NFS_DNS_NAME" == *"fsx"* ]]; then
JUNCTION_PATH="/vol1"
NFS_OPTIONS="rsize=262144,wsize=262144,hard,vers=3,tcp,mountproto=tcp"
else
# Set a default value or handle other cases if needed
JUNCTION_PATH="unknown"
NFS_OPTIONS="unknown"
fi

# Print NFS mount
echo "Mounting $NFS_DNS_NAME:$JUNCTION_PATH"
mount -t nfs -o $NFS_OPTIONS $NFS_DNS_NAME:$JUNCTION_PATH $NFS_MOUNT_POINT
mkdir -p $NFS_MOUNT_POINT/tmp
chmod a+w $NFS_MOUNT_POINT/tmp

# add to fstab
echo "$NFS_DNS_NAME:$JUNCTION_PATH $NFS_MOUNT_POINT nfs $NFS_OPTIONS 0 0" >> \
/etc/fstab