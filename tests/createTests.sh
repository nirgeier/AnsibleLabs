#!/bin/bash

###
### This script will create the tests for this repository
### 

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Set the base folder for our labs
LABS_FOLDER="$ROOT_FOLDER/Labs/"

# Get all directories in the current path
LABS=($(ls -d $ROOT_FOLDER/Labs/*/ | sed 's#/##'))

# Set the base folder for our labs build status file
labsStatus=$ROOT_FOLDER/tests/README.md

# Write the status file header
echo "| Lab  | Build Status |" > $labsStatus
echo "| -  | - |" >> $labsStatus

# Loop through directories
for ((i=0; i<${#LABS[@]}; i++)); do
    # Get current directory
    CURRENT=${LABS[i]}
    PREVIOUS=""
    NEXT=""
    
    # Escape special characters in previous and current values to prevent sed issues
    ESC_CURRENT="/Labs/$(sed 's/[\/&]/\\&/g' <<< "$(basename "$CURRENT")")"
    
    # Get previous directory (if exists)
    if ((i > 0)); then
        PREVIOUS=${LABS[i-1]}
        # Escape special characters in previous and current values to prevent sed issues
        ESC_PREVIOUS="/Labs/$(sed 's/[\/&]/\\&/g' <<< "$(basename "$PREVIOUS")")"
    fi
    
    # Get next directory (if exists)
    if ((i < ${#LABS[@]}-1)); then
        NEXT=${LABS[i+1]}
        # Escape special characters in previous and current values to prevent sed issues
        ESC_NEXT="/Labs/$(sed 's/[\/&]/\\&/g' <<< "$(basename "$NEXT")")"
    fi
    
    read -r -d '' replacement_text <<EOF
<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
    <a href="$ESC_PREVIOUS">:arrow_backward: $ESC_PREVIOUS</a>
    &emsp;<a href="/Labs">Back to labs list</a>
    &emsp;<a href="$ESC_NEXT">$ESC_NEXT :arrow_forward:</a>
</p>
<!--- Labs Navigation End -->
EOF

    # Escape special characters AND preserve newlines for sed
    ESC_TEXT=$(sed -e 's/[\/&]/\\&/g' -e '$!s/$/\\/' <<< "$replacement_text")

    # Replace the content between the navigation comments with dynamic content
    sed -i '' -e "/<!--- Labs Navigation Start -->/,/<!--- Labs Navigation End -->/c\\
$ESC_TEXT" "/${CURRENT}README.md"
done

# Search for the folder with _demo
DEMO_FILES=$(find $LABS_FOLDER -name '*_demo.sh' | sort -u)



# Loop over the test folders
for file in $DEMO_FILES
do
    # Get the path to the Labs folder
    labPath=$(dirname ${file#$LABS_FOLDER})

    # Get the path to the test folder
    labId=$(basename $(dirname $file))

    # Define the name of the workflow 
    workflowName="Lab-${labId:0:3}.yaml"

    escapedLabPath=$(echo $labPath | sed 's/\//\\\//g')
    # Replace tokens with values and write to a new file
    gsed -e "s/<LAB_ID>/$workflowName/g" ${ROOT_FOLDER}/tests/test-template.yaml  | \
    gsed -e "s/<LAB_PATH>/Labs\/$escapedLabPath/g" > $ROOT_FOLDER/.github/workflows/${labId}.yaml 
    
    # Add the build status
    echo    "| [$labId](/Labs/$labPath) " \
            "| <a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/${labId}.yaml">"              \
            "<img src=\"https://github.com/nirgeier/AnsibleLabs/actions/workflows/${labId}.yaml/badge.svg\"> "  \
            "</a>" >> $labsStatus
done

