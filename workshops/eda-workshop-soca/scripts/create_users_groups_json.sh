#!/bin/bash -ex

if ! yum list installed ansible; then
    sudo yum -y install ansible
fi

cluster_name=$1
scripts_dir=$2

if [[ ":$cluster_name" == ":" ]]; then
    $cluster_name=$(basename /apps/soca/soca-*)
fi
if [[ ":$scripts_dir" == ":" ]]; then
    $scripts_dir=/apps/soca/$cluster_name/cluster_node_bootstrap
fi

cd ../ansible
ansible-playbook create_users_groups_json.yml -i inventories/local.yml -e ClusterName=$cluster_name -e ScriptsDir=$scripts_dir
