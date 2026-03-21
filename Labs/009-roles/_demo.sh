#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Get the current directory of our lab
CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
echo "Current directory $CURRENT_DIR"

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh

# run ansible playbook
docker exec ansible-labs bash -c "cd /home/ansible/labs/009-roles && ansible-playbook ./009-codewizard-role-playbook.yaml"

# Test the servers
echo -e $(curl -s localhost:5001)
echo -e $(curl -s localhost:5002)
echo -e $(curl -s localhost:5003)
