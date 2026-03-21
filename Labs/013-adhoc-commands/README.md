---
# Ad-Hoc Commands

* In this lab we run Ansible ad-hoc commands to perform quick, one-off tasks on managed hosts without writing a playbook.
* Ad-hoc commands are perfect for gathering information, making quick changes, or testing connectivity.
* They use the same modules as playbooks, just invoked directly from the command line.

## What will we learn?

- The syntax and structure of ad-hoc commands
- The most commonly used modules for ad-hoc tasks
- How to use `--become` for privilege escalation
- Practical use cases: fact gathering, file operations, service management

---

## Prerequisites

- Complete the [Lab 002](../002-no-inventory/README.md#usage) in order to have a working `Ansible` controller and inventory configuration.

---

## 01. Ad-Hoc Command Syntax

```sh
ansible <host-pattern> -m <module> -a "<arguments>" [options]

# Components:
# <host-pattern>  : all, webservers, linux-server-1, etc.
# -m <module>     : the module to run (default: command)
# -a "<arguments>": module arguments as key=value pairs
# [options]       : --become, --user, --limit, -v, etc.
```

---

## 02. Essential Modules for Ad-Hoc Use

### `ping` - Test Connectivity

```sh
# Ping all hosts
ansible all -m ping

# Ping a specific group
ansible webservers -m ping

# Ping with verbose output (shows SSH details)
ansible all -m ping -vvv

# In our demo lab:
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"

### Output
linux-server-1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### `command` - Run a Command (No Shell Features)

```sh
# Run a command on all servers
ansible all -m command -a "uptime"

# Get the hostname
ansible all -m command -a "hostname"

# Check disk space
ansible all -m command -a "df -h"

# In our demo lab:
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'uptime'"
```

> **NOTE:** The `command` module does NOT use a shell - no pipes (`|`), redirects (`>`), or environment variables (`$VAR`). Use the `shell` module for those.

### `shell` - Run Shell Commands

```sh
# Use shell features like pipes
ansible all -m shell -a "ps aux | grep nginx"

# Environment variable expansion
ansible all -m shell -a "echo $HOME"

# Multi-command with semicolons
ansible all -m shell -a "cd /tmp && ls -la"

# In our demo lab:
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m shell -a 'hostname'"

### Output
linux-server-3 | CHANGED | rc=0 >>
linux-server-3
linux-server-2 | CHANGED | rc=0 >>
linux-server-2
linux-server-1 | CHANGED | rc=0 >>
linux-server-1
```

### `raw` - Run Commands Without Python

```sh
# Useful when Python is not installed on the target
ansible all -m raw -a "cat /etc/os-release"

# Bootstrap Python on a new node
ansible all -m raw -a "apt-get install -y python3"
```

---

## 03. File Operations

```sh
# Copy a file to all servers
ansible all -m copy -a "src=/tmp/test.txt dest=/tmp/test.txt"

# Create a file with content
ansible all -m copy -a "content='Hello from Ansible' dest=/tmp/hello.txt"

# Change file permissions
ansible all -m file -a "path=/tmp/hello.txt mode=0644 owner=root"

# Create a directory
ansible all -m file -a "path=/opt/myapp state=directory mode=0755"

# Delete a file
ansible all -m file -a "path=/tmp/hello.txt state=absent"

# Fetch a file from a remote host
ansible linux-server-1 -m fetch -a "src=/etc/hostname dest=/tmp/hostnames/"
```

---

## 04. Package Management

```sh
# Install a package (Debian/Ubuntu)
ansible all -m apt -a "name=curl state=present" --become

# Install multiple packages
ansible all -m apt -a "name=curl,wget,vim state=present update_cache=yes" --become

# Remove a package
ansible all -m apt -a "name=vim state=absent" --become

# Update all packages
ansible all -m apt -a "upgrade=dist" --become

# Use the generic package module (works on any OS)
ansible all -m package -a "name=curl state=present" --become
```

---

## 05. Service Management

```sh
# Start a service
ansible all -m service -a "name=nginx state=started" --become

# Stop a service
ansible all -m service -a "name=nginx state=stopped" --become

# Restart a service
ansible all -m service -a "name=nginx state=restarted" --become

# Enable service to start on boot
ansible all -m service -a "name=nginx enabled=yes" --become

# Use systemd module for more control
ansible all -m systemd -a "name=nginx state=started enabled=yes" --become
```

---

## 06. Gathering Facts

```sh
# Gather all facts about hosts
ansible all -m setup

# Filter facts by name pattern
ansible all -m setup -a "filter=ansible_distribution*"
ansible all -m setup -a "filter=ansible_memory_mb"
ansible all -m setup -a "filter=ansible_default_ipv4"

# Get all network interfaces
ansible all -m setup -a "filter=ansible_interfaces"

# Save facts to files
ansible all -m setup --tree /tmp/facts/

# In our demo lab:
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_distribution*'"
```

---

## 07. User Management

```sh
# Create a user
ansible all -m user -a "name=john state=present" --become

# Add user to a group
ansible all -m user -a "name=john groups=sudo append=yes" --become

# Delete a user
ansible all -m user -a "name=john state=absent remove=yes" --become
```

---

## 08. Useful Options

| Option                | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `-b` / `--become`     | Enable privilege escalation (sudo)                   |
| `--become-user`       | Become a specific user (default: root)               |
| `-K`                  | Prompt for sudo password                             |
| `-u <user>`           | Connect as this SSH user                             |
| `--limit <pattern>`   | Limit to a subset of hosts                           |
| `-f <N>`              | Number of parallel forks (default: 5)                |
| `-v` / `-vv` / `-vvv` | Increase verbosity                                   |
| `--check`             | Dry run - show what would change without changing it |
| `--diff`              | Show diff of changes                                 |

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 09. Hands-on

1. Test connectivity to all hosts using the `ping` module.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"
   ```

2. Get the uptime of all servers using the `command` module.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'uptime'"
   ```

3. Create a file `/tmp/ansible-test.txt` on all servers with the content `Created by Ansible ad-hoc`, then verify it exists, then remove it.

   ??? success "Solution"

   ```sh
   # Create the file
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m copy -a \"content='Created by Ansible ad-hoc' dest=/tmp/ansible-test.txt\""

   # Verify
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'cat /tmp/ansible-test.txt'"

   # Remove
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m file -a 'path=/tmp/ansible-test.txt state=absent'"
   ```

4. Gather OS distribution facts from all hosts.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_distribution*'"
   ```

5. Get memory information from all hosts.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_memtotal_mb'"
   ```

6. Install `curl` on all servers, then verify the installation.

   ??? success "Solution"

   ```sh
   # Install
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m apt -a 'name=curl state=present' --become"

   # Verify
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'curl --version'"
   ```

7. Use a shell command with a pipe to list all running processes that contain the word `python`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m shell -a 'ps aux | grep python'"
   ```

8. Create a directory `/tmp/ad-hoc-demo` on all servers, then remove it.

   ??? success "Solution"

   ```sh
   # Create
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m file -a 'path=/tmp/ad-hoc-demo state=directory mode=0755'"

   # Remove
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m file -a 'path=/tmp/ad-hoc-demo state=absent'"
   ```

---

## 10. Summary

- Ad-hoc commands use the syntax: `ansible <hosts> -m <module> -a "<args>"`
- The `command` module is safe but limited - no pipes or shell expansion
- Use `shell` when you need pipes (`|`), redirects (`>`), or environment variables
- `setup` gathers system facts; use `filter=` to narrow results
- `--become` elevates privileges (sudo) for tasks that require it
- Ad-hoc commands are ideal for quick one-off tasks; use playbooks for anything repeatable
- Common modules: `ping`, `command`, `shell`, `copy`, `file`, `apt`, `service`, `setup`
