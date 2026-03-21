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
echo -e "${CYAN}Lab 029 - Advanced Execution Strategies${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# Step 1: Rolling update with serial: 1
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Rolling update with serial: 1 (one host at a time)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab029-rolling.yml << 'EOF'
---
- name: Rolling Update - serial 1
  hosts: all
  serial: 1
  max_fail_percentage: 0

  tasks:
    - name: Simulate taking host out of rotation
      ansible.builtin.debug:
        msg: \"[{{ inventory_hostname }}] Taking out of load balancer rotation\"
      delegate_to: localhost

    - name: Simulate update task
      ansible.builtin.command:
        cmd: echo \"Updating {{ inventory_hostname }}\"
      register: update_out
      changed_when: true

    - name: Show update result
      ansible.builtin.debug:
        msg: \"{{ update_out.stdout }}\"

    - name: Simulate returning host to rotation
      ansible.builtin.debug:
        msg: \"[{{ inventory_hostname }}] Back online\"
      delegate_to: localhost

- name: Post-update summary
  hosts: all
  gather_facts: false
  tasks:
    - name: Report completion (run once)
      ansible.builtin.debug:
        msg: \"All {{ ansible_play_hosts | length }} hosts updated successfully!\"
      run_once: true
EOF"

echo -e "${GREEN}$ ansible-playbook lab029-rolling.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-rolling.yml"

# Step 2: run_once example
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: run_once - execute a task only once across all hosts${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab029-run-once.yml << 'EOF'
---
- name: run_once Demo
  hosts: all
  gather_facts: false

  tasks:
    - name: This task runs on every host
      ansible.builtin.debug:
        msg: \"Running on: {{ inventory_hostname }}\"

    - name: This task runs only ONCE (on first host)
      ansible.builtin.debug:
        msg: \"run_once: executed on {{ inventory_hostname }} for all {{ ansible_play_hosts | length }} hosts\"
      run_once: true

    - name: Write a marker file on all hosts
      ansible.builtin.copy:
        content: \"marked by ansible on {{ inventory_hostname }}\n\"
        dest: /tmp/run-once-demo.txt
        mode: \"0644\"

    - name: Report all marker files created (run_once)
      ansible.builtin.debug:
        msg: \"Marker files created on all hosts. Reporting from: {{ inventory_hostname }}\"
      run_once: true
EOF"

echo -e "${GREEN}$ ansible-playbook lab029-run-once.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-run-once.yml"

# Step 3: delegate_to: localhost
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: delegate_to - run a task on a different host (localhost)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab029-delegate.yml << 'EOF'
---
- name: delegate_to Demo
  hosts: all
  gather_facts: false

  tasks:
    - name: Create a file on each remote host
      ansible.builtin.copy:
        content: \"Created on {{ inventory_hostname }}\n\"
        dest: /tmp/delegate-demo.txt
        mode: \"0644\"

    - name: Log deployment on the controller (delegate_to localhost)
      ansible.builtin.shell:
        cmd: echo \"{{ inventory_hostname }} deployed at $(date)\" >> /tmp/deployment-log.txt
      delegate_to: localhost
      changed_when: true

    - name: Show deployment log once (delegate + run_once)
      ansible.builtin.command:
        cmd: cat /tmp/deployment-log.txt
      delegate_to: localhost
      register: deploy_log
      run_once: true
      changed_when: false

    - name: Print deployment log
      ansible.builtin.debug:
        msg: \"{{ deploy_log.stdout_lines }}\"
      run_once: true
EOF"

echo -e "${GREEN}$ ansible-playbook lab029-delegate.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-delegate.yml"

# Step 4: max_fail_percentage: 0
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: max_fail_percentage: 0 - abort if any host fails${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab029-max-fail.yml << 'EOF'
---
- name: max_fail_percentage Demo
  hosts: all
  serial: 1
  max_fail_percentage: 0

  tasks:
    - name: Simulate a healthy task
      ansible.builtin.debug:
        msg: \"Host {{ inventory_hostname }} is healthy - proceeding with update\"

    - name: Write status file
      ansible.builtin.copy:
        content: \"ok\n\"
        dest: /tmp/health-check.txt
        mode: \"0644\"

    - name: Verify status (idempotent read)
      ansible.builtin.command:
        cmd: cat /tmp/health-check.txt
      register: status
      changed_when: false

    - name: Assert healthy status
      ansible.builtin.assert:
        that:
          - status.stdout == \"ok\"
        fail_msg: \"Host {{ inventory_hostname }} failed health check!\"
        success_msg: \"Host {{ inventory_hostname }} passed health check\"
EOF"

echo -e "${GREEN}$ ansible-playbook lab029-max-fail.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-max-fail.yml"

# Summary
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Summary of Advanced Execution strategies demonstrated:${COLOR_OFF}"
echo -e "${GREEN}  serial: 1               - Rolling updates, one host at a time${COLOR_OFF}"
echo -e "${GREEN}  run_once: true          - Execute task only once across all hosts${COLOR_OFF}"
echo -e "${GREEN}  delegate_to: localhost  - Run task on control node instead of target${COLOR_OFF}"
echo -e "${GREEN}  max_fail_percentage: 0  - Abort immediately if any host fails${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 029 - Complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
