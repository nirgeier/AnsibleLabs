---
# Package and Service Modules

* In this lab we master package management and service control using Ansible modules.
* These are the workhorses of configuration management - installing software and keeping services running.
* We will cover `apt`, `yum`/`dnf`, `package`, `pip`, `service`, and `systemd`.

## What will we learn?

- `apt`, `yum/dnf`, `package` modules for OS package management
- `pip` and `npm` for language-level packages
- `service` and `systemd` for managing system services

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) to understand how playbooks and tasks are structured.

---

## 01. `apt` Module (Debian/Ubuntu)

```yaml
tasks:
  # Install a single package
  - name: Install nginx
    ansible.builtin.apt:
      name: nginx
      state: present

  # Install multiple packages
  - name: Install web stack
    ansible.builtin.apt:
      name:
        - nginx
        - certbot
        - python3-certbot-nginx
      state: present
      update_cache: true
      cache_valid_time: 3600 # Don't update cache if it's less than 1 hour old

  # Install a specific version
  - name: Install specific nginx version
    ansible.builtin.apt:
      name: nginx=1.24.0-1ubuntu1
      state: present

  # Remove a package
  - name: Remove apache2
    ansible.builtin.apt:
      name: apache2
      state: absent
      purge: true # Also remove config files

  # Upgrade all packages
  - name: Upgrade all packages
    ansible.builtin.apt:
      upgrade: dist
      update_cache: true

  # Install from a .deb URL
  - name: Install package from URL
    ansible.builtin.apt:
      deb: https://example.com/myapp_1.0.0_amd64.deb

  # Add a repository
  - name: Add nginx PPA
    ansible.builtin.apt_repository:
      repo: ppa:nginx/stable
      state: present

  # Add apt key
  - name: Add Docker apt key
    ansible.builtin.apt_key:
      url: https://download.docker.com/linux/ubuntu/gpg
      state: present
```

---

## 02. `yum` / `dnf` Module (RHEL/CentOS/Fedora)

```yaml
tasks:
  # Install packages
  - name: Install nginx (RHEL)
    ansible.builtin.yum:
      name:
        - nginx
        - policycoreutils-python-utils
      state: present

  # Use dnf (Fedora, RHEL 8+)
  - name: Install packages with dnf
    ansible.builtin.dnf:
      name:
        - nginx
        - python3
      state: present

  # Enable a repository
  - name: Enable EPEL
    ansible.builtin.yum:
      name: epel-release
      state: present

  # Remove a package
  - name: Remove httpd
    ansible.builtin.yum:
      name: httpd
      state: absent
```

---

## 03. `package` Module - OS-Agnostic

```yaml
tasks:
  # Works on Debian AND RedHat - Ansible detects the OS
  - name: Install curl (any OS)
    ansible.builtin.package:
      name: curl
      state: present

  # Install multiple packages
  - name: Install common tools
    ansible.builtin.package:
      name:
        - curl
        - git
        - wget
        - htop
      state: present
```

> **TIP:** Use the `package` module for cross-platform playbooks. It automatically selects the correct package manager for the target OS (`apt`, `yum`, `dnf`, `zypper`, etc.).

---

## 04. `pip` Module - Python Packages

```yaml
tasks:
  # Install a Python package
  - name: Install boto3
    ansible.builtin.pip:
      name: boto3
      state: present

  # Install a specific version
  - name: Install specific version
    ansible.builtin.pip:
      name: django==4.2.0
      state: present

  # Install into a virtualenv
  - name: Install into venv
    ansible.builtin.pip:
      name:
        - flask
        - gunicorn
        - psycopg2
      virtualenv: /opt/myapp/venv
      virtualenv_command: python3 -m venv

  # Install from requirements file
  - name: Install from requirements
    ansible.builtin.pip:
      requirements: /opt/myapp/requirements.txt
      virtualenv: /opt/myapp/venv
```

---

## 05. `service` Module

```yaml
tasks:
  # Start and enable a service
  - name: Start and enable nginx
    ansible.builtin.service:
      name: nginx
      state: started
      enabled: true

  # Restart a service
  - name: Restart nginx
    ansible.builtin.service:
      name: nginx
      state: restarted

  # Reload (graceful restart)
  - name: Reload nginx
    ansible.builtin.service:
      name: nginx
      state: reloaded

  # Stop and disable
  - name: Disable and stop apache
    ansible.builtin.service:
      name: apache2
      state: stopped
      enabled: false
```

---

## 06. `systemd` Module - Advanced Service Control

