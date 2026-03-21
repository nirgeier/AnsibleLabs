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
# 1. Create the playbook
# -------------------------------------------------------
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Creating lab017-packages.yml playbook${COLOR_OFF}"
echo -e "${Green}* Covers: apt (install packages), command (verify), service (manage services)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab017-packages.yml << 'EOF'
---
- name: Package and Service Modules Demo
  hosts: all
  become: true
  gather_facts: true

  vars:
    required_packages:
      - curl
      - wget
    web_server: nginx

  tasks:
    # --- Update apt cache ---
    - name: \"[apt] Update package cache\"
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
      when: ansible_os_family == \"Debian\"
      changed_when: false

    # --- Install curl and wget with apt ---
    - name: \"[apt] Install curl and wget\"
      ansible.builtin.apt:
        name: \"{{ required_packages }}\"
        state: present
      when: ansible_os_family == \"Debian\"

    # --- Verify curl is installed with command module ---
    - name: \"[command] Verify curl is installed\"
      ansible.builtin.command:
        cmd: curl --version
      register: curl_version
      changed_when: false

    - name: \"[debug] Show curl version\"
      ansible.builtin.debug:
        msg: \"curl installed: {{ curl_version.stdout_lines[0] }}\"

    # --- Verify wget is installed with command module ---
    - name: \"[command] Verify wget is installed\"
      ansible.builtin.command:
        cmd: wget --version
      register: wget_version
      changed_when: false

    - name: \"[debug] Show wget version\"
      ansible.builtin.debug:
        msg: \"wget installed: {{ wget_version.stdout_lines[0] }}\"

    # --- Install nginx web server ---
    - name: \"[apt] Install nginx web server\"
      ansible.builtin.apt:
        name: \"{{ web_server }}\"
        state: present
      when: ansible_os_family == \"Debian\"
      notify: Start nginx

    # --- Ensure nginx service is started and enabled ---
    - name: \"[service] Ensure nginx is started and enabled\"
      ansible.builtin.service:
        name: \"{{ web_server }}\"
        state: started
        enabled: true

    # --- Check nginx service status ---
    - name: \"[command] Check nginx service status\"
      ansible.builtin.command:
        cmd: nginx -v
      register: nginx_version
      changed_when: false

    - name: \"[debug] Show nginx version\"
      ansible.builtin.debug:
        msg: \"nginx installed: {{ nginx_version.stderr }}\"

  handlers:
    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
EOF"

echo -e "${GREEN}$ cat lab017-packages.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/lab017-packages.yml"

# -------------------------------------------------------
# 2. Run the playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Running lab017-packages.yml${COLOR_OFF}"
echo -e "${Red}* This will install curl, wget, and nginx - may take a minute${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab017-packages.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab017-packages.yml"

# -------------------------------------------------------
# 3. Verify with ad-hoc commands
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Verifying with ad-hoc commands${COLOR_OFF}"

echo -e ""
echo -e "${CYAN}-- Verify curl is installed on all servers --${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m command -a 'curl --version'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'curl --version'"

echo -e ""
echo -e "${CYAN}-- Verify wget is installed on all servers --${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m command -a 'wget --version'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'wget --version'"

echo -e ""
echo -e "${CYAN}-- Check nginx service status via service module --${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m service -a 'name=nginx state=started' --become${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m service -a 'name=nginx state=started' --become"

echo -e ""
echo -e "${CYAN}-- Check nginx version on all servers --${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m command -a 'nginx -v'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'nginx -v'"

# -------------------------------------------------------
# 4. Run again to confirm idempotency
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Run again to confirm idempotency (should show changed=0 for packages)${COLOR_OFF}"
echo -e "${Green}* apt module is idempotent - it won't reinstall already-present packages${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab017-packages.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab017-packages.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Summary:${COLOR_OFF}"
echo -e "  ${Green}apt              ${COLOR_OFF} → install/remove packages on Debian/Ubuntu"
echo -e "  ${Green}update_cache     ${COLOR_OFF} → refresh package lists (cache_valid_time avoids slow re-runs)"
echo -e "  ${Green}state: present   ${COLOR_OFF} → install if not already installed (idempotent)"
echo -e "  ${Green}service          ${COLOR_OFF} → start/stop/restart/enable services"
echo -e "  ${Green}when: os_family  ${COLOR_OFF} → guard apt tasks for cross-platform playbooks"
echo -e "  ${Green}notify + handler ${COLOR_OFF} → start service only when install task changes something"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
