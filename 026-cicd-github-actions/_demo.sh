#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 026 - CI/CD with GitHub Actions${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Note: GitHub Actions cannot run locally - we create the workflow files${COLOR_OFF}"
echo -e "${CYAN}      and simulate what each workflow step does inside the controller${COLOR_OFF}"

# Step 1: Create the GitHub Actions workflow directory and deployment workflow
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create .github/workflows/ansible-deploy.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "mkdir -p /labs-scripts/.github/workflows && cat > /labs-scripts/.github/workflows/ansible-deploy.yml << 'EOF'
# .github/workflows/ansible-deploy.yml
name: Ansible Deployment

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install Ansible and lint
        run: pip install ansible ansible-lint

      - name: Run ansible-lint
        run: ansible-lint site.yml || true

      - name: Syntax check
        run: ansible-playbook site.yml --syntax-check

      - name: Dry run (check mode)
        run: |
          ansible-playbook site.yml --check \
            -e \"target_env=\${{ github.event.inputs.environment || 'staging' }}\"

      - name: Deploy
        if: github.ref == 'refs/heads/main'
        run: |
          ansible-playbook site.yml \
            -e \"target_env=\${{ github.event.inputs.environment || 'staging' }}\"
EOF"

echo -e "${GREEN}$ cat .github/workflows/ansible-deploy.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/.github/workflows/ansible-deploy.yml"

# Step 2: Create the lint-only workflow
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: Create .github/workflows/lint.yml (PR quality gate)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/.github/workflows/lint.yml << 'EOF'
# .github/workflows/lint.yml
name: Ansible Lint

on:
  pull_request:
    branches: [main]
    paths:
      - '**.yml'
      - '**.yaml'

jobs:
  lint:
    runs-on: ubuntu-latest
    name: Lint Ansible code

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install ansible-lint
        run: pip install ansible ansible-lint

      - name: Run ansible-lint
        run: ansible-lint --profile moderate site.yml || true

      - name: Syntax check all playbooks
        run: |
          for playbook in *.yml; do
            echo \"Checking: \$playbook\"
            ansible-playbook \"\$playbook\" --syntax-check || true
          done
EOF"

echo -e "${GREEN}$ cat .github/workflows/lint.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/.github/workflows/lint.yml"

# Ensure site.yml exists (reuse from lab 025 or create it)
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Ensuring site.yml exists for simulation steps...${COLOR_OFF}"
docker exec ansible-controller sh -c "[ -f /labs-scripts/site.yml ] || cat > /labs-scripts/site.yml << 'EOF'
---
- name: Application Deployment
  hosts: all
  become: true
  gather_facts: true

  vars:
    app_version: \"{{ app_version | default('1.0.0') }}\"
    target_env: \"{{ target_env | default('development') }}\"

  tasks:
    - name: Show deployment info
      ansible.builtin.debug:
        msg:
          - \"Deploying version {{ app_version }} to {{ target_env }}\"
          - \"Target host: {{ inventory_hostname }}\"

    - name: Create deployment directory
      ansible.builtin.file:
        path: \"/opt/deployments/{{ app_version }}\"
        state: directory
        mode: \"0755\"

    - name: Create version file
      ansible.builtin.copy:
        content: |
          version={{ app_version }}
          environment={{ target_env }}
          deployed_by=ansible
        dest: \"/opt/deployments/{{ app_version }}/version.txt\"
        mode: \"0644\"
EOF"

# Step 3: Simulate the workflow - Syntax check
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Simulate GitHub Actions - 'Syntax check' step${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook site.yml --syntax-check${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --syntax-check"

# Step 4: Simulate the workflow - Lint
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Simulate GitHub Actions - 'Run ansible-lint' step${COLOR_OFF}"
echo -e "${GREEN}$ ansible-lint site.yml || true${COLOR_OFF}"
docker exec ansible-controller sh -c "pip3 install ansible-lint --quiet && cd /labs-scripts && ansible-lint site.yml || true"

# Step 5: Simulate the workflow - Dry run
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: Simulate GitHub Actions - 'Dry run (check mode)' step${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook site.yml --check -e 'target_env=staging'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check -e 'target_env=staging'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Workflow files created in .github/workflows/:${COLOR_OFF}"
docker exec ansible-controller sh -c "ls -la /labs-scripts/.github/workflows/"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 026 - Complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
