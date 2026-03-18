#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 023 - Ansible Idempotency${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create the idempotent playbook${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab023-idempotency.yml << 'EOF'
---
- name: Lab 023 - Idempotency demo
  hosts: linux-server-1
  gather_facts: false

  tasks:
    - name: Ensure /tmp/idempotency-demo directory exists
      ansible.builtin.file:
        path: /tmp/idempotency-demo
        state: directory
        mode: '0755'

    - name: Ensure config file is present with specific content
      ansible.builtin.copy:
        content: |
          # Managed by Ansible
          app_name=demo
          version=1.0.0
          environment=production
        dest: /tmp/idempotency-demo/app.conf
        mode: '0644'

    - name: Ensure a specific line is present in the config
      ansible.builtin.lineinfile:
        path: /tmp/idempotency-demo/app.conf
        line: \"log_level=info\"
        state: present

    - name: Ensure curl is installed
      ansible.builtin.package:
        name: curl
        state: present

    - name: Ensure a symlink exists
      ansible.builtin.file:
        src: /tmp/idempotency-demo/app.conf
        dest: /tmp/idempotency-demo/app.conf.link
        state: link

    - name: Read back the config to confirm final state
      ansible.builtin.command: cat /tmp/idempotency-demo/app.conf
      register: conf_output
      changed_when: false

    - name: Show final config
      ansible.builtin.debug:
        msg: \"{{ conf_output.stdout_lines }}\"
EOF
echo 'lab023-idempotency.yml created.'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: FIRST RUN - expect changes${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab023-idempotency.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && echo '=== FIRST RUN ===' && ansible-playbook lab023-idempotency.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: SECOND RUN - expect changed=0 (fully idempotent)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab023-idempotency.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && echo '=== SECOND RUN (expect changed=0) ===' && ansible-playbook lab023-idempotency.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Dry run with --check --diff - confirm no pending changes${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab023-idempotency.yml --check --diff${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab023-idempotency.yml --check --diff"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: Simulate a drift - manually modify the config file${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m lineinfile -a 'path=... line=DRIFTED_LINE'${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && \
  ansible linux-server-1 -m ansible.builtin.lineinfile \
    -a 'path=/tmp/idempotency-demo/app.conf line=DRIFTED_LINE state=present' && \
  echo '--- Config after manual drift:' && \
  ansible linux-server-1 -m command -a 'cat /tmp/idempotency-demo/app.conf' --one-line"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 6: Re-run playbook to correct the drift${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab023-idempotency.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && echo '=== DRIFT CORRECTION RUN ===' && ansible-playbook lab023-idempotency.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 023 complete! Key takeaway: idempotent playbooks can be run${COLOR_OFF}"
echo -e "${CYAN}multiple times safely - only making changes when needed.${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
