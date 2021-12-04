#!/bin/bash

# 
# This script will create the required keys for the ansible playground
# We will connect to this continaer using ssh key
#

# Verify that we have the desired folder
mkdir -p /root/.ssh

# The ssh file we loooking for
FILE=/root/.ssh/${hostname}

# touch the authorized_keys for first use
touch /root/.ssh/authorized_keys

# Check to see if we have certificzte
if test -f "$FILE"; then
    echo "$FILE exists."
else
  # Generate ssh key(s) 
  yes '' | ssh-keygen -P '' -f ${FILE} > /dev/null
fi

# Set the required flags 
chmod 777 /root/.ssh/authorized_keys

# Add the key to the authorized_keys
cat ${FILE}.pub >> /root/.ssh/authorized_keys

# Set the required flags 
chmod 400 /root/.ssh/authorized_keys  

# Start the ssh deamon 
/usr/sbin/sshd -D