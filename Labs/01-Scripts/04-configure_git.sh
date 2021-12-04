#!/bin/bash

# We will need to pre-install the missing plugin
# https://docs.ansible.com/ansible/latest/collections/community/general/git_config_module.html
# ansible-galaxy collection install community.general

# The desired file name to run
FILE_NAME=/opt/scripts/script.sh

# Create the desired file
touch ${PWD}/../runtime/$FILE_NAME

# Generta the desired script for printing out ansible verison
cat << EOF > ${PWD}/../runtime/${FILE_NAME}
#!/bin/bash
cd /opt/scripts/
ansible-playbook 04-configure_git.yaml
EOF

# Set the execution mode
chmod +x ${PWD}/../runtime/$FILE_NAME

# Copy the configuration files
cp ${PWD}/sources/* ${PWD}/../runtime/opt/scripts/

# Execute the script on the ansible contianer
docker exec -it 00-setup_ansible_1 $FILE_NAME