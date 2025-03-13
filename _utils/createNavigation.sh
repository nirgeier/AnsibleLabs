
#!/bin/bash

###
### This script will create the tests for this repository
### 

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Set the base folder for our labs
LABS_FOLDER="$ROOT_FOLDER/Labs/"

# Search for the folder with README
demoFiles=$(find $ROOT_FOLDER -name 'README' | sort -u)

# Get all directories in the current path
LABS=($(ls -d $ROOT_FOLDER/Labs/*/ | sed 's#/##'))

# Loop through directories
for ((i=0; i<${#LABS[@]}; i++)); do
    # Get current directory
    CURRENT=${LABS[i]}
    PREVIOUS=""
    NEXT=""
    
    # Get previous directory (if exists)
    if      ((i > 0)); 
    then    PREVIOUS=${LABS[i-1]}; 
    fi
    
    # Get next directory (if exists)
    if      ((i < ${#LABS[@]}-1)); 
    then    NEXT=${LABS[i+1]}; 
    fi
    
    # Escape special characters in previous and current values to prevent sed issues
    ESC_PREVIOUS=/Labs/$(sed 's/[\/&]/\\&/g' <<< "$(basename $PREVIOUS)")
    ESC_CURRENT=/Labs/$(sed 's/[\/&]/\\&/g' <<< "$(basename $CURRENT)")
    ESC_NEXT=/Labs/$(sed 's/[\/&]/\\&/g' <<< "$(basename $NEXT)")

read -r -d '' navigation_text <<EOF
<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
  <a href="$ESC_PREVIOUS">:arrow_backward: $ESC_PREVIOUS</a>
  &emsp;<a href="/Labs">Back to labs list</a>
  &emsp;<a href="$ESC_NEXT">$ESC_NEXT :arrow_forward:</a>
</p>
<p style="text-align: center; font-size: 12px;">  
<span style="color: #F04F32;">&copy;</span> <span style="color: #2AA9E1;">Code</span><span style="color: #F9B233;">Wizard</span> 2025
</p>  
<!--- Labs Navigation End -->
EOF

    # Escape special characters in previous and current values to prevent sed issues
    ESC_TEXT=$(sed -e 's/[\/&]/\\&/g' -e '$!s/$/\\/' <<< "$navigation_text")

    # Replace the content between the navigation comments with dynamic content
    sed -i '' -e "/<!--- Labs Navigation Start -->/,/<!--- Labs Navigation End -->/c\\
$ESC_TEXT" /${CURRENT}README.md
done
