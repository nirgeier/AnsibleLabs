---
# Security Hardening with Ansible

* In this lab we use Ansible to automate Linux server security hardening - applying CIS Benchmark-inspired controls systematically across a fleet.
* Ansible makes security policies consistent, auditable, and repeatable.
* Automation ensures every server receives identical hardening without manual drift.

## What will we learn?

- SSH hardening configuration
- User and sudo management
- Firewall configuration with `ufw`/`firewalld`
- System auditing with `auditd`
- Applying CIS benchmark controls

---

## Prerequisites

- Complete [Lab 016](../016-file-modules/README.md#usage) and [Lab 017](../017-package-service-modules/README.md#usage) in order to have a working knowledge of file modules and package/service management.

---

## 01. SSH Hardening

```yaml
# roles/ssh-hardening/tasks/main.yml
---
- name: Harden SSH configuration
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    state: present
    validate: /usr/sbin/sshd -t -f %s
    backup: true
  loop:
    # Disable root login
    - regexp: "^#?PermitRootLogin"
      line: "PermitRootLogin no"
    # Disable password authentication
    - regexp: "^#?PasswordAuthentication"
      line: "PasswordAuthentication no"
    # Disable empty passwords
    - regexp: "^#?PermitEmptyPasswords"
      line: "PermitEmptyPasswords no"
    # Disable X11 forwarding
    - regexp: "^#?X11Forwarding"
      line: "X11Forwarding no"
    # Set max auth tries
    - regexp: "^#?MaxAuthTries"
      line: "MaxAuthTries 3"
    # Set login grace time
    - regexp: "^#?LoginGraceTime"
      line: "LoginGraceTime 60"
    # Disable host-based authentication
    - regexp: "^#?HostbasedAuthentication"
      line: "HostbasedAuthentication no"
    # Disable .rhosts files
    - regexp: "^#?IgnoreRhosts"
      line: "IgnoreRhosts yes"
    # Set SSH protocol
    - regexp: "^#?Protocol"
      line: "Protocol 2"
    # Set client alive settings
    - regexp: "^#?ClientAliveInterval"
      line: "ClientAliveInterval 300"
    - regexp: "^#?ClientAliveCountMax"
      line: "ClientAliveCountMax 2"
  notify: Restart sshd

- name: Set allowed SSH ciphers
  ansible.builtin.blockinfile:
    path: /etc/ssh/sshd_config
    block: |
      # Hardened ciphers (CIS Benchmark)
      Ciphers aes128-ctr,aes192-ctr,aes256-ctr
      MACs hmac-sha2-256,hmac-sha2-512
      KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group14-sha256
    marker: "# {mark} ANSIBLE MANAGED: SSH Ciphers"
  notify: Restart sshd
```

---

## 02. User and Sudo Management

```yaml
# roles/user-management/tasks/main.yml
---
- name: Ensure admin users exist
  ansible.builtin.user:
    name: "{{ item.name }}"
    state: present
    groups: sudo
    shell: /bin/bash
    create_home: true
    password_lock: true # Force key-based auth only
  loop: "{{ admin_users }}"

- name: Deploy SSH public keys for admin users
  ansible.builtin.authorized_key:
    user: "{{ item.name }}"
    key: "{{ item.ssh_key }}"
    state: present
    exclusive: false
  loop: "{{ admin_users }}"

- name: Configure sudoers (passwordless for specific commands)
  ansible.builtin.copy:
    content: |
      # Ansible-managed sudoers
      %sudo ALL=(ALL:ALL) NOPASSWD: /usr/bin/apt, /bin/systemctl
      Defaults    requiretty
      Defaults    logfile=/var/log/sudo.log
    dest: /etc/sudoers.d/ansible-managed
    mode: "0440"
    validate: /usr/sbin/visudo -cf %s

- name: Lock inactive user accounts
  ansible.builtin.user:
    name: "{{ item }}"
    password_lock: true
  loop: "{{ locked_users | default([]) }}"

- name: Remove unauthorized users
  ansible.builtin.user:
    name: "{{ item }}"
    state: absent
    remove: true
  loop: "{{ removed_users | default([]) }}"
```

---

## 03. Firewall Configuration

### UFW (Ubuntu/Debian)

```yaml
tasks:
  - name: Install ufw
    ansible.builtin.apt:
      name: ufw
      state: present

  - name: Reset ufw to defaults
    community.general.ufw:
      state: reset

  - name: Set default outgoing to allow
    community.general.ufw:
      direction: outgoing
      policy: allow

  - name: Set default incoming to deny
    community.general.ufw:
      direction: incoming
      policy: deny

  - name: Allow SSH
    community.general.ufw:
      rule: allow
      port: "22"
      proto: tcp
      comment: SSH access

  - name: Allow HTTP and HTTPS
    community.general.ufw:
      rule: allow
      port: "{{ item }}"
      proto: tcp
    loop:
      - "80"
      - "443"

  - name: Allow specific IP to access admin port
    community.general.ufw:
      rule: allow
      src: "{{ admin_ip }}"
      port: "8443"
      proto: tcp
      comment: Admin access from office

  - name: Enable ufw
    community.general.ufw:
      state: enabled
      logging: "on"
```

### firewalld (RHEL/CentOS)

```yaml
tasks:
  - name: Install and start firewalld
    ansible.builtin.package:
      name: firewalld
      state: present

  - name: Start firewalld
    ansible.builtin.service:
      name: firewalld
      state: started
      enabled: true

  - name: Allow SSH
    ansible.posix.firewalld:
      service: ssh
      state: enabled
      permanent: true
      immediate: true

  - name: Allow HTTP/HTTPS
    ansible.posix.firewalld:
      service: "{{ item }}"
      state: enabled
      permanent: true
      immediate: true
    loop:
      - http
      - https

  - name: Block specific port
    ansible.posix.firewalld:
      port: "23/tcp"
      state: disabled
      permanent: true
      immediate: true
```

---

## 04. System Auditing with `auditd`

```yaml
tasks:
  - name: Install auditd
    ansible.builtin.package:
      name: auditd
      state: present

  - name: Deploy audit rules
    ansible.builtin.copy:
      content: |
        # Audit file modifications in /etc
        -w /etc/passwd -p wa -k identity
        -w /etc/group -p wa -k identity
        -w /etc/shadow -p wa -k identity
        -w /etc/sudoers -p wa -k sudo_changes

        # Audit SSH configuration changes
        -w /etc/ssh/sshd_config -p wa -k sshd_config

        # Audit privilege escalation
        -a always,exit -F arch=b64 -S setuid -k setuid
        -a always,exit -F arch=b64 -S setgid -k setgid

        # Audit network changes
        -w /etc/hosts -p wa -k network_changes

        # Audit crontab changes
        -w /etc/cron.d/ -p wa -k cron_changes
        -w /var/spool/cron/ -p wa -k cron_changes
      dest: /etc/audit/rules.d/hardening.rules
      mode: "0640"
    notify: Restart auditd

  - name: Enable auditd
    ansible.builtin.service:
      name: auditd
      state: started
      enabled: true
```

---

## 05. OS-Level Hardening

```yaml
tasks:
  # Disable unused filesystems
  - name: Disable unused filesystems
    ansible.builtin.copy:
      content: |
        install cramfs /bin/true
        install freevxfs /bin/true
        install jffs2 /bin/true
        install hfs /bin/true
        install hfsplus /bin/true
        install squashfs /bin/true
        install udf /bin/true
      dest: /etc/modprobe.d/disable-filesystems.conf
      mode: "0644"

  # Kernel hardening via sysctl
  - name: Apply sysctl security settings
    ansible.posix.sysctl:
      name: "{{ item.name }}"
      value: "{{ item.value }}"
      state: present
      reload: true
    loop:
      # Network security
      - { name: net.ipv4.ip_forward, value: "0" }
      - { name: net.ipv4.conf.all.accept_redirects, value: "0" }
      - { name: net.ipv4.conf.all.accept_source_route, value: "0" }
      - { name: net.ipv4.conf.all.log_martians, value: "1" }
      - { name: net.ipv4.icmp_echo_ignore_broadcasts, value: "1" }
      # Memory protection
      - { name: kernel.randomize_va_space, value: "2" }
      - { name: kernel.dmesg_restrict, value: "1" }
      - { name: fs.suid_dumpable, value: "0" }
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 06. Hands-on

1. Create a hardening playbook that tightens SSH settings and applies kernel sysctl parameters, then do a dry run with `--check --diff`:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab034-hardening.yml << 'EOF'
   ---
   - name: Basic Server Hardening
     hosts: all
     become: true
     gather_facts: true

     tasks:
       - name: SSH - Disable X11 forwarding
         ansible.builtin.lineinfile:
           path: /etc/ssh/sshd_config
           regexp: \"^#?X11Forwarding\"
           line: \"X11Forwarding no\"
           backup: true

       - name: SSH - Set max auth tries
         ansible.builtin.lineinfile:
           path: /etc/ssh/sshd_config
           regexp: \"^#?MaxAuthTries\"
           line: \"MaxAuthTries 3\"

       - name: SSH - Set client alive settings
         ansible.builtin.lineinfile:
           path: /etc/ssh/sshd_config
           regexp: \"^#?ClientAliveInterval\"
           line: \"ClientAliveInterval 300\"

       - name: Kernel - Disable IP forwarding
         ansible.posix.sysctl:
           name: net.ipv4.ip_forward
           value: \"0\"
           state: present
           reload: true

       - name: Kernel - Log suspicious packets
         ansible.posix.sysctl:
           name: net.ipv4.conf.all.log_martians
           value: \"1\"
           state: present
           reload: true

       - name: Kernel - Enable ASLR
         ansible.posix.sysctl:
           name: kernel.randomize_va_space
           value: \"2\"
           state: present
           reload: true

       - name: Verify sshd config is valid
         ansible.builtin.command:
           cmd: sshd -t
         changed_when: false

       - name: Show hardening summary
         ansible.builtin.debug:
           msg:
             - \"SSH hardened: MaxAuthTries=3, X11Forwarding=no\"
             - \"Kernel: ip_forward=0, ASLR=2\"
             - \"Hardening applied to: {{ inventory_hostname }}\"
   EOF
   ansible-playbook lab034-hardening.yml --check --diff"
   ```

2. Apply the hardening playbook for real:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab034-hardening.yml"
   ```

3. Verify the applied sysctl settings and SSH configuration on all hosts:

   ??? success "Solution"

   ```sh
   # Verify sysctl settings
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'sysctl net.ipv4.ip_forward kernel.randomize_va_space' --become"

   # Verify SSH settings
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'grep -E \"MaxAuthTries|X11Forwarding|ClientAlive\" /etc/ssh/sshd_config'"
   ```

4. Set up `auditd` rules on all hosts and verify they are loaded:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab034-auditd.yml << 'EOF'
   ---
   - name: Configure auditd
     hosts: all
     become: true
     gather_facts: true

     tasks:
       - name: Install auditd
         ansible.builtin.apt:
           name: auditd
           state: present
           update_cache: true
         when: ansible_os_family == 'Debian'

       - name: Ensure audit rules directory exists
         ansible.builtin.file:
           path: /etc/audit/rules.d
           state: directory
           mode: \"0750\"

       - name: Deploy hardening audit rules
         ansible.builtin.copy:
           content: |
             # Identity file changes
             -w /etc/passwd -p wa -k identity
             -w /etc/group -p wa -k identity
             -w /etc/shadow -p wa -k identity
             -w /etc/sudoers -p wa -k sudo_changes
             # SSH config changes
             -w /etc/ssh/sshd_config -p wa -k sshd_config
             # Cron changes
             -w /etc/cron.d/ -p wa -k cron_changes
           dest: /etc/audit/rules.d/hardening.rules
           mode: \"0640\"

       - name: Start and enable auditd
         ansible.builtin.service:
           name: auditd
           state: started
           enabled: true
         ignore_errors: true

       - name: Verify audit rules are loaded
         ansible.builtin.command:
           cmd: auditctl -l
         register: audit_rules
         changed_when: false
         become: true
         ignore_errors: true

       - name: Show loaded audit rules
         ansible.builtin.debug:
           var: audit_rules.stdout_lines
   EOF
   ansible-playbook lab034-auditd.yml"
   ```

5. Create a playbook that performs a security audit and generates a compliance report - check for password auth, root login, firewall status, and ASLR:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab034-audit-report.yml << 'EOF'
   ---
   - name: Security Compliance Audit
     hosts: all
     become: true
     gather_facts: true

     tasks:
       - name: Check SSH PasswordAuthentication
         ansible.builtin.command:
           cmd: grep -E '^PasswordAuthentication' /etc/ssh/sshd_config
         register: ssh_pass_auth
         changed_when: false
         failed_when: false

       - name: Check SSH PermitRootLogin
         ansible.builtin.command:
           cmd: grep -E '^PermitRootLogin' /etc/ssh/sshd_config
         register: ssh_root_login
         changed_when: false
         failed_when: false

       - name: Check ASLR status
         ansible.builtin.command:
           cmd: sysctl kernel.randomize_va_space
         register: aslr_status
         changed_when: false

       - name: Check UFW status
         ansible.builtin.command:
           cmd: ufw status
         register: ufw_status
         changed_when: false
         failed_when: false

       - name: Print compliance report
         ansible.builtin.debug:
           msg:
             - \"=== Security Report: {{ inventory_hostname }} ===\"
             - \"SSH PasswordAuth: {{ ssh_pass_auth.stdout | default('not configured') }}\"
             - \"SSH PermitRoot:   {{ ssh_root_login.stdout | default('not configured') }}\"
             - \"ASLR:             {{ aslr_status.stdout }}\"
             - \"Firewall:         {{ ufw_status.stdout_lines[0] | default('not installed') }}\"
   EOF
   ansible-playbook lab034-audit-report.yml"
   ```

---

## 07. Summary

- Use `lineinfile` with `regexp` to precisely edit SSH config without breaking it
- The `sysctl` module applies kernel parameters **idempotently**
- `ufw`/`firewalld` modules manage firewall rules declaratively across distro families
- `auditd` rules track changes to critical files for compliance and forensics
- Always run `--check --diff` before applying hardening to understand the full impact
- Use `validate:` in `copy`/`template` tasks for config files that have a built-in syntax checker
