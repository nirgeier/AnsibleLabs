#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 030 - AWX / Ansible Automation Platform (AAP)${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${Red}NOTE: AWX/AAP requires a full Kubernetes/OpenShift cluster.${COLOR_OFF}"
echo -e "${Red}      This demo shows key concepts and runs the equivalent playbook locally.${COLOR_OFF}"

# -------------------------------------------------------
# 1. AWX/AAP Overview - key concepts
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] AWX/AAP Key Concepts Overview${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "  ${GREEN}Organizations${COLOR_OFF}   → Multi-tenant isolation (teams, projects, inventories)"
echo -e "  ${GREEN}Inventories${COLOR_OFF}     → Groups of managed hosts (static or dynamic)"
echo -e "  ${GREEN}Credentials${COLOR_OFF}     → Encrypted secrets (SSH keys, vault passwords, cloud tokens)"
echo -e "  ${GREEN}Projects${COLOR_OFF}        → Git repository containing playbooks"
echo -e "  ${GREEN}Job Templates${COLOR_OFF}   → Reusable playbook execution definitions"
echo -e "  ${GREEN}Workflows${COLOR_OFF}       → Chain multiple Job Templates with conditionals"
echo -e "  ${GREEN}RBAC${COLOR_OFF}            → Role-based access control per resource"
echo -e "  ${GREEN}Schedules${COLOR_OFF}       → Cron-like triggers for Job Templates"

# -------------------------------------------------------
# 2. Sample Job Template config (YAML format)
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Creating a sample AWX Job Template definition (YAML)${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/awx-job-template.yml << 'EOF'
---
# AWX / AAP Job Template definition (as-code via awx.awx collection)
# This would be applied with: ansible-playbook configure-awx.yml
name: Deploy Web Application
description: Deploys the web application to production servers
organization: Default
project: MyWebApp
playbook: deploy.yml
inventory: Production Inventory
credentials:
  - Production SSH Key
  - Vault Password
verbosity: 1
extra_vars:
  app_version: \"{{ app_version | default('latest') }}\"
  deploy_env: production
ask_variables_on_launch: true
ask_limit_on_launch: true
concurrent_jobs_enabled: false
EOF
echo '=== AWX Job Template YAML ==='
cat /labs-scripts/awx-job-template.yml"

# -------------------------------------------------------
# 3. AWX Inventory YAML
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Creating an AWX Inventory definition${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/awx-inventory.yml << 'EOF'
---
# AWX Inventory as-code (awx.awx.inventory module)
name: Production Inventory
organization: Default
kind: ''  # '' = regular inventory, 'smart' = smart inventory

# Inventory sources (dynamic - pulls from external sources)
sources:
  - name: AWS EC2 Source
    source: ec2
    credential: AWS Credentials
    overwrite: true
    update_on_launch: true
    source_vars:
      regions:
        - us-east-1
        - eu-west-1
      filters:
        tag:Environment: production

# Static groups and hosts (also configurable)
groups:
  - name: webservers
    hosts:
      - web-01
      - web-02
  - name: databases
    hosts:
      - db-01
EOF
echo '=== AWX Inventory YAML ==='
cat /labs-scripts/awx-inventory.yml"

# -------------------------------------------------------
# 4. AWX Workflow definition
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Showing what an AWX Workflow looks like${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/awx-workflow.yml << 'EOF'
---
# AWX Workflow Job Template definition
# Workflows chain multiple Job Templates together
name: Full Deploy Pipeline
organization: Default
schema:
  - identifier: node-build
    unified_job_template: Build Application
    success_nodes:
      - node-test
    failure_nodes:
      - node-notify-failure

  - identifier: node-test
    unified_job_template: Run Integration Tests
    success_nodes:
      - node-deploy
    failure_nodes:
      - node-notify-failure

  - identifier: node-deploy
    unified_job_template: Deploy Web Application
    success_nodes:
      - node-notify-success

  - identifier: node-notify-success
    unified_job_template: Send Success Notification

  - identifier: node-notify-failure
    unified_job_template: Send Failure Notification
EOF
echo '=== AWX Workflow Definition ==='
cat /labs-scripts/awx-workflow.yml"

# -------------------------------------------------------
# 5. Equivalent playbook AWX would execute
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 5] Creating the equivalent playbook AWX would run${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab030-awx-equivalent.yml << 'EOF'
---
# This is the equivalent of what AWX executes behind the scenes
# AWX adds: credential injection, RBAC, logging, notifications, and UI
- name: Lab 030 - AWX Equivalent Playbook (runs locally)
  hosts: all
  gather_facts: true

  vars:
    app_version: \"1.0.0\"
    deploy_env: lab

  tasks:
    - name: Show AWX would inject these facts automatically
      ansible.builtin.debug:
        msg:
          - \"AWX Job ID:       (would be injected by AWX as awx_job_id)\"
          - \"AWX Job Template: (would be injected by AWX as awx_job_template_name)\"
          - \"Host:             {{ inventory_hostname }}\"
          - \"App Version:      {{ app_version }}\"
          - \"Deploy Env:       {{ deploy_env }}\"
          - \"OS:               {{ ansible_distribution }} {{ ansible_distribution_version }}\"

    - name: Simulate deployment step - create app directory
      ansible.builtin.file:
        path: /tmp/myapp-{{ app_version }}
        state: directory
        mode: '0755'

    - name: Simulate deployment step - write app config
      ansible.builtin.copy:
        dest: /tmp/myapp-{{ app_version }}/config.json
        content: |
          {
            \"version\": \"{{ app_version }}\",
            \"environment\": \"{{ deploy_env }}\",
            \"deployed_at\": \"{{ ansible_date_time.iso8601 }}\",
            \"deployed_by\": \"ansible (AWX in production)\"
          }
        mode: '0644'

    - name: Read and display the config
      ansible.builtin.command: cat /tmp/myapp-{{ app_version }}/config.json
      register: config_content
      changed_when: false

    - name: Show deployed config
      ansible.builtin.debug:
        msg: "{{ config_content.stdout_lines }}"
EOF"

# -------------------------------------------------------
# 6. Run the equivalent playbook locally
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 6] Running the equivalent playbook locally${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab030-awx-equivalent.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab030-awx-equivalent.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 030 complete!${COLOR_OFF}"
echo -e "  ${GREEN}AWX/AAP wraps playbooks with:${COLOR_OFF} RBAC, credential vaulting, logging, UI, notifications"
echo -e "  ${GREEN}Job Templates${COLOR_OFF} = playbook + inventory + credentials bundled together"
echo -e "  ${GREEN}Workflows${COLOR_OFF}     = chained Job Templates with success/failure branching"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
