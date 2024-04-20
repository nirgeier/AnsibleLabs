#!/bin/bash

###
### Generate a diff folder for the diffs
###

# Get the root directory of the repository
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <commit1> <commit2>"
    exit 1
fi

###
### Download the bash colors file
###

# Create a temporary file
tmpfile=$(mktemp)

# Define a cleanup procedure
cleanup() {
    rm -f "$tmpfile"
}

# Use trap to call cleanup when the script exits
trap cleanup EXIT

# Download a file
curl -s -o "$tmpfile" "https://gist.githubusercontent.com/nirgeier/0fbe451bbd3001ced5fb48953734a4d6/raw"

# Source the downloaded script
source $tmpfile

echo -e   "${Yellow}* Getting the commit id of the desired commits/branches ${Color_Off}"
commit1=$(git rev-parse --short $1)
commit2=$(git rev-parse --short $2)

# Creare the commit folder
echo  -e  "${Yellow}* Creating the diff folde [$commit1-$commit2] ${Color_Off}"
DIFF_FOLDER=$ROOT_FOLDER/diff/$commit1-$commit2
mkdir -p $DIFF_FOLDER

# We need to proceess the diff from the root folder
cd $ROOT_FOLDER

# Get list of changed files
echo -e "${Yellow}* Creating the list of files${Color_Off}"
files=$(git diff --name-only $commit1 $commit2)

# Convert the list of files into an array
echo -e "${Yellow}* Convert the list of files into an array${Color_Off}"
IFS=$'\n' read -rd '' -a file_array <<<"$files"

# Loop over each file
echo -e "${Yellow}* Looping over the files${Color_Off}"
# Loop over each file
for file in "${file_array[@]}"; do
  
  # Set the diff file_name
  diff_file="$DIFF_FOLDER/${file//\//_}.diff"

  # Create a diff file for the file
  git diff $commit1 $commit2 -- "$file" > "$diff_file"
  
done


