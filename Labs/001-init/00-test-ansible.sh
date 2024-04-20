#!/bin/bash

# Save the current directory
CURRENT_DIR=$(dirname "$0")

source ../000-setup/00-setup.sh
source ../000-setup/01-check-servers.sh

# Switch to the current directory
cd $CURRENT_DIR
source ./02-init-ansible.sh
source ./03-test-ansible.sh