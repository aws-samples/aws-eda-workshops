#!/bin/bash
 
source /etc/environment
HOSTNAME=$(hostname | awk '{split($0,a,"."); print a[1]}')
SCHEDULER_HOSTNAME=$(/opt/pbs/bin/qstat -Bf | grep "Server:" | awk '{print $2}')
if [[ "$HOSTNAME" != "$SCHEDULER_HOSTNAME" ]]; then
    echo "Please run the script on $SCHEDULER_HOSTNAME"
    Exit
fi
 
/apps/soca/$SOCA_CONFIGURATION/python/latest/bin/python3 /apps/soca/$SOCA_CONFIGURATION/cluster_manager/add_nodes.py --ht_support true \
--instance_ami <AMI_ID> --base_os "centos7" --root_size 10 --subnet_id <SUBNET_ID>\
--instance_type  <INSTANCE_TYPE> \
--desired_capacity 1 --queue alwayson --job_owner $USER --job_name $USER \
--keep_forever false --terminate_when_idle 10
