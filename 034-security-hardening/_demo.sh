#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 034 - Security Hardening${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# -------------------------------------------------------
# 1. Create the hardening playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 1] Creating lab034-hardening.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab034-hardening.yml << 'EOF'
---
- name: Lab 034 - Security Hardening
  hosts: all
  gather_facts: true
  become: false   # containers run as root already

  vars:
    ssh_config_path: /etc/ssh/sshd_config
    sysctl_settings:
      - { key: net.ipv4.ip_forward,            value: '0' }
      - { key: kernel.randomize_va_space,       value: '2' }
      - { key: net.ipv4.conf.all.log_martians,  value: '1' }

  tasks:
    # ---- SSH Hardening ----
    - name: Harden SSH - disable X11 forwarding
      ansible.builtin.lineinfile:
        path: \"{{ ssh_config_path }}\"
        regexp: '^#?X11Forwarding'
        line: 'X11Forwarding no'
        backup: true

    - name: Harden SSH - set MaxAuthTries to 3
      ansible.builtin.lineinfile:
        path: \"{{ ssh_config_path }}\"
        regexp: '^#?MaxAuthTries'
        line: 'MaxAuthTries 3'
        backup: true

    - name: Harden SSH - set ClientAliveInterval to 300
      ansible.builtin.lineinfile:
        path: \"{{ ssh_config_path }}\"
        regexp: '^#?ClientAliveInterval'
        line: 'ClientAliveInterval 300'
        backup: true

    - name: Harden SSH - set ClientAliveCountMax to 2
      ansible.builtin.lineinfile:
        path: \"{{ ssh_config_path }}\"
        regexp: '^#?ClientAliveCountMax'
        line: 'ClientAliveCountMax 2'
        backup: true

    - name: Harden SSH - disable PermitRootLogin (permit-password only)
      ansible.builtin.lineinfile:
        path: \"{{ ssh_config_path }}\"
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin prohibit-password'
        backup: true

    # ---- Sysctl Hardening ----
    - name: Apply sysctl security settings
      ansible.posix.sysctl:
        name: \"{{ item.key }}\"
        value: \"{{ item.value }}\"
        state: present
        reload: true
        ignoreerrors: true
      loop: \"{{ sysctl_settings }}\"

    # ---- File Permissions ----
    - name: Ensure /etc/crontab has restricted permissions
      ansible.builtin.file:
        path: /etc/crontab
        owner: root
        group: root
        mode: '0600'
      failed_when: false

    - name: Ensure /etc/passwd has correct permissions
      ansible.builtin.file:
        path: /etc/passwd
        owner: root
        group: root
        mode: '0644'

    - name: Ensure /etc/shadow has restricted permissions
      ansible.builtin.file:
        path: /etc/shadow
        owner: root
        group: root
        mode: '0640'
      failed_when: false
EOF
echo '=== lab034-hardening.yml created ==='
cat /labs-scripts/lab034-hardening.yml"

# -------------------------------------------------------
# 2. Dry run with --check --diff
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 2] Dry run with --check --diff (no changes applied yet)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab034-hardening.yml --check --diff${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab034-hardening.yml --check --diff"

# -------------------------------------------------------
# 3. Apply for real
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 3] Applying hardening changes for real${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab034-hardening.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab034-hardening.yml"

# -------------------------------------------------------
# 4. Verify applied settings
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 4] Verifying applied settings with ad-hoc commands${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

echo -e "${GREEN}$ ansible all -m command -a 'sysctl kernel.randomize_va_space'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'sysctl kernel.randomize_va_space'"

echo -e ""
echo -e "${GREEN}$ ansible all -m command -a 'sysctl net.ipv4.conf.all.log_martians'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'sysctl net.ipv4.conf.all.log_martians'"

echo -e ""
echo -e "${GREEN}$ ansible all -m command -a 'grep MaxAuthTries /etc/ssh/sshd_config'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'grep MaxAuthTries /etc/ssh/sshd_config'"

echo -e ""
echo -e "${GREEN}$ ansible all -m command -a 'grep X11Forwarding /etc/ssh/sshd_config'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'grep X11Forwarding /etc/ssh/sshd_config'"

echo -e ""
echo -e "${GREEN}$ ansible all -m command -a 'grep ClientAliveInterval /etc/ssh/sshd_config'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'grep ClientAliveInterval /etc/ssh/sshd_config'"

# -------------------------------------------------------
# 5. Compliance audit playbook
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[STEP 5] Running compliance audit - checks current security settings${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab034-audit.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab034-audit.yml << 'EOF'
---
- name: Lab 034 - Security Compliance Audit
  hosts: all
  gather_facts: true
  become: false

  tasks:
    - name: Check ASLR setting
      ansible.builtin.command: sysctl -n kernel.randomize_va_space
      register: aslr
      changed_when: false

    - name: Check IP forwarding
      ansible.builtin.command: sysctl -n net.ipv4.ip_forward
      register: ip_forward
      changed_when: false

    - name: Check martian logging
      ansible.builtin.command: sysctl -n net.ipv4.conf.all.log_martians
      register: log_martians
      changed_when: false
      failed_when: false

    - name: Check SSH MaxAuthTries
      ansible.builtin.shell: grep -E '^MaxAuthTries' /etc/ssh/sshd_config || echo 'NOT SET'
      register: max_auth
      changed_when: false

    - name: Check SSH X11Forwarding
      ansible.builtin.shell: grep -E '^X11Forwarding' /etc/ssh/sshd_config || echo 'NOT SET'
      register: x11
      changed_when: false

    - name: Check SSH ClientAliveInterval
      ansible.builtin.shell: grep -E '^ClientAliveInterval' /etc/ssh/sshd_config || echo 'NOT SET'
      register: keepalive
      changed_when: false

    - name: Check /etc/passwd permissions
      ansible.builtin.stat:
        path: /etc/passwd
      register: passwd_stat

    - name: Security Compliance Report
      ansible.builtin.debug:
        msg:
          - \"======= SECURITY AUDIT: {{ inventory_hostname }} =======\"
          - \"ASLR (should be 2):            {{ aslr.stdout }}  {{ '[OK]' if aslr.stdout == '2' else '[FAIL]' }}\"
          - \"IP Forward (should be 0):      {{ ip_forward.stdout }}  {{ '[OK]' if ip_forward.stdout == '0' else '[FAIL]' }}\"
          - \"Log Martians (should be 1):    {{ log_martians.stdout | default('N/A') }}\"
          - \"SSH MaxAuthTries:              {{ max_auth.stdout }}\"
          - \"SSH X11Forwarding:             {{ x11.stdout }}\"
          - \"SSH ClientAliveInterval:       {{ keepalive.stdout }}\"
          - \"/etc/passwd mode:              {{ passwd_stat.stat.mode }}  {{ '[OK]' if passwd_stat.stat.mode == '0644' else '[CHECK]' }}\"
EOF
ansible-playbook /labs-scripts/lab034-audit.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 034 complete!${COLOR_OFF}"
echo -e "  ${GREEN}lineinfile${COLOR_OFF}        → idempotent SSH config hardening"
echo -e "  ${GREEN}ansible.posix.sysctl${COLOR_OFF} → kernel parameter management"
echo -e "  ${GREEN}--check --diff${COLOR_OFF}    → preview changes before applying (dry run)"
echo -e "  ${GREEN}audit playbook${COLOR_OFF}    → verify compliance after hardening"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
