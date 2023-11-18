#!/bin/bash

# Specify the directory
dir="$1"

# Check if the directory exists
if [[ -d "$dir" ]]; then
    echo "Subfolders in $dir:"
    find "$dir" -maxdepth 1 -type d
else
    echo "Directory $dir does not exist."
fi