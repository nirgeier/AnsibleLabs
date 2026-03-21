#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 022 - Ansible Debugging${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create the debug playbook${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab022-debug.yml << 'EOF'
---
- name: Lab 022 - Ansible Debugging demo
  hosts: linux-server-1
  gather_facts: true

  vars:
    app_version: \"2.5.1\"
    debug_message: \"Debugging with Ansible is easy!\"

  tasks:
    - name: Debug a simple message
      ansible.builtin.debug:
        msg: \"{{ debug_message }}\"

    - name: Debug a variable directly
      ansible.builtin.debug:
        var: app_version

    - name: Debug ansible_hostname fact
      ansible.builtin.debug:
        var: ansible_hostname

    - name: Debug only at verbosity level 1 (-v)
      ansible.builtin.debug:
        msg: \"This message appears at verbosity >= 1\"
        verbosity: 1

    - name: Debug only at verbosity level 2 (-vv)
      ansible.builtin.debug:
        msg: \"This message appears at verbosity >= 2\"
        verbosity: 2

    - name: Run a command and register its output
      ansible.builtin.command: uptime
      register: uptime_result
      changed_when: false

    - name: Show registered variable content
      ansible.builtin.debug:
        var: uptime_result

    - name: Command that might fail - using failed_when to suppress failure
      ansible.builtin.command: ls /nonexistent_directory
      register: ls_result
      failed_when: false

    - name: Show the result of the \"safe\" failure
      ansible.builtin.debug:
        msg:
          - \"Return code : {{ ls_result.rc }}\"
          - \"Stderr      : {{ ls_result.stderr }}\"
          - \"The task did not abort the playbook thanks to failed_when: false\"
EOF
echo 'lab022-debug.yml created.'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: Run normally (verbosity=0, no -v flag)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab022-debug.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Run with -v (verbosity=1, reveals hidden debug messages)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab022-debug.yml -v${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml -v"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Dry run with --check --diff (no changes made)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab022-debug.yml --check --diff${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml --check --diff"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: Ad-hoc debug message across all hosts${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m debug -a 'msg=\"Hello from ad-hoc debug\"'${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m debug -a 'msg=\"Hello from ad-hoc debug\"'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 6: Ad-hoc gather and display a specific fact${COLOR_OFF}"
echo -e "${GREEN}$ ansible linux-server-1 -m setup -a 'filter=ansible_os_family'${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m setup -a 'filter=ansible_os_family'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 022 complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
