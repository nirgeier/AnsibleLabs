---
# Host and Group Variables

* In this lab we master variable management in Ansible - defining variables at host, group, and global levels.
* Understanding variable precedence is critical for writing maintainable playbooks.
* We will practice organizing variables using `host_vars/` and `group_vars/` directories.

## What will we learn?

- How to define variables in inventory, `host_vars/`, and `group_vars/`
- Ansible's variable precedence order (22 levels!)
- How to use special variables and magic variables
- Best practices for organizing variables

---

## Prerequisites

- Complete the [Lab 002](../002-no-inventory/README.md#usage) in order to have a working `Ansible` controller and inventory configuration.
- Complete [Lab 005](../005-facts/README.md#usage) to understand how Ansible gathers host information.

---

## 01. Where to Define Variables

Ansible has many places to define variables. From lowest to highest priority:

| #   | Location                            | Example                          |
| --- | ----------------------------------- | -------------------------------- |
| 1   | Role defaults (`defaults/main.yml`) | `http_port: 80`                  |
| 2   | Inventory group vars                | `[webservers:vars]` in INI file  |
| 3   | `group_vars/all`                    | `group_vars/all.yml`             |
| 4   | `group_vars/<groupname>`            | `group_vars/webservers.yml`      |
| 5   | Inventory host vars                 | `linux-server-1 http_port=8080`  |
| 6   | `host_vars/<hostname>`              | `host_vars/linux-server-1.yml`   |
| 7   | Play vars (`vars:` in playbook)     | `vars: http_port: 80`            |
| 8   | Play vars_files                     | `vars_files: - vars.yml`         |
| 9   | Role vars (`vars/main.yml`)         | `http_port: 80`                  |
| 10  | Block vars                          | `vars:` inside a `block:`        |
| 11  | Task vars                           | `vars:` inside a task            |
| 12  | `include_vars`                      | `ansible.builtin.include_vars`   |
| 13  | `set_fact`                          | `ansible.builtin.set_fact`       |
| 14  | Register                            | `register: result`               |
| 15  | Extra vars (`-e`)                   | `ansible-playbook -e "env=prod"` |

> **TIP:** Higher number = higher priority. Extra vars (`-e`) always win.

---

## 02. Inline Inventory Variables

```ini
# inventory (INI format)
[webservers]
linux-server-1 http_port=80 document_root=/var/www/html
linux-server-2 http_port=8080 document_root=/srv/www

[dbservers]
linux-server-3 db_port=5432

[all:vars]
ansible_user=root
env=production
```

---

## 03. `group_vars/` Directory

```sh
# Directory structure
group_vars/
├── all.yml          # Applies to every host
├── webservers.yml   # Applies to [webservers] group only
└── dbservers.yml    # Applies to [dbservers] group only
```

```yaml
# group_vars/all.yml
---
ansible_user: root
ansible_python_interpreter: /usr/bin/python3
ntp_server: pool.ntp.org
timezone: UTC


# group_vars/webservers.yml
---
http_port: 80
https_port: 443
document_root: /var/www/html
nginx_worker_processes: auto
max_upload_size: 100M


# group_vars/dbservers.yml
---
db_port: 5432
db_name: appdb
db_user: appuser
backup_enabled: true
backup_retention_days: 30
```

---

## 04. `host_vars/` Directory

```sh
# Directory structure
host_vars/
├── linux-server-1.yml   # Only for linux-server-1
├── linux-server-2.yml   # Only for linux-server-2
└── linux-server-3.yml   # Only for linux-server-3
```

```yaml
# host_vars/linux-server-1.yml
---
server_role: primary-web
http_port: 80
ssl_enabled: true
server_alias: web-primary


# host_vars/linux-server-3.yml
---
server_role: primary-db
db_port: 5432
db_max_connections: 200
```

---

## 05. Magic Variables

Ansible provides built-in variables automatically:

| Variable                       | Value / Description                                   |
| ------------------------------ | ----------------------------------------------------- |
| `inventory_hostname`           | Name of the host as defined in inventory              |
| `ansible_hostname`             | Short hostname from the remote system (`hostname -s`) |
| `ansible_fqdn`                 | Fully qualified domain name from the remote system    |
| `ansible_default_ipv4.address` | Primary IP address of the managed node                |
| `ansible_os_family`            | OS family (Debian, RedHat, etc.)                      |
| `ansible_distribution`         | Linux distribution (Ubuntu, CentOS, etc.)             |
| `ansible_architecture`         | CPU architecture (x86_64, aarch64, etc.)              |
| `groups`                       | Dictionary of all groups and their members            |
| `hostvars`                     | Dictionary of variables for all hosts                 |
| `group_names`                  | List of groups the current host belongs to            |
| `play_hosts`                   | List of active hosts in the current play              |

```yaml
# Using magic variables in a task
- name: Show host information
  ansible.builtin.debug:
    msg: |
      Host: {{ inventory_hostname }}
      IP: {{ ansible_default_ipv4.address }}
      OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
      Groups: {{ group_names | join(', ') }}
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 06. Hands-on

1. Create the `group_vars/` and `host_vars/` directory structure inside the controller, create `group_vars/all.yml` with `ansible_user`, `env`, and `ntp_server` keys, and create `group_vars/webservers.yml` with `http_port` and `document_root`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p group_vars host_vars"
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > group_vars/all.yml << 'EOF'
   ---
   ansible_user: root
   ansible_python_interpreter: /usr/bin/python3
   env: lab
   ntp_server: pool.ntp.org
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > group_vars/webservers.yml << 'EOF'
   ---
   http_port: 80
   document_root: /var/www/html
   EOF"
   ```

2. Create `host_vars/linux-server-1.yml` that overrides `http_port` to `8080` and sets a `server_alias` variable.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > host_vars/linux-server-1.yml << 'EOF'
   ---
   server_alias: primary-web
   http_port: 8080
   EOF"
   ```

3. Write a playbook `debug_vars.yml` that prints `inventory_hostname`, `group_names`, `http_port` (with a default of `N/A`), and `ansible_distribution` for every host, then run it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > debug_vars.yml << 'EOF'
   ---
   - name: Show variables
     hosts: all
     gather_facts: true
     tasks:
       - name: Display host-specific variables
         ansible.builtin.debug:
           msg:
             - \"Host: {{ inventory_hostname }}\"
             - \"Groups: {{ group_names }}\"
             - \"HTTP Port: {{ http_port | default('N/A') }}\"
             - \"OS: {{ ansible_distribution }}\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook debug_vars.yml"
   ```

4. Override the `env` variable at runtime to `production` without editing any file.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook debug_vars.yml -e 'env=production'"
   ```

5. Use an ad-hoc command with the `debug` module (or `setup`) to confirm that `linux-server-1` has a different `http_port` value than the other servers.

   ??? success "Solution"

   ```sh
   # Run the playbook and observe the HTTP Port line differs for linux-server-1
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook debug_vars.yml"

   ### Output (relevant lines)
   # linux-server-1 → HTTP Port: 8080  (from host_vars override)
   # linux-server-2 → HTTP Port: 80    (from group_vars/webservers.yml)
   ```

---

## 07. Summary

- Variables have 15+ levels of precedence; extra vars (`-e`) always win
- Use `group_vars/` for group-wide settings and `host_vars/` for host-specific overrides
- Magic variables (`inventory_hostname`, `ansible_distribution`) are auto-populated by Ansible
- The `hostvars` dictionary lets you access any host's variables from any task
- Inline inventory variables are convenient but `group_vars/` and `host_vars/` files scale better
