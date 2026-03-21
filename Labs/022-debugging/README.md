---
# Debugging and Troubleshooting

* In this lab we learn Ansible's debugging tools and techniques for diagnosing playbook failures, unexpected behavior, and connectivity issues.
* Good debugging skills cut troubleshooting time dramatically.

## What will we learn?

- The `debug` module for printing variables and messages
- Verbosity levels (`-v`, `-vvv`, `-vvvv`)
- Check mode (`--check`) and diff mode (`--diff`)
- The `debugger` keyword for interactive debugging
- Common errors and their solutions

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) in order to have a working understanding of Ansible playbooks.

---

## 01. The `debug` Module

```yaml
tasks:
  # Print a message
  - name: Print a simple message
    ansible.builtin.debug:
      msg: "Hello from {{ inventory_hostname }}"

  # Print a variable
  - name: Print a variable
    ansible.builtin.debug:
      var: ansible_distribution

  # Print multiple variables
  - name: Print multiple values
    ansible.builtin.debug:
      msg:
        - "Host: {{ inventory_hostname }}"
        - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
        - "IP: {{ ansible_default_ipv4.address }}"
        - "Memory: {{ ansible_memtotal_mb }} MB"

  # Conditional debug (only when variable is set)
  - name: Debug when variable exists
    ansible.builtin.debug:
      msg: "The value is: {{ my_var }}"
    when: my_var is defined

  # Print entire dictionary
  - name: Show all facts
    ansible.builtin.debug:
      var: ansible_facts

  # Print registered result
  - name: Run a command
    ansible.builtin.command:
      cmd: df -h
    register: disk_output

  - name: Show command output
    ansible.builtin.debug:
      var: disk_output.stdout_lines
```

---

## 02. Verbosity Levels

```sh
# -v: Show task results (what changed)
ansible-playbook site.yml -v

# -vv: Show input/output of tasks
ansible-playbook site.yml -vv

# -vvv: Show SSH connection details, task data
ansible-playbook site.yml -vvv

# -vvvv: Show Ansible internals, SSH debug output
ansible-playbook site.yml -vvvv
```

### Verbosity in Tasks

```yaml
tasks:
  # Only show this debug message with -v or higher
  - name: Verbose debug
    ansible.builtin.debug:
      msg: "This only shows with -v"
      verbosity: 1

  # Only show with -vvv
  - name: Very verbose debug
    ansible.builtin.debug:
      var: all_the_facts
      verbosity: 3
```

---

## 03. Check Mode and Diff Mode

```sh
# Dry run - show what WOULD happen without making changes
ansible-playbook site.yml --check

# Show file diffs
ansible-playbook site.yml --diff

# Both together (most useful)
ansible-playbook site.yml --check --diff
```

```yaml
tasks:
  # This task always runs, even in check mode
  - name: Always run even in check mode
    ansible.builtin.command:
      cmd: echo "check mode status"
    check_mode: false

  # Mark a task as safe to run in check mode
  - name: This task supports check mode
    ansible.builtin.template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    # template module natively supports check mode
```

---

## 04. The `debugger` Keyword

```yaml
# Enable debugger globally
- name: Debugging play
  hosts: all
  debugger: on_failed # Options: always, never, on_failed, on_unreachable, on_skipped

  tasks:
    - name: This task will enter debugger on failure
      ansible.builtin.command:
        cmd: /nonexistent/command
```

When the debugger activates, you get an interactive prompt:

```sh
[192.168.1.10] TASK: Run command *****
(debug) p result          # Print the task result
(debug) p task.args       # Print task arguments
(debug) p vars            # Print all variables
(debug) task.args['cmd'] = '/correct/command'  # Fix the task
(debug) r                  # Retry the task
(debug) c                  # Continue to next task
(debug) q                  # Quit
```

---

## 05. Log File

```ini
# ansible.cfg
[defaults]
log_path = /var/log/ansible.log
```

```sh
# Tail the log during a run
tail -f /var/log/ansible.log

# Search the log for errors
grep -i "fatal\|error\|failed" /var/log/ansible.log
```

---

## 06. Common Errors and Solutions

