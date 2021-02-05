#!/bin/bash

source /etc/environment
HOSTNAME=$(hostname | awk '{split($0,a,"."); print a[1]}')
SCHEDULER_HOSTNAME=$(/opt/pbs/bin/qstat -Bf | grep "Server:" | awk '{print $2}')
if [[ "$HOSTNAME" != "$SCHEDULER_HOSTNAME" ]]; then
    CMD_PREFIX="ssh $SCHEDULER_HOSTNAME"
else
    CMD_PREFIX=""
fi

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AMI_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/ami-id)
MAC_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs)
SUBNET_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC_ID/subnet-id)

eval $CMD_PREFIX "/apps/soca/$SOCA_CONFIGURATION/python/latest/bin/python3 \
    /apps/soca/$SOCA_CONFIGURATION/cluster_manager/add_nodes.py \
    --ht_support true --instance_ami $AMI_ID --base_os \"centos7\" \
    --root_size 10 --subnet_id $SUBNET_ID --instance_type t3.large \
    --desired_capacity 1 --queue alwayson --job_owner $USER --job_name $USER \
    --keep_forever false --terminate_when_idle 10"
