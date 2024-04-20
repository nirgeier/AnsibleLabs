#!/bin/bash

clear

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Get the root folder of our demo folder
echo "ROOT_FOLDER=$(git rev-parse --show-toplevel)" > $ROOT_FOLDER/Labs/000-setup/.env

# echo -e "${Yellow}Creating folder strcuture${COLOR_OFF}"
mkdir -p $RUNTIME_FOLDER/.ssh
mkdir -p $RUNTIME_FOLDER/.ssh-server
mkdir -p $RUNTIME_FOLDER/labs-scripts

# Start the demo servers
docker-compose -f $ROOT_FOLDER/Labs/000-setup/docker-compose.yaml up -d 
sleep 5

# Verify that the ansible container has ansible installed
echo -e "${Yellow}Verifying Ansible version${COLOR_OFF}"
docker exec -it ansible-controller ansible --version

### Add the certificates to the authorized_keys on our ansible container
### In order to avoid adding keys to the host machine we are verifying that we
### are adding the keys to the demo .ssh folder
echo -e "${Yellow}Connecting to hosts with ssh keys${COLOR_OFF}"

# Add the key to the authorized_keys
echo "* Add key to authorized_keys"
touch       $RUNTIME_FOLDER/.ssh/authorized_keys
chmod 600   $RUNTIME_FOLDER/.ssh/authorized_keys

for i in {1..3}
do
    echo -e ""
    echo -e "${Green}-------------- linux-server-$i -------------- ${COLOR_OFF}"
    echo -e ""
    
    # echo "* Creating SSH key for linux-server-$i"
    # ssh-keygen -R linux-server-$i
    # echo "ssh-keygen -t rsa -q -P '' -f $RUNTIME_FOLDER/.ssh/linux-server-$i <<<y"
    # ssh-keygen -t rsa -q -P '' -f $RUNTIME_FOLDER/.ssh/linux-server-$i <<<y

    echo -e "* ${Yellow}Copying certificate to linux-server-$i ${COLOR_OFF}"
    docker cp linux-server-$i:/root/.ssh/linux-server-$i     $RUNTIME_FOLDER/.ssh     
    docker cp linux-server-$i:/root/.ssh/linux-server-$i.pub $RUNTIME_FOLDER/.ssh 

    echo -e "* ${Yellow}Adding certificate from linux-server-$i to known_hosts ${COLOR_OFF}"
    cat $RUNTIME_FOLDER/.ssh/linux-server-$i.pub >> $RUNTIME_FOLDER/.ssh/known_hosts
    
    # echo -e "* ${Yellow}Start ssh service on linux-server-$i ${COLOR_OFF}"
    # docker exec linux-server-$i bash service ssh restart

    echo -e "* ${Yellow}Checking ssh service on linux-server-$i ${COLOR_OFF}"
    docker exec linux-server-$i bash service --status-all | grep 'ssh'
    
    echo -e "* ${Yellow}Connecting to         linux-server-$i ${COLOR_OFF}"
    ssh -i $RUNTIME_FOLDER/.ssh/linux-server-$i                 \
    -p 300$i root@localhost                                     \
    -o StrictHostKeyChecking=accept-new                         \
    -o UserKnownHostsFile=$RUNTIME_FOLDER/.ssh/known_hosts      \
    cat /etc/hosts | grep --color=auto -E "linux-server-$i|$";
    
done