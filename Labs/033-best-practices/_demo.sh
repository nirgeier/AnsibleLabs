#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 033 - Ansible Best Practices & ansible-lint${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# -------------------------------------------------------
# 1. Install ansible-lint
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Installing ansible-lint${COLOR_OFF}"
echo -e "${GREEN}$ pip3 install ansible-lint${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "pip3 install ansible-lint 2>&1 | tail -5"

# -------------------------------------------------------
# 2. Create a BAD playbook with multiple violations
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Creating a BAD playbook that violates best practices${COLOR_OFF}"
echo -e "${Red}Violations: no task names, hardcoded secret, non-FQCN modules, shell instead of module${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/bad-playbook.yml << 'EOF'
---
- hosts: all
  tasks:
    - shell: echo hello
    - shell: mkdir -p /tmp/myapp
    - copy:
        dest: /tmp/myapp/config.txt
        content: \"db_password=SuperSecret123\"
    - shell: chmod 777 /tmp/myapp
    - shell: systemctl status ssh || true
    - package:
        name: curl
        state: present
    - shell: |
        cd /tmp && ls -la
EOF
echo '=== bad-playbook.yml created ==='
cat /labs-scripts/bad-playbook.yml"

# -------------------------------------------------------
# 3. Run ansible-lint on the BAD playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Running ansible-lint on the BAD playbook (violations expected)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-lint bad-playbook.yml || true${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint bad-playbook.yml || true"

