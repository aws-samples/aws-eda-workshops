#!/bin/bash -ex

if ! yum list installed ansible; then
    sudo yum -y install ansible
fi

cluster_name=$1
scripts_dir=$2

cd ../ansible
ansible-playbook create_users_groups_json.yml -i inventories/local.yml -e ClusterName=$cluster_name -e ScriptsDir=$scripts_dir
