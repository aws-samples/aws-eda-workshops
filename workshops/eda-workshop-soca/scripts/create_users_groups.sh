#!/bin/bash -ex

if ! yum list installed ansible; then
    sudo yum -y install ansible
fi

scripts_dir=$1

cd ../ansible
ansible-playbook create_users_groups.yml -i inventories/local.yml -e ScriptsDir=$scripts_dir
