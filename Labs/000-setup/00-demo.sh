#!/bin/bash

clear

# Get the current folder when the script is executed from 
BASEDIR=$(dirname "$0")

# Switch to the base folder
cd $BASEDIR

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Remove all docker-conatiner
echo -e "${Yellow}Removing old docker containers${COLOR_OFF}"
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# Stop any existing demo containers
docker-compose down

echo -e "${Yellow}Removing old content${COLOR_OFF}"
rm -rf $RUNTIME_FOLDER

echo -e "${Yellow}Creating folder strcuture${COLOR_OFF}"
mkdir -p $RUNTIME_FOLDER/.ssh
mkdir -p $RUNTIME_FOLDER/.ssh-server
mkdir -p $RUNTIME_FOLDER/labs-scripts

# Start the demo containers
echo -e "${Green}Starting docker containers${COLOR_OFF}"
docker-compose up -d --build > /dev/null

# Sleep for few seconds so the enntrypoint will finish its running
sleep 3

# Remove the previous certificates if any
echo -e "${Yellow}Removing old ssh keys${COLOR_OFF}"
ssh-keygen -f "$RUNTIME_FOLDER/.ssh/known_hosts" -R "[localhost]:3001" 2> /dev/null
ssh-keygen -f "$RUNTIME_FOLDER/.ssh/known_hosts" -R "[localhost]:3002" 2> /dev/null
ssh-keygen -f "$RUNTIME_FOLDER/.ssh/known_hosts" -R "[localhost]:3003" 2> /dev/null

# Add new ssh keys
echo -e "${Yellow}Adding new ssh keys${COLOR_OFF}"
ssh-keyscan -p 3001 localhost 2> /dev/null >> $RUNTIME_FOLDER/.ssh/known_hosts 
ssh-keyscan -p 3002 localhost 2> /dev/null >> $RUNTIME_FOLDER/.ssh/known_hosts 
ssh-keyscan -p 3003 localhost 2> /dev/null >> $RUNTIME_FOLDER/.ssh/known_hosts 

### Add the certificates to the authorized_keys on our ansible container
### In order to avoid adding keys to the host machine we are verifying that we 
### are adding the keys to the demo .ssh folder
echo -e "${Yellow}Connecting to hosts with ssh keys${COLOR_OFF}"

set -x
for i in {1..3}
do
    echo -e ""
    echo -e "${Green}------------------------------------------------${COLOR_OFF}"
    echo -e ""
    echo -e "${Green}Connecting to demo.server$i ${COLOR_OFF}"
    echo -e "${Yellow}$ echo cat /etc/hosts ${COLOR_OFF}"
    ssh -i $RUNTIME_FOLDER/.ssh/demo.server$i                  \
        -p 300$i root@localhost                                  \
        -o StrictHostKeyChecking=accept-new                     \
        -o UserKnownHostsFile=$RUNTIME_FOLDER/.ssh/known_hosts  \
        cat /etc/hosts | grep --color=auto -E "demo.server$i|$"
done