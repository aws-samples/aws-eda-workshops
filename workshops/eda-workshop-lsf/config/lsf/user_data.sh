#!/bin/bash

set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1

echo "*** BEGIN LSF HOST BOOTSTRAP ***"

# Export user data, which is defined with the "UserData" attribute
# in the template
%EXPORT_USER_DATA%

export PATH=/sbin:/usr/sbin:/usr/local/bin:/bin:/usr/bin
export AWS_DEFAULT_REGION="$( curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/[a-z]*$//' )"
export LSF_INSTALL_DIR_ROOT="/`echo $LSF_INSTALL_DIR | cut -d / -f2`"
export LSF_ADMIN=lsfadmin

# Install SSM so we can use SSM Session Manager and avoid ssh logins.
yum install -q -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Disable Hyperthreading
echo "Disabling Hyperthreading"
for cpunum in $(cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | cut -s -d, -f2- | tr ',' '\n' | sort -un)
do
    echo 0 > /sys/devices/system/cpu/cpu${cpunum}/online
done

# mount shared file systems
mkdir $LSF_INSTALL_DIR_ROOT
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_FS_DNS_NAME}:/ $LSF_INSTALL_DIR_ROOT

mkdir $FS_MOUNT_POINT

# Using default mount options.  Tune as necessary.
mount $NFS_SERVER_EXPORT $FS_MOUNT_POINT

# if [ -n "${fsx}" ]; then
#    # Download Lustre client
#    cd /tmp
#    wget https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm
#    wget https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm

#    # Install client
#    yum localinstall -y *lustre-client-2.10.5*.rpm

#    # Mount ${fsx}
#    mkdir /fsx && chown centos /fsx
#    mount -t lustre ${fsx}@tcp:/fsx /fsx
# fi

# if [ -n "${ec2nfs}" ]; then
#    mkdir /ec2nfs
#    # mount ${ec2nfs}
# fi

# Set up the LSF enviornment

# Create local lsf.conf file to support per-exechost configs
# See LSF_LOCAL_RESOURCES below.
# TODO: figure out more elegant way to do this
#cp /efs/tools/lsf/clusters/bespin/conf/lsf.conf.orig /etc/lsf.conf

# Add the LSF admin account, ec2-user
# TODO: pass from RC template variable
useradd -m -u 1500 $LSF_ADMIN

LSF_TOP=$LSF_INSTALL_DIR
LSF_CONF_FILE=$LSF_TOP/conf/lsf.conf
. $LSF_TOP/conf/profile.lsf

# Create LSF log directories
mkdir /var/log/lsf && chmod 777 /var/log/lsf

# Support rc_account resource to enable RC_ACCOUNT policy
# Add additional local resources if needed
# if [ -n "${rc_account}" ]; then
#    sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [resourcemap ${rc_account}*rc_account]\"/" $LSF_CONF_FILE
#    echo "update LSF_LOCAL_RESOURCES lsf.conf successfully, add [resourcemap ${rc_account}*rc_account]"
# fi


# Start LSF Daemons
$LSF_SERVERDIR/lsf_daemons start

echo "*** END LSF HOST BOOTSTRAP ***"