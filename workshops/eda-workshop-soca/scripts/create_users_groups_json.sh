#!/bin/bash -ex

cluster_name=$1
scripts_dir=$2
config_dir=$3

if [[ ":$cluster_name" == ":" ]]; then
    cluster_name=$(basename /apps/soca/soca-*)
fi
if [[ ":$scripts_dir" == ":" ]]; then
    scripts_dir=/apps/soca/$cluster_name/cluster_node_bootstrap
fi
if [[ ":$config_dir" == ":" ]]; then
    config_dir=/apps/soca/$cluster_name/cluster_node_bootstrap
fi

if ! yum list installed epel-release &> /dev/null; then
    sudo yum -y install epel-release
fi
if ! yum list installed ansible &> /dev/null; then
    sudo yum -y install ansible
fi

cd ../ansible
ansible-playbook create_users_groups_json.yml -i inventories/local.yml -e ClusterName=$cluster_name -e ScriptsDir=$scripts_dir -e ConfigDir=$config_dir
