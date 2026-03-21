#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 031 - Facts Deep Dive${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# -------------------------------------------------------
# 1. Full setup run and grep for distribution
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Gathering ALL facts and filtering for distribution info${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m setup | grep ansible_distribution${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup | grep ansible_distribution"

# -------------------------------------------------------
# 2. Targeted fact filter
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Using filter= to gather only distribution facts (much faster)${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m setup -a 'filter=ansible_distribution*'${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_distribution*'"

# -------------------------------------------------------
# 3. Create custom facts on the servers
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Creating custom facts in /etc/ansible/facts.d/ on managed hosts${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab031-custom-facts-deploy.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab031-custom-facts-deploy.yml << 'EOF'
---
- name: Deploy custom facts to managed hosts
  hosts: all
  gather_facts: false

  tasks:
    - name: Ensure /etc/ansible/facts.d directory exists
      ansible.builtin.file:
        path: /etc/ansible/facts.d
        state: directory
        mode: '0755'

    - name: Deploy custom application fact file
      ansible.builtin.copy:
        dest: /etc/ansible/facts.d/app.fact
        content: |
          [application]
          name=mywebapp
          version=2.3.1
          environment=lab
          last_deployed=2024-01-15

          [infrastructure]
          tier=web
          region=eu-west-1
          datacenter=dc-01
        mode: '0644'
EOF
ansible-playbook /labs-scripts/lab031-custom-facts-deploy.yml"

# -------------------------------------------------------
# 4. Re-gather facts and show ansible_local
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Re-gathering facts to pick up ansible_local (custom facts)${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m setup -a 'filter=ansible_local'${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_local'"

# -------------------------------------------------------
# 5. Fact caching - configure jsonfile cache
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 5] Demonstrating fact caching with jsonfile backend${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "mkdir -p /labs-scripts/fact_cache && cat > /labs-scripts/ansible-caching.cfg << 'EOF'
[defaults]
inventory        = /labs-scripts/inventory
remote_user      = root
host_key_checking = False
gathering        = smart
fact_caching     = jsonfile
fact_caching_connection = /labs-scripts/fact_cache
fact_caching_timeout = 3600
EOF"

echo -e "${CYAN}First run (cold cache) - facts are gathered from hosts:${COLOR_OFF}"
echo -e "${GREEN}$ ANSIBLE_CONFIG=ansible-caching.cfg ansible all -m setup -a 'filter=ansible_os_family'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && time ANSIBLE_CONFIG=/labs-scripts/ansible-caching.cfg ansible all -m setup -a 'filter=ansible_os_family' 2>&1"

echo -e ""
echo -e "${CYAN}Second run (warm cache) - facts served from disk, much faster:${COLOR_OFF}"
echo -e "${GREEN}$ ANSIBLE_CONFIG=ansible-caching.cfg ansible all -m setup -a 'filter=ansible_os_family'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && time ANSIBLE_CONFIG=/labs-scripts/ansible-caching.cfg ansible all -m setup -a 'filter=ansible_os_family' 2>&1"

echo -e ""
echo -e "${CYAN}Cached fact files written to disk:${COLOR_OFF}"
docker exec ansible-controller sh -c "ls -la /labs-scripts/fact_cache/ && echo '---' && cat /labs-scripts/fact_cache/linux-server-1 | python3 -m json.tool | head -20 || true"

# -------------------------------------------------------
# 6. Selective gather_subset playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 6] Using gather_subset to collect only specific fact categories${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab031-gather-subset.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab031-gather-subset.yml << 'EOF'
---
- name: Lab 031 - Selective fact gathering with gather_subset
  hosts: all
  gather_facts: true
  gather_subset:
    - network
    - hardware
    - '!facter'
    - '!ohai'

  tasks:
    - name: Show network facts only
      ansible.builtin.debug:
        msg:
          - \"Hostname:        {{ ansible_hostname }}\"
          - \"Default IPv4:    {{ ansible_default_ipv4.address | default('N/A') }}\"
          - \"All interfaces:  {{ ansible_interfaces | join(', ') }}\"
          - \"Total memory:    {{ ansible_memtotal_mb | default('N/A') }} MB\"
          - \"CPU cores:       {{ ansible_processor_vcpus | default('N/A') }}\"

    - name: Use custom fact from ansible_local
      ansible.builtin.debug:
        msg:
          - \"App name:        {{ ansible_local.app.application.name | default('N/A') }}\"
          - \"App version:     {{ ansible_local.app.application.version | default('N/A') }}\"
          - \"App environment: {{ ansible_local.app.application.environment | default('N/A') }}\"
          - \"Infra tier:      {{ ansible_local.app.infrastructure.tier | default('N/A') }}\"
EOF
ansible-playbook /labs-scripts/lab031-gather-subset.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 031 complete!${COLOR_OFF}"
echo -e "  ${GREEN}ansible_local${COLOR_OFF}    → populated from /etc/ansible/facts.d/*.fact files"
echo -e "  ${GREEN}gather_subset${COLOR_OFF}    → limit which fact categories are collected"
echo -e "  ${GREEN}fact_caching${COLOR_OFF}     → cache facts to disk/redis to speed up repeated runs"
echo -e "  ${GREEN}filter=pattern${COLOR_OFF}   → ad-hoc fact filtering for targeted queries"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