```yaml
tasks:
  # Start, enable, and reload systemd daemon
  - name: Enable and start myapp
    ansible.builtin.systemd:
      name: myapp
      state: started
      enabled: true
      daemon_reload: true # Reload systemd configuration

  # Install and start a custom service unit
  - name: Deploy systemd service unit
    ansible.builtin.copy:
      content: |
        [Unit]
        Description=My Application
        After=network.target

        [Service]
        Type=simple
        ExecStart=/opt/myapp/bin/myapp
        Restart=on-failure
        User=myapp

        [Install]
        WantedBy=multi-user.target
      dest: /etc/systemd/system/myapp.service
      mode: "0644"
    notify:
      - Reload systemd
      - Start myapp

handlers:
  - name: Reload systemd
    ansible.builtin.systemd:
      daemon_reload: true

  - name: Start myapp
    ansible.builtin.systemd:
      name: myapp
      state: started
      enabled: true
```

---

## 07. Package Management Best Practices

```yaml
tasks:
  # Always update cache before installing (with caching to avoid slow runs)
  - name: Update apt cache
    ansible.builtin.apt:
      update_cache: true
      cache_valid_time: 3600
    changed_when: false # Don't report as changed unless packages change

  # Use variables for package lists
  - name: Install required packages
    ansible.builtin.apt:
      name: "{{ required_packages }}"
      state: present

  # Pin critical package versions for reproducibility
  - name: Install pinned nginx version
    ansible.builtin.apt:
      name: "nginx={{ nginx_version }}"
      state: present
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 08. Hands-on

1. Write a playbook `lab017-packages.yml` that updates the apt cache, then installs `nginx`, `curl`, and `wget` on all hosts using the `apt` module with a package list variable.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab017-packages.yml << 'EOF'
   ---
   - name: Full Stack Package Installation
     hosts: all
     become: true
     gather_facts: true

     vars:
       web_packages:
         - nginx
         - curl
         - wget
       dev_tools:
         - git
         - vim
         - htop

     tasks:
       - name: Update package cache
         ansible.builtin.apt:
           update_cache: true
           cache_valid_time: 3600
         when: ansible_os_family == \"Debian\"
         changed_when: false

       - name: Install web packages
         ansible.builtin.apt:
           name: \"{{ web_packages }}\"
           state: present
         when: ansible_os_family == \"Debian\"

       - name: Install developer tools
         ansible.builtin.apt:
           name: \"{{ dev_tools }}\"
           state: present
         when: ansible_os_family == \"Debian\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab017-packages.yml"
   ```

2. Add tasks to ensure `nginx` is started and enabled, then verify its status using `systemd`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat >> lab017-packages.yml << 'EOF'

       - name: Ensure nginx is running
         ansible.builtin.service:
           name: nginx
           state: started
           enabled: true

       - name: Verify nginx status
         ansible.builtin.systemd:
           name: nginx
         register: nginx_status

       - name: Show nginx status
         ansible.builtin.debug:
           msg: \"Nginx is {{ nginx_status.status.ActiveState }}\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab017-packages.yml"
   ```

3. Use an ad-hoc command to check that `nginx` is installed and print its version on all servers.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'nginx -v'"

   ### Output
   linux-server-1 | CHANGED | rc=0 >>
   nginx version: nginx/1.24.0
   linux-server-2 | CHANGED | rc=0 >>
   nginx version: nginx/1.24.0
   linux-server-3 | CHANGED | rc=0 >>
   nginx version: nginx/1.24.0
   ```

4. Use the `pip` module in a playbook task to install the `requests` Python package on all servers.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab017-pip.yml << 'EOF'
   ---
   - name: Install Python packages
     hosts: all
     become: true

     tasks:
       - name: Install Python pip packages
         ansible.builtin.pip:
           name:
             - requests
             - pyyaml
           state: present
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab017-pip.yml"
   ```

5. Use an ad-hoc command to stop `nginx` on all servers, then start it again, and confirm the service is running.

   ??? success "Solution"

   ```sh
   # Stop nginx
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m service -a 'name=nginx state=stopped' --become"

   # Start nginx
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m service -a 'name=nginx state=started' --become"

   # Confirm running
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'nginx -v'"
   ```

---

## 09. Summary

- Use `apt` for Debian/Ubuntu, `yum`/`dnf` for RedHat, or `package` for any OS
- `update_cache: true` with `cache_valid_time` prevents slow cache updates on repeated runs
- Use package list variables so a single task installs all required software
- `service` handles basic service control; `systemd` adds `daemon_reload` and more granular control
- `pip` installs Python packages, with virtual environment support built in
- Always combine package installation with service management for a complete, idempotent setup
- Use `when: ansible_os_family == "Debian"` to guard `apt` tasks in cross-platform playbooks
