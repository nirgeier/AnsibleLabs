#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

ssh -i $ROOT_FOLDER/runtime/.ssh/$1                  \
        -p $2 root@localhost                                 \
        -o StrictHostKeyChecking=accept-new                     \
        -o UserKnownHostsFile=$ROOT_FOLDER/runtime/.ssh/known_hosts  \
        