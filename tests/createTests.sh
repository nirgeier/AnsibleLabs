#!/bin/bash

###
### This script will create the tests for this repository
###

set -euo pipefail

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Set the base folder for our labs
LABS_FOLDER="$ROOT_FOLDER/Labs/"

# Portable sed: use gsed on macOS if available, otherwise plain sed
if command -v gsed >/dev/null 2>&1; then
    SED=gsed
else
    SED=sed
fi

# Ensure the workflows directory exists
mkdir -p "$ROOT_FOLDER/.github/workflows"

# Get all lab directories (sorted), strip trailing slash
mapfile -t LABS < <(find "$ROOT_FOLDER/Labs" -mindepth 1 -maxdepth 1 -type d | sort)

# Set the base folder for our labs build status file
labsStatus="$ROOT_FOLDER/tests/README.md"

# Write the status file header
cat >"$labsStatus" <<'HEADER'
# Ansible Labs - Build Status

| Lab | Build Status |
| --- | ------------ |
HEADER

# ── Workflow generation ───────────────────────────────────────────────────────
# Find all _demo.sh files and generate a GitHub workflow for each
DEMO_FILES=$(find "$LABS_FOLDER" -name '_demo.sh' | sort)

for file in $DEMO_FILES; do
    # labPath  = e.g. "012-host-group-variables"
    labPath=$(basename "$(dirname "$file")")
    labId="$labPath"

    # workflowName = e.g. "Lab-012.yaml"
    workflowName="Lab-${labId:0:3}.yaml"

    # Generate workflow from template
    $SED -e "s|<LAB_ID>|${workflowName}|g" \
        -e "s|<LAB_PATH>|Labs/${labPath}|g" \
        "${ROOT_FOLDER}/tests/test-template.yaml" \
        >"${ROOT_FOLDER}/.github/workflows/${labId}.yaml"

    echo "  Generated: .github/workflows/${labId}.yaml"

    # Append build badge row to tests/README.md
    echo "| [${labId}](https://nirgeier.github.io/AnsibleLabs/${labPath}/) | [![${labId}](https://github.com/nirgeier/AnsibleLabs/actions/workflows/${labId}.yaml/badge.svg)](https://github.com/nirgeier/AnsibleLabs/actions/workflows/${labId}.yaml) |" \
        >>"$labsStatus"
done

echo ""
echo "Done. Workflows written to .github/workflows/"
echo "Build status table written to tests/README.md"
