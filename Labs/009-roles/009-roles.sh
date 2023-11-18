#!/bin/bash

# Get the current folder when the script is executed from 
BASEDIR=$(dirname "$0")

# Switch to the base folder
echo $BASEDIR

# Load the colors
source ../../_utils/common.sh

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# remove old content
rm -rf ${ROOT_FOLDER}/roles_demo
mkdir ${ROOT_FOLDER}/roles_demo
cd ${ROOT_FOLDER}/roles_demo

echo -e "${Yellow}Initilaizing the role${COLOR_OFF}"
echo -e "${White}$ ${Green}ansible-galaxy init codewizard_lab_role${COLOR_OFF}"
ansible-galaxy init codewizard_lab_role

echo -e "${Yellow}Verifying role creation${COLOR_OFF}"
tree codewizard_lab_role

cd codewizard_lab_role

# Add git repository
echo -e "${Yellow}Initilaizing git repository${COLOR_OFF}"
git init 
git remote add origin git@github.com:nirgeier/AnsibleRoleLab.git

# Push the fisrt step to git
git add .
git commit -m"Initial commit"
git push -f

