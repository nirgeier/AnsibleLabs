#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 020 - Ansible Tags${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create the tagged playbook${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab020-tags.yml << 'EOF'
---
- name: Lab 020 - Ansible Tags demo
  hosts: linux-server-1
  gather_facts: false

  tasks:
    - name: \"[INSTALL] Install curl\"
      ansible.builtin.package:
        name: curl
        state: present
      tags:
        - install

    - name: \"[INSTALL] Install vim\"
      ansible.builtin.package:
        name: vim
        state: present
      tags:
        - install

    - name: \"[CONFIGURE] Write app config file\"
      ansible.builtin.copy:
        content: |
          [app]
          mode=production
          log_level=info
        dest: /tmp/app.conf
        mode: '0644'
      tags:
        - configure

    - name: \"[CONFIGURE] Set hostname fact\"
      ansible.builtin.set_fact:
        app_host: \"{{ inventory_hostname }}\"
      tags:
        - configure

    - name: \"[VERIFY] Check curl is present\"
      ansible.builtin.command: which curl
      register: curl_check
      changed_when: false
      tags:
        - verify

    - name: \"[VERIFY] Show config file content\"
      ansible.builtin.command: cat /tmp/app.conf
      register: conf_content
      changed_when: false
      tags:
        - verify

    - name: \"[VERIFY] Display verification results\"
      ansible.builtin.debug:
        msg:
          - \"curl path: {{ curl_check.stdout }}\"
          - \"config: {{ conf_content.stdout_lines }}\"
      tags:
        - verify
EOF
echo 'lab020-tags.yml created.'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: List available tags${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab020-tags.yml --list-tags${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --list-tags"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Run ALL tasks (no tag filter)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab020-tags.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Run only 'install' tagged tasks${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab020-tags.yml --tags install${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --tags install"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: Run 'configure' and 'verify' tagged tasks${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab020-tags.yml --tags configure,verify${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --tags configure,verify"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 6: Skip the 'install' tasks${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab020-tags.yml --skip-tags install${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --skip-tags install"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 020 complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
