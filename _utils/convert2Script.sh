#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Directory containing the files
dir="$ROOT_FOLDER/Labs/000-setup"

# Output file
output_file="$ROOT_FOLDER/output.sh"

# Start the output file
echo "#!/bin/bash" > $output_file

# Recursive function
process_files() {
    for file in "$1"/*; do
        if [ -d "$file" ]; 
            then
            process_files "$file"
        elif [ -f "$file" ] && [ $(basename "$file") != "README.md" ]; 
            then
            echo "Processing $file"
            relative_path=$(python3 -c "import os.path; print(os.path.relpath('$file', '$dir'))")
            mkdir -p "$(dirname "$relative_path")"
            echo "mkdir -p \"$(dirname "$relative_path")\"" >> $output_file
            echo "cat << 'EOF' > $relative_path" >> $output_file
            cat "$file" >> $output_file
            echo "" >> $output_file
            echo "EOF" >> $output_file
            echo "" >> $output_file
        fi
    done
}

# Call the function on the directory
process_files "$dir"