| Error                                                          | Likely Cause                  | Solution                                          |
| -------------------------------------------------------------- | ----------------------------- | ------------------------------------------------- |
| `UNREACHABLE! Connection refused`                              | SSH not running or wrong port | Check SSH service and port                        |
| `Permission denied (publickey)`                                | Wrong SSH key or user         | Check `IdentityFile` and `remote_user`            |
| `MODULE FAILURE: No module named 'X'`                          | Python module missing on host | Install with pip or package manager               |
| `fatal: [host]: FAILED! => {"msg": "A variable is undefined"}` | Variable not set              | Add `default()` filter or `when: var is defined`  |
| `Timeout waiting for privilege escalation`                     | sudo requires a password      | Add `become_ask_pass: true` or configure NOPASSWD |
| `Changed=N but should be 0`                                    | Non-idempotent task           | Rewrite task to be idempotent                     |
| `Syntax error on line X`                                       | YAML formatting issue         | Check indentation and colons                      |

---

## 07. Testing Connectivity

```sh
# Basic ping test
ansible all -m ping

# In our demo lab we will execute it, as follows:
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"

### Output
# linux-server-1 | SUCCESS => { ... "ping": "pong" }
# linux-server-2 | SUCCESS => { ... "ping": "pong" }
# linux-server-3 | SUCCESS => { ... "ping": "pong" }

# With verbose output to see SSH details
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping -vvv"

# Test with a specific user
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping -u root"

# Test connection parameters
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_hostname'"
```

---

## 08. Ansible Lint

```sh
# Install ansible-lint
pip install ansible-lint

# Lint a playbook
ansible-lint site.yml

# Lint all playbooks
ansible-lint

# List specific rules
ansible-lint --list-rules

# Skip specific rules
ansible-lint site.yml --skip-list yaml[line-length]
```

---

## 09. Hands-on

1. Create a debug playbook `lab022-debug.yml` that prints host information, checks nginx status, and uses a rescue block to handle a failing task.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab022-debug.yml << 'EOF'
   ---
   - name: Debugging Practice
     hosts: all
     gather_facts: true

     tasks:
       - name: Print host information
         ansible.builtin.debug:
           msg:
             - \"Hostname: {{ inventory_hostname }}\"
             - \"OS: {{ ansible_distribution }} {{ ansible_distribution_version }}\"
             - \"Architecture: {{ ansible_architecture }}\"
             - \"IPv4: {{ ansible_default_ipv4.address }}\"
             - \"Memory (MB): {{ ansible_memtotal_mb }}\"

       - name: Check if a service is running
         ansible.builtin.command:
           cmd: systemctl status nginx
         register: nginx_status
         ignore_errors: true
         changed_when: false

       - name: Show service status
         ansible.builtin.debug:
           msg: \"Nginx status: {{ 'running' if nginx_status.rc == 0 else 'not running' }}\"

       - name: Print registered output on failure
         ansible.builtin.debug:
           var: nginx_status
           verbosity: 1

       - name: Conditional task with debug
         block:
           - name: Try something
             ansible.builtin.command:
               cmd: \"false\"
         rescue:
           - name: Show what happened
             ansible.builtin.debug:
               msg: \"The task failed! This is the rescue block.\"
   EOF"
   ```

2. Run the playbook at normal verbosity, then with `-v`, then with `-vvv`.

   ??? success "Solution"

   ```sh
   # Normal run
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml"

   # Verbose run
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml -v"

   # Very verbose (see SSH details)
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml -vvv"
   ```

3. Run the playbook in check mode to see what would happen without applying changes.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml --check"
   ```

4. Enable logging to `/tmp/ansible.log` and inspect the log after a run.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && echo 'log_path = /tmp/ansible.log' >> ansible.cfg"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab022-debug.yml"

   docker exec ansible-controller sh -c "cat /tmp/ansible.log"
   ```

---

## 10. Summary

- `debug` with `var:` prints variables; `msg:` prints formatted strings
- Use `verbosity: N` to show debug messages only at a specific verbosity level
- `--check` shows what would change; `--diff` shows file content changes
- The `debugger: on_failed` keyword gives an **interactive shell** on task failure
- Enable `log_path` in `ansible.cfg` for persistent logging
- `ansible-lint` catches style and correctness issues before you run a playbook
- Always test connectivity with `ansible all -m ping` before running playbooks
