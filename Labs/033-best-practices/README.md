---
# Ansible Best Practices

* In this lab we review the directory structure, coding conventions, and design patterns that make Ansible projects maintainable at scale.
* Following best practices from the start prevents technical debt and makes playbooks easier to share and debug.
* Good practices cover structure, naming, security, performance, and testing.

## What will we learn?

- Recommended project directory structure
- Naming conventions for tasks, variables, and files
- Playbook design patterns (separation of concerns, idempotency)
- Security best practices
- Performance optimization tips

---

## Prerequisites

- Complete [Lab 009](../009-roles/README.md#usage) in order to have a working knowledge of Ansible roles and playbooks.

---

## 01. Recommended Project Structure

```text
ansible-project/
├── ansible.cfg                  # Project-level config
├── requirements.yml             # Collections and role dependencies
├── site.yml                     # Master playbook (entry point)
│
├── inventory/
│   ├── production/
│   │   ├── hosts                # Production inventory
│   │   ├── group_vars/
│   │   │   ├── all.yml          # Variables for all hosts
│   │   │   ├── webservers.yml   # Variables for webservers
│   │   │   └── vault.yml        # Encrypted secrets (!)
│   │   └── host_vars/
│   │       └── web1.yml         # Host-specific variables
│   └── staging/
│       ├── hosts
│       └── group_vars/
│
├── playbooks/
│   ├── deploy.yml               # Application deployment
│   ├── provision.yml            # Server provisioning
│   └── maintenance.yml          # Maintenance tasks
│
├── roles/
│   ├── common/                  # Applied to all servers
│   ├── nginx/                   # Nginx role
│   └── postgresql/              # PostgreSQL role
│
├── filter_plugins/              # Custom Jinja2 filters
├── library/                     # Custom modules
└── tests/
    └── integration/             # Integration test playbooks
```

---

## 02. Naming Conventions

### Tasks

```yaml
# GOOD: Descriptive, action-oriented, capitalized
- name: Install nginx web server
- name: Deploy application configuration from template
- name: Ensure PostgreSQL service is running

# BAD: Vague, lowercase, passive voice
- name: nginx
- name: do config
- name: service
```

### Variables

```yaml
# Use descriptive names with underscores
nginx_port: 80
nginx_worker_processes: auto
db_connection_pool_size: 10

# Prefix role variables with role name
nginx_ssl_enabled: true
postgresql_max_connections: 100

# Prefix vault variables with vault_
vault_db_password: "{{ db_password }}"
vault_api_key: "secret_key"

# Use ALL_CAPS for environment-specific constants
APP_VERSION: "2.1.0"
DEPLOY_TIMESTAMP: "{{ ansible_date_time.iso8601 }}"
```

### Files and Roles

```sh
# Roles: short, lowercase, hyphenated
roles/nginx/
roles/node-exporter/
roles/postgresql/

# Playbooks: action-noun
deploy.yml       # Not: deployment.yml or deploying.yml
provision.yml
configure-nginx.yml

# Variable files: group or host name
group_vars/webservers.yml
host_vars/web1.production.yml
```

---

## 03. Playbook Design Patterns

### Separation of Concerns

```yaml
# site.yml - orchestrates everything
---
- import_playbook: playbooks/common.yml # Applied to all servers
- import_playbook: playbooks/webservers.yml
- import_playbook: playbooks/databases.yml

# playbooks/webservers.yml - only web concerns
---
- name: Configure web servers
  hosts: webservers
  become: true
  roles:
    - common
    - nginx
    - certbot
```

### Use Roles Over Monolithic Playbooks

```yaml
# BAD: 500-line monolithic playbook
- name: Big playbook
  hosts: all
  tasks:
    - name: task 1 ...
    # ... 200 more tasks ...

# GOOD: Compose from focused roles
- name: Configure servers
  hosts: all
  roles:
    - common # ~20 tasks
    - nginx # ~15 tasks
    - monitoring # ~10 tasks
```

### Default Variables Pattern

```yaml
# roles/nginx/defaults/main.yml - ALWAYS define defaults
---
nginx_port: 80
nginx_ssl_enabled: false
nginx_worker_processes: auto
nginx_document_root: /var/www/html

# Let users override in inventory or playbook vars
# group_vars/webservers.yml
nginx_port: 443
nginx_ssl_enabled: true
```

---

## 04. Security Best Practices

```yaml
# 1. Never hardcode secrets
# BAD
db_password: "MyPassword123"

# GOOD: Use Vault
db_password: "{{ vault_db_password }}"   # vault.yml is encrypted

# 2. Use become only where needed
- name: Install package (needs root)
  ansible.builtin.apt:
    name: nginx
    state: present
  become: true           # Task-level, not play-level

# 3. Validate file permissions explicitly
- name: Deploy config
  ansible.builtin.copy:
    src: config.ini
    dest: /etc/app/config.ini
    owner: root
    group: app
    mode: "0640"          # Always explicit!

# 4. Use no_log for sensitive tasks
- name: Set database password
  ansible.builtin.command:
    cmd: "psql -c \"ALTER USER app PASSWORD '{{ db_password }}'\""
  no_log: true            # Hide from output and logs

# 5. Validate inputs with assert
- name: Validate environment
  ansible.builtin.assert:
    that:
      - target_env is defined
      - target_env in ['dev', 'staging', 'production']
    fail_msg: "target_env must be one of: dev, staging, production"
```

---

## 05. Performance Best Practices

```ini
# ansible.cfg - performance settings
[defaults]
# Increase parallelism (default is 5)
forks = 20

# Cache facts to skip re-gathering
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible-facts
fact_caching_timeout = 86400

# Gather only what you need
gathering = smart          # Only gather if not cached

[ssh_connection]
# Enable pipelining (fewer SSH round trips)
pipelining = true
control_path = /tmp/ansible-%%h-%%p-%%r
```

```yaml
# Gather only needed facts
- name: Fast play
  hosts: all
  gather_facts: false # Skip if you don't need facts

  tasks:
    - name: Gather only network facts
      ansible.builtin.setup:
        gather_subset:
          - network
          - "!all"
          - "!min"
```

---

## 06. Idempotency Checklist

```yaml
tasks:
  # Use state: parameters
  - ansible.builtin.file: state=directory
  - ansible.builtin.apt: state=present
  - ansible.builtin.service: state=started

  # Use creates/removes for command/shell
  - ansible.builtin.command:
      cmd: tar -xzf /tmp/app.tar.gz -C /opt/
      creates: /opt/app/bin/app

  # changed_when for read-only commands
  - ansible.builtin.command:
      cmd: app --version
    changed_when: false

  # Use lineinfile/blockinfile not shell echo >>
  - ansible.builtin.lineinfile:
      path: /etc/hosts
      line: "10.0.0.1 myhost"

  # AVOID: always changes, not idempotent
  - ansible.builtin.shell:
      cmd: "echo 'config=value' >> /etc/app.conf"
```

---

## 07. Testing Your Playbooks

```sh
# 1. Syntax check (always first)
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --syntax-check"

# 2. Dry run
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check --diff"

# 3. Lint
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint site.yml"

# 4. Run against test environment first
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml -i inventory/staging/"

# 5. Run again to verify idempotency (expect: changed=0)
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml -i inventory/staging/"

# 6. Run against production
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml -i inventory/production/"
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 08. Hands-on

1. Create a playbook that violates multiple best practices (hardcoded secret, no task names, non-idempotent shell usage), then run `ansible-lint` against it:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > bad-playbook.yml << 'EOF'
   ---
   - hosts: all
     vars:
       db_pass: secret123
     tasks:
       - apt:
           name: nginx
           state: present
       - shell: echo \"server_port=8080\" >> /etc/app.conf
       - shell: service nginx restart
       - copy:
           src: /tmp/config
           dest: /etc/nginx/nginx.conf
   EOF
   ansible-lint bad-playbook.yml || true"
   ```

2. Rewrite the bad playbook following best practices - named tasks, FQCN modules, `lineinfile` instead of shell redirect, and a handler for the service restart. Run `ansible-lint` on the result:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > good-playbook.yml << 'EOF'
   ---
   - name: Configure web server (best practices example)
     hosts: all
     become: true
     gather_facts: true

     vars:
       nginx_port: 80
       nginx_conf_content: |
         # Managed by Ansible
         server {
           listen {{ nginx_port }};
         }

     tasks:
       - name: Install nginx web server
         ansible.builtin.apt:
           name: nginx
           state: present
           update_cache: true

       - name: Deploy nginx configuration
         ansible.builtin.copy:
           content: \"{{ nginx_conf_content }}\"
           dest: /etc/nginx/nginx.conf
           owner: root
           group: root
           mode: \"0644\"
         notify: Reload nginx

       - name: Ensure nginx is running
         ansible.builtin.service:
           name: nginx
           state: started
           enabled: true

     handlers:
       - name: Reload nginx
         ansible.builtin.service:
           name: nginx
           state: reloaded
   EOF
   ansible-lint good-playbook.yml && ansible-playbook good-playbook.yml --check"
   ```

3. Create a complete `ansible.cfg` with all recommended performance and security settings, verify it with `ansible --version`, and benchmark the difference with pipelining on vs off:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > ansible-optimized.cfg << 'EOF'
   [defaults]
   inventory          = ./inventory
   remote_user        = root
   host_key_checking  = False
   retry_files_enabled = False

   # Performance
   forks              = 20
   gathering          = smart
   fact_caching       = jsonfile
   fact_caching_connection = /tmp/ansible-facts
   fact_caching_timeout = 86400

   # Output
   stdout_callback    = yaml
   callbacks_enabled  = profile_tasks

   # Security
   vault_password_file = .vault_pass   ; if using vault

   [ssh_connection]
   pipelining         = true
   control_path       = /tmp/ansible-%%h-%%p-%%r
   ssh_args           = -o ControlMaster=auto -o ControlPersist=60s
   EOF"

   # Benchmark without pipelining
   docker exec ansible-controller sh -c "cd /labs-scripts && ANSIBLE_PIPELINING=False time ansible all -m setup --tree /tmp/facts-nopipe/ 2>&1 | tail -3"

   # Benchmark with pipelining
   docker exec ansible-controller sh -c "cd /labs-scripts && ANSIBLE_PIPELINING=True time ansible all -m setup --tree /tmp/facts-pipe/ 2>&1 | tail -3"
   ```

4. Create the recommended directory structure for an Ansible project (inventory, playbooks, roles) using a playbook that builds the skeleton:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab033-structure.yml << 'EOF'
   ---
   - name: Create Recommended Ansible Project Structure
     hosts: localhost
     gather_facts: false

     vars:
       project_root: /labs-scripts/my-project

     tasks:
       - name: Create project directories
         ansible.builtin.file:
           path: \"{{ project_root }}/{{ item }}\"
           state: directory
           mode: \"0755\"
         loop:
           - inventory/production/group_vars
           - inventory/production/host_vars
           - inventory/staging/group_vars
           - playbooks
           - roles
           - filter_plugins
           - library
           - tests/integration

       - name: Create ansible.cfg
         ansible.builtin.copy:
           content: |
             [defaults]
             inventory = ./inventory
             roles_path = ./roles
             host_key_checking = False
             forks = 20
             gathering = smart
             [ssh_connection]
             pipelining = true
           dest: \"{{ project_root }}/ansible.cfg\"

       - name: Create site.yml entry point
         ansible.builtin.copy:
           content: |
             ---
             - import_playbook: playbooks/common.yml
             - import_playbook: playbooks/webservers.yml
           dest: \"{{ project_root }}/site.yml\"

       - name: Create requirements.yml
         ansible.builtin.copy:
           content: |
             ---
             collections:
               - name: community.general
               - name: ansible.posix
             roles: []
           dest: \"{{ project_root }}/requirements.yml\"

       - name: Show resulting structure
         ansible.builtin.command:
           cmd: find {{ project_root }} -type f -o -type d
         register: tree
         changed_when: false

       - name: Display project structure
         ansible.builtin.debug:
           var: tree.stdout_lines
   EOF
   ansible-playbook lab033-structure.yml"
   ```

5. Run `ansible-lint` with the `production` profile on the bad-playbook.yml from the earlier task and fix all reported violations:

   ??? success "Solution"

   ```sh
   # Create a known-bad playbook
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > bad-playbook-v2.yml << 'EOF'
   ---
   - hosts: all
     vars:
       secret_password: hardcoded123
     tasks:
       - apt:
           name: nginx
       - shell: echo server_port=8080 >> /etc/nginx/nginx.conf
       - shell: service nginx restart
   EOF"

   # Lint it and see all violations
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint bad-playbook-v2.yml || true"

   # Create the fixed version
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > fixed-playbook-v2.yml << 'EOF'
   ---
   - name: Configure nginx (best practices)
     hosts: all
     become: true

     vars:
       nginx_port: 8080

     handlers:
       - name: Restart nginx
         ansible.builtin.service:
           name: nginx
           state: restarted

     tasks:
       - name: Install nginx web server
         ansible.builtin.apt:
           name: nginx
           state: present
           update_cache: true

       - name: Set nginx server port
         ansible.builtin.lineinfile:
           path: /etc/nginx/nginx.conf
           regexp: \"^.*server_port\"
           line: \"server_port={{ nginx_port }}\"
           create: true
           mode: \"0644\"
         notify: Restart nginx
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint fixed-playbook-v2.yml && echo 'All lint checks passed!'"
   ```

---

## 09. Summary

- Use a consistent directory structure with `inventory/`, `playbooks/`, `roles/`
- **Descriptive task names** (capitalized, action-verb) make playbooks self-documenting
- Prefix role variables with the role name; prefix vault vars with `vault_`
- **Never hardcode secrets** - use `ansible-vault` combined with `no_log: true`
- Enable `pipelining = true` and `forks = 20` for dramatically faster runs
- Always test in order: syntax-check → lint → dry-run → staging → idempotency check → production
