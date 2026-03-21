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
# 1. Create the handlers + blocks playbook
# -------------------------------------------------------
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Creating lab015-handlers.yml${COLOR_OFF}"
echo -e "${Green}* Tasks use 'notify' to trigger a handler only when they CHANGE something${COLOR_OFF}"
echo -e "${Green}* Handlers run ONCE at the end of the play, even if notified multiple times${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab015-handlers.yml << 'EOF'
---
- name: Handlers and Blocks Demo
  hosts: all
  gather_facts: false

  tasks:
    # --- Handlers section ---
    - name: Create /tmp/lab015 directory (notifies handler when changed)
      ansible.builtin.file:
        path: /tmp/lab015
        state: directory
        mode: \"0755\"
      notify: Log directory created

    - name: Write a config file (notifies handler when changed)
      ansible.builtin.copy:
        content: |
          # Lab 015 config
          created_by: ansible
          idempotent: true
        dest: /tmp/lab015/app.conf
        mode: \"0644\"
      notify: Log config deployed

    # --- Block / rescue / always section ---
    - name: Block with rescue and always
      block:
        - name: \"[block] Create result directory\"
          ansible.builtin.file:
            path: /tmp/lab015/results
            state: directory

        - name: \"[block] Write result file\"
          ansible.builtin.copy:
            content: \"Block succeeded on {{ inventory_hostname }}!\n\"
            dest: /tmp/lab015/results/outcome.txt

        - name: \"[block] Show block succeeded\"
          ansible.builtin.debug:
            msg: \"Block completed successfully on {{ inventory_hostname }}\"

      rescue:
        - name: \"[rescue] Handle block failure gracefully\"
          ansible.builtin.debug:
            msg: \"Rescue executed! Handling the error on {{ inventory_hostname }}\"

      always:
        - name: \"[always] This runs regardless of success or failure\"
          ansible.builtin.debug:
            msg: \"Always block: cleanup/notification step for {{ inventory_hostname }}\"

  handlers:
    - name: Log directory created
      ansible.builtin.debug:
        msg: \"HANDLER FIRED: /tmp/lab015 directory was created on {{ inventory_hostname }}\"

    - name: Log config deployed
      ansible.builtin.debug:
        msg: \"HANDLER FIRED: app.conf was deployed on {{ inventory_hostname }}\"
EOF"

echo -e "${GREEN}$ cat lab015-handlers.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/lab015-handlers.yml"

# -------------------------------------------------------
# 2. First run - handlers WILL fire (tasks change something)
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] First run - handlers WILL fire (tasks make changes)${COLOR_OFF}"
echo -e "${Red}* Watch for 'HANDLER FIRED' messages at the end of the play${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab015-handlers.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-handlers.yml"

# -------------------------------------------------------
# 3. Second run - handlers will NOT fire (idempotent)
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Second run - handlers will NOT fire (nothing changed = idempotent)${COLOR_OFF}"
echo -e "${Red}* No 'HANDLER FIRED' messages - tasks show 'ok' instead of 'changed'${COLOR_OFF}"
echo -e "${Red}* PLAY RECAP should show changed=0${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab015-handlers.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-handlers.yml"

# -------------------------------------------------------
# 4. Demonstrate rescue - intentional failure
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Demonstrating rescue - intentional failure inside block${COLOR_OFF}"
echo -e "${Red}* When the block fails, rescue executes; always runs regardless${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab015-rescue-demo.yml << 'EOF'
---
- name: Block Rescue Demo - Intentional Failure
  hosts: linux-server-1
  gather_facts: false

  tasks:
    - name: Demonstrate block/rescue/always with a forced failure
      block:
        - name: \"[block] This task will FAIL intentionally\"
          ansible.builtin.command:
            cmd: \"false\"

        - name: \"[block] This task will be SKIPPED (never reached)\"
          ansible.builtin.debug:
            msg: \"You will never see this message\"

      rescue:
        - name: \"[rescue] Failure caught! Running recovery steps\"
          ansible.builtin.debug:
            msg: \"Rescue block triggered - handling error gracefully\"

        - name: \"[rescue] Write failure log\"
          ansible.builtin.copy:
            content: \"Deployment failed at {{ ansible_date_time.iso8601 | default('unknown') }}\n\"
            dest: /tmp/lab015/failure.log

      always:
        - name: \"[always] Cleanup - runs whether block succeeded or failed\"
          ansible.builtin.debug:
            msg: \"Always block: sending notification, cleaning temp files, etc.\"
EOF"
echo -e "${GREEN}$ ansible-playbook lab015-rescue-demo.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-rescue-demo.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Summary:${COLOR_OFF}"
echo -e "  ${Green}notify:   ${COLOR_OFF} → trigger a handler (only when task changes something)"
echo -e "  ${Green}handlers: ${COLOR_OFF} → run once at end of play, even if notified many times"
echo -e "  ${Green}block:    ${COLOR_OFF} → group tasks; shared when/become/tags apply to all"
echo -e "  ${Green}rescue:   ${COLOR_OFF} → runs only if the block FAILS (like catch)"
echo -e "  ${Green}always:   ${COLOR_OFF} → runs regardless of success or failure (like finally)"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
