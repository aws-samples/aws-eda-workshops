#!/bin/bash
echo 'CONFIGURE LSF'
source $LSF_INSTALL_DIR/conf/profile.lsf
echo "LSF_ENVDIR=$LSF_ENVDIR"

# Uncomment params to support dynamic hosts in lsf.cluster.*
sed -i -e 's/#\sLSF_HOST_ADDR_RANGE/LSF_HOST_ADDR_RANGE/' \
        -e 's/#\sFLOAT_CLIENTS/FLOAT_CLIENTS/' \
        $LSF_ENVDIR/lsf.cluster.* && \

echo "Updated lsf.conf:" && \
cat $LSF_ENVDIR/lsf.conf && \

# lsf.conf
# Set logging to local file system
sed -i -e 's|^LSF_LOGDIR.*|LSF_LOGDIR=/var/log/lsf|' $LSF_ENVDIR/lsf.conf  && \

cat <<EOF >> $LSF_ENVDIR/lsf.conf
LSB_RC_EXTERNAL_HOST_FLAG=aws
LSB_RC_EXTERNAL_HOST_IDLE_TIME=2 # terminate instance after 2 min idle
LSB_RC_QUERY_INTERVAL=15
LSB_RC_UPDATE_INTERVAL=10
LSF_DYNAMIC_HOST_TIMEOUT=10m # Wait time before removing unavailable dynamic hosts
LSF_DYNAMIC_HOST_WAIT_TIME=3 # time in sec that a dynamic host waits before communicating
LSF_LOCAL_RESOURCES="[resource aws] [type LINUX64]" # Adds 'aws' boolean to dynamic hosts
LSF_MQ_BROKER_HOSTS=$HOSTNAME # start mqtt broker for bhosts -rc and bhosts -rconly commands to work.
LSF_STRIP_DOMAIN=.ec2.internal:.$AWS_CFN_STACK_REGION.compute.internal
MQTT_BROKER_HOST=$HOSTNAME
MQTT_BROKER_PORT=1883
EOF

# Dedup the lsf.conf file
awk '!a[$0]++' $LSF_ENVDIR/lsf.conf > /tmp/lsf.conf.deduped  && \
mv /tmp/lsf.conf.deduped $LSF_ENVDIR/lsf.conf && \

echo "Updated $LSF_ENVDIR/lsf.conf:" && \
cat $LSF_ENVDIR/lsf.conf

# Copy other pre-configured lsf config files
aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/lsf.shared \
        $LSF_ENVDIR/lsf.shared && \
sed -i -e "s/^_CFN_LSF_CLUSTER_NAME_/$LSF_CLUSTER_NAME/" $LSF_ENVDIR/lsf.shared && \

aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/lsb.queues \
        $LSF_ENVDIR/lsbatch/$LSF_CLUSTER_NAME/configdir/lsb.queues && \

aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/lsb.modules \
        $LSF_ENVDIR/lsbatch/$LSF_CLUSTER_NAME/configdir/lsb.modules && \

aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/lsb.params\
        $LSF_ENVDIR/lsbatch/$LSF_CLUSTER_NAME/configdir/lsb.params


# CONFIGURE IBM LSF RESOURCE CONNECTOR FOR AWS
# Sets AWS as the sole host provider
echo 'CONFIGURE IBM LSF RESOURCE CONNECTOR FOR AWS'
aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/hostProviders.json \
        $LSF_ENVDIR/resource_connector/hostProviders.json && \

# ec2-fleet-config.json
aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/ec2-fleet-config.json \
        $LSF_ENVDIR/resource_connector/aws/conf/ec2-fleet-config.json && \

# awsprov.config.json
aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/awsprov_config.json \
        $LSF_ENVDIR/resource_connector/aws/conf/awsprov_config.json && \
sed -i -e "s/_CFN_AWS_REGION_/$AWS_CFN_STACK_REGION/" $LSF_ENVDIR/resource_connector/aws/conf/awsprov_config.json && \

# awsprov.templates.json
aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/awsprov_templates.json \
        $LSF_ENVDIR/resource_connector/aws/conf/awsprov_templates.json && \

sed -i -e "s|%CFN_COMPUTE_AMI%|$CFN_COMPUTE_NODE_AMI|" \
        -e "s|%CFN_COMPUTE_NODE_SUBNET%|$CFN_COMPUTE_NODE_SUBNET|" \
        -e "s|%CFN_ADMIN_KEYPAIR%|$CFN_EC2_KEY_PAIR|" \
        -e "s|%CFN_COMPUTE_SECURITY_GROUP_ID%|$CFN_COMPUTE_NODE_SG_ID|" \
        -e "s|%CFN_LSF_COMPUTE_NODE_INSTANCE_PROFILE_ARN%|$CFN_COMPUTE_NODE_INSTANCE_PROFILE_ARN|" \
        -e "s|%CFN_LSF_CLUSTER_NAME%|$LSF_CLUSTER_NAME|" \
        -e "s|%CFN_FSXN_SVM_DNS_NAME%|$NFS_DNS_NAME|" \
        -e "s|%CFN_NFS_MOUNT_POINT%|$NFS_MOUNT_POINT|" \
        -e "s|%CFN_LSF_INSTALL_DIR%|$LSF_INSTALL_DIR|" \
        -e "s|%CFN_DCV_USER_NAME%|$CFN_DCV_USERNAME|" \
        -e "s|%CFN_LSF_COMPUTE_NODE_SPOT_FLEET_ROLE_ARN%|$CFN_COMPUTE_SPOT_FLEET_ROLE_ARN|" \
        $LSF_ENVDIR/resource_connector/aws/conf/awsprov_templates.json && \

# user_data script that RC executes on compute nodes
aws s3 cp s3://$AWS_S3_BUCKET_NAME/workshops/eda-workshop-lsf/config/lsf/user_data.sh \
        $LSF_INSTALL_DIR/10.1/resource_connector/aws/scripts/user_data.sh && \
chmod +x $LSF_INSTALL_DIR/10.1/resource_connector/aws/scripts/user_data.sh