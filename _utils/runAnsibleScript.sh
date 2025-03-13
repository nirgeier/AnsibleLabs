#!/bin/bash

clear

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Set a default value for the script path
ANSIBLE_SCRIPT=labs-scripts/script.sh

if [ "$#" -eq 0 ]
then
    echo -e "${BYellow}---------------------------------------- ${COLOR_OFF}"
    echo -e "${BYellow}--- ${BRed}Missing script folder to execute ${BYellow}--- ${COLOR_OFF}"
    echo -e "${BYellow}---------------------------------------- ${COLOR_OFF}"
    exit 0;
fi

echo -e "${YELLOW}Creating the runtime folder${COLOR_OFF}"
mkdir -p $ROOT_FOLDER/runtime/labs-scripts/

echo -e "${YELLOW}Removing previous content${COLOR_OFF}"
rm -rf $ROOT_FOLDER/runtime/labs-scripts/

echo -e "${YELLOW}Copying content${COLOR_OFF}"
cp -R $ROOT_FOLDER/Labs/001-init $ROOT_FOLDER/runtime/labs-scripts/

echo -e "${YELLOW}Copying content${COLOR_OFF}"
cp -R $1 $ROOT_FOLDER/runtime/labs-scripts/

# Set the execution mode
echo -e "${YELLOW}Setting execution to sh files${COLOR_OFF}"
#ls -la $ROOT_FOLDER/runtime/labs-scripts/

# Execute the script on the ansible container
echo -e ""
echo -e "${YELLOW}\$ docker exec -it ansible-controller /$ANSIBLE_SCRIPT${COLOR_OFF}"
echo -e ""

docker exec -it ansible-controller /$ANSIBLE_SCRIPT