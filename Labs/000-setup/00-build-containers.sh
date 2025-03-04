#!/bin/bash

clear

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)
export ROOT_FOLDER=$ROOT_FOLDER

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Get the current directory of our lab
CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# check if any running containers
if [ $(docker ps -aq | wc -l) -gt 1 ]; then
    # Remove all docker-conatiner
    echo -e "${Yellow}Removing old docker containers${COLOR_OFF}"
    docker stop $(docker ps -aq)
    docker rm   $(docker ps -aq)

    # Stop any existing demo containers
    docker-compose -f $CURRENT_DIR/docker-compose.yaml down
    sleep 5
fi

echo -e "${Yellow}Removing old content${COLOR_OFF}"
rm -rf $RUNTIME_FOLDER

# echo -e "${Yellow}Creating folder strcuture${COLOR_OFF}"
mkdir -p $RUNTIME_FOLDER/.ssh
mkdir -p $RUNTIME_FOLDER/.ssh-server
mkdir -p $RUNTIME_FOLDER/labs-scripts

# Get the root folder of our demo folder
echo "ROOT_FOLDER=$(git rev-parse --show-toplevel)" > $CURRENT_DIR/.env

# Start the demo containers
echo -e "${Green}Starting docker containers${COLOR_OFF}"
docker-compose -f $CURRENT_DIR/docker-compose.yaml up -d --build 
sleep 5

# Sleep for few seconds so the enntrypoint will finish its running
echo -e "* ${Yellow}Sleeping 5 seconds - waiting for container to start ${COLOR_OFF}"
echo -e ""

for i in {1..5}; do  
    echo -e -n "${Red}." 
    sleep 1
done