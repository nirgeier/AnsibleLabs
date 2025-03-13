
#!/bin/bash

###
### This script will create the tests for this repository
### 

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Set the base folder for our labs
LABS_FOLDER="$ROOT_FOLDER/Labs/"

# Search for the folder to test
demoFiles=$(find $ROOT_FOLDER -name '*_demo.sh' | sort -u)

# Labs build status file
labsStatus=$ROOT_FOLDER/tests/README.md

# Write the status file header
echo "| Lab  | Build Status |" > $labsStatus
echo "| -  | - |" >> $labsStatus

# Loop over the test folders
for file in $demoFiles
do
    # Get the path to the folder
    labPath=$(dirname ${file#$LABS_FOLDER})

    # Get the path to the folder
    labId=$(basename $(dirname $file))

    escapedLabPath=$(echo $labPath | sed 's/\//\\\//g')
    # Replace tokens with values and write to a new file
    gsed -e "s/<LAB_ID>/$labId/g" ${ROOT_FOLDER}/tests/test-template.yaml  | \
    gsed -e "s/<LAB_PATH>/Labs\/$escapedLabPath/g" > $ROOT_FOLDER/.github/workflows/${labId}.yaml 
    
    # Add the build status
    echo    "| [$labId](/Labs/$labPath) " \
            "| <a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/${labId}.yaml">"              \
            "<img src=\"https://github.com/nirgeier/AnsibleLabs/actions/workflows/${labId}.yaml/badge.svg\"> "  \
            "</a>" >> $labsStatus
done

# Format (Beautify) the build status
# You will need to install the following packages
###
### pip install mdformat-gfm
###
mdformat $labsStatus

pushd . > /dev/null

cd $ROOT_FOLDER/tests/
pwd
# Delete old Lab content
gsed -i '/<!-- Labs List start -->/,/<!-- Labs List end -->/{{//!d}}' $ROOT_FOLDER/README.md

# Append the new Lab content
gsed -i '/<!-- Labs List start -->/r ./README.md' $ROOT_FOLDER/README.md

popd . > /dev/null

# Move the readme to the main Labs folder
mv $labsStatus $ROOT_FOLDER/Labs/

