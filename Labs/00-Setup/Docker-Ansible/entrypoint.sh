#!/bin/bash

mkdir -p /opt/ansible
mkdir -p /opt/scripts

# Add the desired certificate
ssh -i /root/.ssh/${hostname1} root@${hostname1} -o StrictHostKeyChecking=no
ssh -i /root/.ssh/${hostname2} root@${hostname2} -o StrictHostKeyChecking=no

# This script will run the desired ansible script or will wait for input
case "$1" in
    '')
	sleep inf
	;;
    *)
	/opt/scripts/$*
	;;
esac