# -------------------------------------------------------
# 4. Create a GOOD playbook following all best practices
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Creating a GOOD playbook following all best practices${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/good-playbook.yml << 'EOF'
---
- name: Lab 033 - Good Practices Playbook
  hosts: all
  gather_facts: true
  become: false

  vars:
    app_dir: /tmp/myapp-good
    # Secrets should come from vault or environment - never hardcoded
    db_password: \"{{ lookup('env', 'DB_PASSWORD') | default('changeme_use_vault') }}\"

  tasks:
    - name: Create application directory with correct permissions
      ansible.builtin.file:
        path: \"{{ app_dir }}\"
        state: directory
        mode: '0755'

    - name: Deploy application configuration (no hardcoded secrets)
      ansible.builtin.template:
        src: /dev/stdin
        dest: \"{{ app_dir }}/config.txt\"
        mode: '0600'
      vars:
        template_content: |
          # Application configuration
          # db_password is sourced from vault/environment at runtime
          app_name=myapp
          environment={{ ansible_hostname }}
      # inline template workaround for demo
      ansible.builtin.copy:
        dest: \"{{ app_dir }}/config.txt\"
        content: |
          # Application configuration (secrets via vault, not hardcoded)
          app_name=myapp
          environment={{ ansible_hostname }}
        mode: '0600'

    - name: Ensure curl is installed (FQCN, declarative, idempotent)
      ansible.builtin.package:
        name: curl
        state: present

    - name: Check SSH service status (command module, not shell)
      ansible.builtin.command: systemctl status ssh
      register: ssh_status
      changed_when: false
      failed_when: false

    - name: Show SSH status result
      ansible.builtin.debug:
        msg: \"SSH service status: {{ 'running' if ssh_status.rc == 0 else 'not running' }}\"

    - name: List app directory contents (command, not shell)
      ansible.builtin.command: ls -la {{ app_dir }}
      register: dir_listing
      changed_when: false

    - name: Display directory listing
      ansible.builtin.debug:
        var: dir_listing.stdout_lines
EOF
echo '=== good-playbook.yml created ==='
cat /labs-scripts/good-playbook.yml"

# -------------------------------------------------------
# 5. Run ansible-lint on the GOOD playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 5] Running ansible-lint on the GOOD playbook (should pass or minimal warnings)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-lint good-playbook.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint good-playbook.yml || true"

# -------------------------------------------------------
# 6. Create the recommended project directory structure
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 6] Creating recommended Ansible project directory structure${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "
mkdir -p /labs-scripts/project-structure/{roles/webserver/{tasks,handlers,templates,files,vars,defaults,meta},group_vars,host_vars,playbooks,inventory/group_vars}

cat > /labs-scripts/project-structure/README.txt << 'EOF'
Recommended Ansible Project Layout
====================================
project/
  ansible.cfg              # Project-level config
  requirements.yml         # Galaxy collections and roles
  site.yml                 # Master playbook (imports others)
  playbooks/
    deploy.yml             # Specific-purpose playbooks
    hardening.yml
  inventory/
    production             # Production inventory file
    staging                # Staging inventory file
    group_vars/
      all.yml              # Vars for all hosts
      webservers.yml       # Vars for webserver group
  host_vars/
    web-01.yml             # Host-specific vars
  roles/
    webserver/
      tasks/main.yml       # Role tasks
      handlers/main.yml    # Role handlers
      templates/           # Jinja2 templates
      files/               # Static files
      vars/main.yml        # Role vars (high precedence)
      defaults/main.yml    # Role defaults (low precedence)
      meta/main.yml        # Role metadata + dependencies
  filter_plugins/          # Custom filter plugins
  library/                 # Custom modules
EOF

find /labs-scripts/project-structure -type f -o -type d | sort | sed 's|/labs-scripts/project-structure||' | head -40
echo ''
echo '=== Key files created ==='
cat /labs-scripts/project-structure/README.txt"

# -------------------------------------------------------
# 7. Pipelining benchmark hint
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 7] Performance tip: SSH Pipelining${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "  ${GREEN}Without pipelining${COLOR_OFF}: each task = 3 SSH connections (copy, execute, cleanup)"
echo -e "  ${GREEN}With pipelining${COLOR_OFF}:    each task = 1 SSH connection (pipe script via stdin)"
echo -e ""
echo -e "  Enable in ansible.cfg:"
echo -e "  ${CYAN}[connection]${COLOR_OFF}"
echo -e "  ${CYAN}pipelining = True${COLOR_OFF}"
echo -e ""
docker exec ansible-controller sh -c "
echo '[defaults]' > /tmp/bench-nopipe.cfg
echo 'inventory = /labs-scripts/inventory' >> /tmp/bench-nopipe.cfg
echo 'remote_user = root' >> /tmp/bench-nopipe.cfg
echo 'host_key_checking = False' >> /tmp/bench-nopipe.cfg

echo '[defaults]' > /tmp/bench-pipe.cfg
echo 'inventory = /labs-scripts/inventory' >> /tmp/bench-pipe.cfg
echo 'remote_user = root' >> /tmp/bench-pipe.cfg
echo 'host_key_checking = False' >> /tmp/bench-pipe.cfg
echo '[connection]' >> /tmp/bench-pipe.cfg
echo 'pipelining = True' >> /tmp/bench-pipe.cfg

echo '=== Timing WITHOUT pipelining ==='
time ANSIBLE_CONFIG=/tmp/bench-nopipe.cfg ansible all -m ansible.builtin.ping 2>&1
echo ''
echo '=== Timing WITH pipelining ==='
time ANSIBLE_CONFIG=/tmp/bench-pipe.cfg ansible all -m ansible.builtin.ping 2>&1"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 033 complete!${COLOR_OFF}"
echo -e "  ${GREEN}ansible-lint${COLOR_OFF}      → catches style, safety and idempotency issues"
echo -e "  ${GREEN}FQCN modules${COLOR_OFF}      → ansible.builtin.copy vs copy (unambiguous)"
echo -e "  ${GREEN}No hardcoded secrets${COLOR_OFF} → use ansible-vault or environment lookups"
echo -e "  ${GREEN}Name every task${COLOR_OFF}   → required by lint, essential for readability"
echo -e "  ${GREEN}pipelining=True${COLOR_OFF}   → reduces SSH round-trips per task"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
