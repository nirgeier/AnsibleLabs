#!/bin/bash

source ../../_utils/common.sh

###
### Create the required files for this demo
###
echo -e "${Yellow}-----------------------------------${COLOR_OFF}"
echo -e "${Cyan}* Creating the required files"

echo -e "${Cyan}* Creating $RUNTIME_FOLDER/labs-scripts/ansible.cfg"
cat <<EOF > $RUNTIME_FOLDER/labs-scripts/ansible.cfg
##
## This is the main configuration file for our demo application
##

# This is the default location of the inventory file, script, or directory
# that Ansible will use to determine what hosts it has available to talk to
[defaults]

# Define that inventory info is in the file named “inventory”
inventory = inventory

# Specify remote hosts, so we do not need to config them in main ssh config
[ssh_connection]
transport = ssh

# The location of the ssh config file
# We will create this file in our next step
ssh_args  = -F ssh.config
EOF

echo -e "${Cyan}* Creating $RUNTIME_FOLDER/labs-scripts/ssh.config"
cat <<EOF > $RUNTIME_FOLDER/labs-scripts/ssh.config
# Set up the desired hosts
# keep in mind that we have set up the hosts in the docker-compose
Host *
    # Disable host key checking: 
    # avoid asking for the key-print authenticity
    StrictHostKeyChecking no
    
    UserKnownHostsFile    /dev/null
    
    # Enable hashing known_host file
    HashKnownHosts        yes
    
    # IdentityFile allows to specify private keys we wish to use for authentication
    # Authentication = the process of Authentication
    # We will use the auto-generated ssh keys from our Docker container

# List the desired servers. 
# the hosts are defined in the docker-compose which we created in the setup lab)
Host                linux-server-1
    HostName        linux-server-1
    IdentityFile    /root/.ssh/linux-server-1
    User            root
    Port            3001

Host                linux-server-2
    HostName        linux-server-2
    IdentityFile    /root/.ssh/linux-server-2
    User            root
    Port            3002

Host                linux-server-3
    HostName        linux-server-3
    IdentityFile    /root/.ssh/linux-server-3
    User            root
    Port            3003
EOF

echo -e "${Cyan}* Creating $RUNTIME_FOLDER/labs-scripts/inventory"
cat <<EOF > $RUNTIME_FOLDER/labs-scripts/inventory
###
### List of servers which we want ansible to connect to
### The names are defined in the docker-compose
###

[servers]
  linux-server-1
  linux-server-2
  linux-server-3
EOF

echo -e "${Cyan}* List created files and folders"
tree -a $RUNTIME_FOLDER/labs-scripts