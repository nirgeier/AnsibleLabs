#!/bin/bash

clear

# Get the current folder when the script is 
# executed as source from another script
BASEDIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# echo -e "${Yellow}Creating folder strcuture${COLOR_OFF}"
mkdir -p $RUNTIME_FOLDER/.ssh
mkdir -p $RUNTIME_FOLDER/.ssh-server
mkdir -p $RUNTIME_FOLDER/labs-scripts

# Wait for opertation to conmplete (not require just to be safe)
sleep 5

# Start the demo containers
echo -e "${Green}Starting docker containers${COLOR_OFF}"
docker-compose up -d --build > /dev/null

# Sleep for few seconds so the enntrypoint will finish its running
echo -e "* ${Yellow}Sleeping 5 seconds - waiting for container to start ${COLOR_OFF}"
echo -e ""

for i in {1..5}; 
do 
    echo -e -n "${Red}." 
    sleep 1
done

source ./01-check-servers.sh

