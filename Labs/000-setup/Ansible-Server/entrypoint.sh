#!/bin/bash

mkdir -p /labs-scripts/ansible
mkdir -p /labs-scripts/scripts

# Generate certificate for this server
ssh-keygen -A

# unlock the user
passwd -u root

# Create the sshd_config
cat << EOF >> /etc/ssh/sshd_config
PasswordAuthentication  no
PermitRootLogin         yes
Port                    22
Protocol                2
EOF

rc-status
rc-service sshd start

# This container will wait for input
sleep inf
