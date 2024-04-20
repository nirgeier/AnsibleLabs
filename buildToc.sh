#!/bin/bash

# Get the current directory
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Set the output file name
OUTPUT_FILE=$BASE_DIR/README-Labs.md

# Create the output file
touch $OUTPUT_FILE

# Navigate to the Labs directory
cd Labs

# Create or clear the README.md file
echo "# List of labs" > $OUTPUT_FILE

echo "" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
# Create or clear the README.md file
echo "| Lab Name | Description |" >> $OUTPUT_FILE
echo "| -------- | ----------- |" >> $OUTPUT_FILE

# Loop over all directories (labs)
for lab in $(ls -d */); do
    # Remove trailing slash from directory name
    labname=${lab%%/}
    # Add directory to the README.md with a link
    echo "| [${labname}](./Labs/${labname})| ${labname} |" >> $OUTPUT_FILE
done

cat $OUTPUT_FILE

