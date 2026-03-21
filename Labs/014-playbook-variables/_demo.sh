#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

# -------------------------------------------------------
# 1. Create vars file
# -------------------------------------------------------
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Creating vars/lab014.yml variable file${COLOR_OFF}"
docker exec ansible-controller sh -c "mkdir -p /labs-scripts/vars"
docker exec ansible-controller sh -c "cat > /labs-scripts/vars/lab014.yml << 'EOF'
---
greeting: \"Welcome to Ansible Labs!\"
lab_number: 14
app_version: \"1.0\"
packages:
  - curl
  - vim
  - git
server_config:
  port: 8080
  max_connections: 50
  debug: false
EOF"
echo -e "${GREEN}$ cat vars/lab014.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/vars/lab014.yml"

# -------------------------------------------------------
# 2. Create the playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Creating lab014-vars.yml playbook${COLOR_OFF}"
echo -e "${Green}* Demonstrates: play-level vars, vars_files, set_fact, register+debug, default filter${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab014-vars.yml << 'EOF'
---
- name: Playbook Variables Demo
  hosts: all
  gather_facts: true
  vars_files:
    - vars/lab014.yml
  vars:
    inline_var: \"I was defined inline in the play\"
    deploy_env: staging

  tasks:
    - name: \"[play vars] Show greeting from vars_files\"
      ansible.builtin.debug:
        msg: \"{{ greeting }} (Lab {{ lab_number }}, version {{ app_version }})\"

    - name: \"[play vars] Show inline variable\"
      ansible.builtin.debug:
        msg: \"{{ inline_var }}\"

    - name: \"[play vars] Show package list using join filter\"
      ansible.builtin.debug:
        msg: \"Packages to install: {{ packages | join(', ') }}\"

    - name: \"[play vars] Show dictionary variable (dot notation)\"
      ansible.builtin.debug:
        msg:
          - \"Server port:        {{ server_config.port }}\"
          - \"Max connections:    {{ server_config.max_connections }}\"
          - \"Debug mode:         {{ server_config.debug }}\"

    - name: \"[register] Capture hostname command output\"
      ansible.builtin.command:
        cmd: hostname
      register: hostname_result
      changed_when: false

    - name: \"[register] Show captured output\"
      ansible.builtin.debug:
        msg:
          - \"stdout:      {{ hostname_result.stdout }}\"
          - \"return code: {{ hostname_result.rc }}\"
          - \"changed:     {{ hostname_result.changed }}\"

    - name: \"[set_fact] Build derived server_url variable\"
      ansible.builtin.set_fact:
        server_url: \"http://{{ ansible_default_ipv4.address }}:{{ server_config.port }}\"
        deploy_label: \"{{ deploy_env | upper }}-{{ inventory_hostname }}\"

    - name: \"[set_fact] Show derived facts\"
      ansible.builtin.debug:
        msg:
          - \"Server URL:    {{ server_url }}\"
          - \"Deploy label:  {{ deploy_label }}\"

    - name: \"[default filter] Show variable with fallback (undefined_var not set)\"
      ansible.builtin.debug:
        msg: \"Timeout: {{ undefined_var | default('30s') }}\"
EOF"

echo -e "${GREEN}$ cat lab014-vars.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/lab014-vars.yml"

# -------------------------------------------------------
# 3. Run the playbook (first run)
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Running the playbook (app_version=1.0 from vars file)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab014-vars.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab014-vars.yml"

# -------------------------------------------------------
# 4. Run again with -e override
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Override app_version at runtime with -e flag${COLOR_OFF}"
echo -e "${Red}* Extra vars (-e) have the HIGHEST precedence - they always win${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab014-vars.yml -e \"app_version=2.0\"${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab014-vars.yml -e 'app_version=2.0'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Summary:${COLOR_OFF}"
echo -e "  ${Green}vars:        ${COLOR_OFF} → inline variables in the play"
echo -e "  ${Green}vars_files:  ${COLOR_OFF} → load variables from external YAML files"
echo -e "  ${Green}register:    ${COLOR_OFF} → capture task output (.stdout, .rc, .changed)"
echo -e "  ${Green}set_fact:    ${COLOR_OFF} → create/derive variables during the play"
echo -e "  ${Green}| default() ${COLOR_OFF} → provide fallback for undefined variables"
echo -e "  ${Green}-e 'k=v'    ${COLOR_OFF} → override any variable at runtime (highest priority)"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
