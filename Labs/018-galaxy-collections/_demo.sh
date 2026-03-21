#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 018 - Ansible Galaxy Collections${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${GREEN}$ ansible-galaxy collection list${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection list"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${GREEN}$ ansible-galaxy collection install community.general${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection install community.general"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${GREEN}$ ansible-doc community.general.ini_file | head -30${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "ansible-doc community.general.ini_file | head -30"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Creating a playbook that uses community.general.ini_file module${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab018-galaxy.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab018-galaxy.yml << 'EOF'
---
- name: Lab 018 - Using community.general collection
  hosts: linux-server-1
  gather_facts: false

  tasks:
    - name: Ensure /tmp/app.ini exists with a section
      community.general.ini_file:
        path: /tmp/app.ini
        section: app
        option: version
        value: \"1.0.0\"
        mode: '0644'

    - name: Add another key to the ini file
      community.general.ini_file:
        path: /tmp/app.ini
        section: app
        option: environment
        value: production
        mode: '0644'

    - name: Read the ini file content
      ansible.builtin.command: cat /tmp/app.ini
      register: ini_content
      changed_when: false

    - name: Show ini file content
      ansible.builtin.debug:
        msg: \"{{ ini_content.stdout_lines }}\"
EOF
ansible-playbook lab018-galaxy.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Creating requirements.yml and installing from it${COLOR_OFF}"
echo -e "${GREEN}$ ansible-galaxy collection install -r requirements.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat > requirements.yml << 'EOF'
---
collections:
  - name: community.general
    version: \">=7.0.0\"
  - name: ansible.posix
EOF
ansible-galaxy collection install -r requirements.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${GREEN}$ ansible-galaxy collection list${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "ansible-galaxy collection list"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 018 complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
