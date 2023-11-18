#!/bin/bash

clear

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Generate the playbook file
cat << EOF > $LABS_SCRIPT_FOLDER/006-loop-and-conditions.yaml
- hosts: linux-server-2
  tasks:
    - name: Run with items greater than 5
      ansible.builtin.command: echo {{ item }}
      loop: [ 0, 2, 4, 6, 8, 10 ]
      when: item > 5
EOF

# Generate the desired script for printing out ansible verison
cat << EOF > $DEFAULT_ANSIBLE_SCRIPT
#!/bin/bash

cd /labs-scripts
ansible-playbook ./006-loop-and-conditions.yaml
EOF

# Set the execution mode
chmod +x $DEFAULT_ANSIBLE_SCRIPT

# Execute the script
$ROOT_FOLDER/_utils/runAnsibleScript.sh

