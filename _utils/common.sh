#!/bin/bash

##########################################
### Colors
##########################################

# Reset
COLOR_OFF='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

##########################################
### Folders
##########################################

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)
RUNTIME_FOLDER=$ROOT_FOLDER/runtime
LABS_SCRIPT_FOLDER=$RUNTIME_FOLDER/labs-scripts
DEFAULT_ANSIBLE_SCRIPT=$LABS_SCRIPT_FOLDER/script.sh

# mkdir -p $RUNTIME_FOLDER/.ssh
# mkdir -p $LABS_SCRIPT_FOLDER
