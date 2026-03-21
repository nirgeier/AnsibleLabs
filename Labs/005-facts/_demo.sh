#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh

# Run a simple ansible script
# Display facts from all hosts and store them indexed by hostname under facts folder
docker exec ansible-labs bash -c "cd /home/ansible/labs/005-facts && ansible all -m ansible.builtin.gather_facts --tree /home/ansible/labs/005-facts/facts"

# display the facts folder
docker exec ansible-labs bash -c "tree -a /home/ansible/labs/005-facts/facts"

echo "Waiting for user to proceed to next step... (playbook)"
read user_input

# run ansible playbook which installs git on the servers
docker exec ansible-labs bash -c "cd /home/ansible/labs/005-facts && ansible-playbook ./005-playbook-facts.yaml"

# display the facts folder
docker exec ansible-labs bash -c "tree -a /home/ansible/labs/005-facts/facts"