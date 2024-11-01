#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1

echo "*** BEGIN LSF HOST BOOTSTRAP ***"

env

# Export user data, which is defined with the "UserData" attribute
# in the template
%EXPORT_USER_DATA%

export PATH=/sbin:/usr/sbin:/usr/local/bin:/bin:/usr/bin
export AWS_DEFAULT_REGION="$( curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/[a-z]*$//' )"
export EC2_INSTANCE_TYPE="$( curl -s http://169.254.169.254/latest/meta-data/instance-type | sed -e 's/\./_/' )"
export EC2_INSTANCE_LIFE_CYCLE="$( curl -s http://169.254.169.254/latest/meta-data/instance-life-cycle | sed -e 's/\-/_/' )"
export CPU_ARCHITECTURE="$(lscpu | awk '/Architecture/ {print toupper($2)}')"
export LSF_ADMIN=lsfadmin

# Add the LSF admin account
useradd -m -u 1500 $LSF_ADMIN
# Add DCV login user account
useradd -m -u 1501 $DCV_USER_NAME

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
if [[ "$FSXN_SVM_DNS_NAME" == *"efs"* ]]; then
   JUNCTION_PATH="/"
   NFS_OPTIONS="nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport"
# Check if the NFS_DNS_NAME contains "fsx"
elif [[ "$FSXN_SVM_DNS_NAME" == *"fsx"* ]]; then
   JUNCTION_PATH="/vol1"
   NFS_OPTIONS="rsize=262144,wsize=262144,hard,vers=3,tcp,mountproto=tcp"
else
   # Set a default value or handle other cases if needed
   JUNCTION_PATH="unknown"
   NFS_OPTIONS="unknown"
fi

# Print NFS mount
echo "Mounting $FSXN_SVM_DNS_NAME:$JUNCTION_PATH"
mkdir -p $NFS_MOUNT_POINT
mount -t nfs -o $NFS_OPTIONS $FSXN_SVM_DNS_NAME:$JUNCTION_PATH $NFS_MOUNT_POINT

## Set up the LSF environment
# Create LSF log and conf directories
mkdir -p /var/log/lsf && chmod 777 /var/log/lsf
mkdir -p /etc/lsf && chmod 777 /etc/lsf

LSF_TOP=${LSF_INSTALL_DIR}
source $LSF_TOP/conf/profile.lsf

# Create local lsf.conf file and update LSF_LOCAL_RESOURCES
# parameter to support dynamic resources
cp $LSF_ENVDIR/lsf.conf /etc/lsf/lsf.conf
chmod 444 /etc/lsf/lsf.conf
export LSF_ENVDIR=/etc/lsf

# Add instance_type resource
sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [resourcemap ${EC2_INSTANCE_TYPE}*instance_type]\"/" $LSF_ENVDIR/lsf.conf
echo "Updated LSF_LOCAL_RESOURCES lsf.conf with [resourcemap ${EC2_INSTANCE_TYPE}*instance_type]"

# Add cpu_type resource (if set)
if [ -n "${cpu_type}" ]; then
   sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [resourcemap ${cpu_type}*cpu_type]\"/" $LSF_ENVDIR/lsf.conf
   echo "Updated LSF_LOCAL_RESOURCES lsf.conf with [resourcemap ${cpu_type}*cpu_type]"
fi

if [ -n "${rc_account}" ]; then
   sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [resourcemap ${rc_account}*rc_account]\"/" $LSF_ENVDIR/lsf.conf
   echo "Updated LSF_LOCAL_RESOURCES lsf.conf with [resourcemap ${rc_account}*rc_account]"
fi

# Add on_demand or spot attribute to resource map
if [ -n "${EC2_INSTANCE_LIFE_CYCLE}" ]; then
   sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [resource ${EC2_INSTANCE_LIFE_CYCLE}]\"/" $LSF_ENVDIR/lsf.conf
   echo "Updated LSF_LOCAL_RESOURCES lsf.conf with [resource ${EC2_INSTANCE_LIFE_CYCLE}]"
fi

# Add CPU Architecture to type map
if [ -n "${CPU_ARCHITECTURE}" ]; then
   # Check if the pattern [type ...] is present in the lsf.conf fil
   if grep -q "\[type [^]]*\]" $LSF_ENVDIR/lsf.conf; then
      sed -i "s/\[type [^]]*\]/[type $CPU_ARCHITECTURE]/" $LSF_ENVDIR/lsf.conf
   else
      sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [type ${CPU_ARCHITECTURE}]\"/" $LSF_ENVDIR/lsf.conf
   fi
fi

if [ -n "${ssd}" ]; then
   sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [resource ${ssd}]\"/" $LSF_ENVDIR/lsf.conf
   echo "Updated LSF_LOCAL_RESOURCES lsf.conf with [resource ${ssd}]"
fi

# Start LSF Daemons
lsadmin limstartup
lsadmin resstartup
sleep 2
badmin hstartup

echo "*** END LSF HOST BOOTSTRAP ***"


