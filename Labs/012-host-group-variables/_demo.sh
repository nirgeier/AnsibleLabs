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
# 1. Create group_vars and host_vars directory structure
# -------------------------------------------------------
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Creating group_vars/ and host_vars/ directories${COLOR_OFF}"
echo -e "${GREEN}$ docker exec ansible-controller sh -c \"mkdir -p /labs-scripts/group_vars /labs-scripts/host_vars\"${COLOR_OFF}"
docker exec ansible-controller sh -c "mkdir -p /labs-scripts/group_vars /labs-scripts/host_vars"

# -------------------------------------------------------
# 2. Create group_vars/all.yml
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Creating group_vars/all.yml (applies to every host)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/group_vars/all.yml << 'EOF'
---
ansible_user: root
ansible_python_interpreter: /usr/bin/python3
env: lab
ntp_server: pool.ntp.org
timezone: UTC
EOF"
echo -e "${GREEN}$ cat group_vars/all.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/group_vars/all.yml"

# -------------------------------------------------------
# 3. Create group_vars/servers.yml with http_port=80
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Creating group_vars/servers.yml (applies to [servers] group)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/group_vars/servers.yml << 'EOF'
---
http_port: 80
document_root: /var/www/html
server_role: generic-web
EOF"
echo -e "${GREEN}$ cat group_vars/servers.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/group_vars/servers.yml"

# -------------------------------------------------------
# 4. Create host_vars/linux-server-1.yml (overrides http_port)
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Creating host_vars/linux-server-1.yml (host-specific override)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/host_vars/linux-server-1.yml << 'EOF'
---
http_port: 8080
server_alias: primary-web
server_role: primary
EOF"
echo -e "${GREEN}$ cat host_vars/linux-server-1.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/host_vars/linux-server-1.yml"

echo -e ""
echo -e "${Red}* linux-server-1 will show http_port=8080 (host_vars overrides group_vars)${COLOR_OFF}"
echo -e "${Red}* all other servers will show http_port=80 (from group_vars/servers.yml)${COLOR_OFF}"

# -------------------------------------------------------
# 5. Create and run debug playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 5] Creating debug_vars.yml playbook${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/debug_vars.yml << 'EOF'
---
- name: Show host and group variables
  hosts: all
  gather_facts: true

  tasks:
    - name: Display host-specific variables
      ansible.builtin.debug:
        msg:
          - \"Host:          {{ inventory_hostname }}\"
          - \"Groups:        {{ group_names | join(', ') }}\"
          - \"HTTP Port:     {{ http_port | default('N/A') }}\"
          - \"OS:            {{ ansible_distribution }}\"
          - \"Environment:   {{ env | default('N/A') }}\"
          - \"NTP Server:    {{ ntp_server | default('N/A') }}\"
          - \"Server Role:   {{ server_role | default('N/A') }}\"
EOF"

echo -e ""
echo -e "${GREEN}$ ansible-playbook debug_vars.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook debug_vars.yml"

# -------------------------------------------------------
# 6. Override with -e flag
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 6] Override env variable at runtime using -e flag (highest precedence)${COLOR_OFF}"
echo -e "${Green}* Extra vars (-e) always win over ALL other variable definitions${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook debug_vars.yml -e \"env=production\"${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook debug_vars.yml -e 'env=production'"

# -------------------------------------------------------
# 7. Show hostvars magic variable
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 7] Using hostvars magic variable to inspect another host's variables${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/hostvars_demo.yml << 'EOF'
---
- name: Demonstrate hostvars magic variable
  hosts: all
  gather_facts: false

  tasks:
    - name: Show linux-server-1 http_port from any host
      ansible.builtin.debug:
        msg:
          - \"I am:                           {{ inventory_hostname }}\"
          - \"linux-server-1 http_port is:   {{ hostvars['linux-server-1']['http_port'] | default('N/A') }}\"
          - \"My http_port is:               {{ http_port | default('N/A') }}\"
EOF"
echo -e "${GREEN}$ ansible-playbook hostvars_demo.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook hostvars_demo.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Summary:${COLOR_OFF}"
echo -e "  ${Green}group_vars/all.yml    ${COLOR_OFF}→ applies to ALL hosts"
echo -e "  ${Green}group_vars/servers.yml${COLOR_OFF}→ applies to hosts in [servers] group"
echo -e "  ${Green}host_vars/<host>.yml  ${COLOR_OFF}→ applies to a single host (overrides group_vars)"
echo -e "  ${Green}-e 'var=value'        ${COLOR_OFF}→ command-line extra vars (highest precedence)"
echo -e "  ${Green}hostvars['host']      ${COLOR_OFF}→ access any host's variables from any task"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
