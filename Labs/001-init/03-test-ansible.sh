#!/bin/bash
###
### Run our first ansible script to chcek the servers
###

source ../../_utils/common.sh

echo -e "${Yellow}-----------------------------------${COLOR_OFF}"
echo -e "${Cyan}* Check the setup, execute a basic ansible script${COLOR_OFF}"
echo -e "${Green}* Executing: ${Yellow}ansible all -m ping${COLOR_OFF}"
# Test that the servers can accept connections from the ansible server
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"