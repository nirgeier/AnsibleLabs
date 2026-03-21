---
# Idempotency and Check Mode

* In this lab we explore idempotency - the principle that running a playbook multiple times should produce the same result as running it once.
* We learn to write idempotent tasks and use check mode to verify playbooks before applying changes.

## What will we learn?

- What idempotency means and why it matters
- How to write idempotent tasks using correct module parameters
- `changed_when` and `failed_when` for custom behavior
- Using `--check` and `--diff` effectively

---

## Prerequisites

- Complete [Lab 022](../022-debugging/README.md#usage) in order to have a working understanding of Ansible debugging tools.

---

## 01. What is Idempotency?

An operation is **idempotent** if applying it multiple times has the same effect as applying it once.

In Ansible: running a playbook twice should leave the system in the same state, and the second run should show `changed=0`.

**Why it matters:**

- Safe to re-run playbooks without fear of breaking things
- Enables playbooks to be run as part of CI/CD pipelines
- Makes it easy to detect configuration drift
- Enables `--check` mode to validate state

---

## 02. Idempotent vs Non-Idempotent Tasks

### Non-Idempotent (Bad)

```yaml
tasks:
  # BAD: Adds a line every time, even if it already exists
  - name: Add line to file (BAD)
    ansible.builtin.shell:
      cmd: "echo 'server_port=8080' >> /etc/app/config"

  # BAD: Creates a user even if they exist (will fail on second run)
  - name: Create user (BAD)
    ansible.builtin.command:
      cmd: "useradd myuser"
```

### Idempotent (Good)

```yaml
tasks:
  # GOOD: lineinfile checks if the line already exists
  - name: Set server port (GOOD)
    ansible.builtin.lineinfile:
      path: /etc/app/config
      line: "server_port=8080"
      state: present

  # GOOD: user module handles existing users correctly
  - name: Create user (GOOD)
    ansible.builtin.user:
      name: myuser
      state: present
```

---

## 03. Common Idempotency Patterns

### Pattern 1 - Use Module Instead of Command

```yaml
tasks:
  # NON-IDEMPOTENT
  - name: Create directory with command
    ansible.builtin.command:
      cmd: mkdir -p /opt/app

  # IDEMPOTENT
  - name: Create directory with file module
    ansible.builtin.file:
      path: /opt/app
      state: directory
```

### Pattern 2 - `creates` and `removes` Parameters

```yaml
tasks:
  # Only run if the file does NOT exist
  - name: Extract archive (only once)
    ansible.builtin.command:
      cmd: tar -xzf /tmp/app.tar.gz -C /opt/app
      creates: /opt/app/bin/myapp # Skip if this file exists

  # Only run if the file DOES exist
  - name: Remove temp file
    ansible.builtin.command:
      cmd: rm -f /tmp/app.tar.gz
      removes: /tmp/app.tar.gz # Skip if file doesn't exist
```

### Pattern 3 - `changed_when: false` for Read-Only Commands

```yaml
tasks:
  # Gathering info never changes anything
  - name: Check application version
    ansible.builtin.command:
      cmd: /opt/app/bin/myapp --version
    register: app_version
    changed_when: false # This is read-only, never "changed"

  - name: Get current git commit
    ansible.builtin.command:
      cmd: git -C /opt/app rev-parse HEAD
    register: git_commit
    changed_when: false
```

### Pattern 4 - Custom `changed_when`

```yaml
tasks:
  # Run a script; mark as changed only if output contains "updated"
  - name: Run update script
    ansible.builtin.command:
      cmd: /opt/scripts/update.sh
    register: update_result
    changed_when: "'updated' in update_result.stdout"

  # Service was restarted only if it was previously stopped
  - name: Ensure service state
    ansible.builtin.command:
      cmd: systemctl is-active myservice
    register: service_state
    changed_when: service_state.rc != 0
    failed_when: false
```

### Pattern 5 - Use `state:` Parameters

```yaml
tasks:
  # Always specify state explicitly
  - name: Package management
    ansible.builtin.apt:
      name: nginx
      state: present # present, absent, latest

  - name: File management
    ansible.builtin.file:
      path: /opt/app
      state: directory # directory, file, link, absent, touch

  - name: Service management
    ansible.builtin.service:
      name: nginx
      state: started # started, stopped, restarted, reloaded
```

---

## 04. Using `--check` Mode Effectively

```sh
# Run in check mode - no changes applied
ansible-playbook site.yml --check

# In our demo lab we will execute it, as follows:
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check"

# Check + show diffs
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check --diff"

# Check only specific hosts
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check --limit linux-server-1"

# Check a specific tag
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check --tags configure"
```

> **NOTE:** Some tasks don't support check mode (e.g., `command`, `shell` without explicit support). Use `changed_when: false` and `check_mode: false` for tasks that need to run in both modes.

---

## 05. Testing Idempotency

```sh
# Run 1: First run - expect changes
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml"

# Run 2: Second run - expect no changes
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml"

### Output (second run)
# PLAY RECAP ****
# linux-server-1 : ok=10 changed=0 unreachable=0 failed=0
#                              ^^^^^^^^^^^^^^^^^^
#                              This should be 0 on second run!
```

---

## 06. Hands-on

1. Create a playbook `lab023-idempotency.yml` with idempotent tasks: create a directory, deploy a config file, initialize a data file without overwriting, add a hosts entry, and check directory contents with `changed_when: false`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab023-idempotency.yml << 'EOF'
   ---
   - name: Idempotency Practice
     hosts: all
     become: true
     gather_facts: false

     tasks:
       # IDEMPOTENT: file module with state
       - name: Create directory (idempotent)
         ansible.builtin.file:
           path: /opt/lab023
           state: directory
           mode: \"0755\"

       # IDEMPOTENT: copy module checks content hash
       - name: Deploy config file (idempotent)
         ansible.builtin.copy:
           content: |
             # Lab 023 Config
             app_name=lab023
             version=1.0
           dest: /opt/lab023/config.ini
           mode: \"0644\"

       # IDEMPOTENT: only runs if file doesn't exist
       - name: Initialize data file (runs only once)
         ansible.builtin.copy:
           content: \"initialized\n\"
           dest: /opt/lab023/data.txt
           force: false      # Don't overwrite if it already exists

       # IDEMPOTENT: lineinfile checks before adding
       - name: Add entry to hosts
         ansible.builtin.lineinfile:
           path: /etc/hosts
           line: \"127.0.0.1 lab023.local\"
           state: present

       # READ-ONLY: changed_when: false
       - name: Check directory contents (read-only)
         ansible.builtin.command:
           cmd: ls -la /opt/lab023
         register: dir_contents
         changed_when: false

       - name: Show contents
         ansible.builtin.debug:
           var: dir_contents.stdout_lines
   EOF"
   ```

2. Run the playbook twice and compare the `changed=` count between the first and second run.

   ??? success "Solution"

   ```sh
   # First run - should show some changes
   docker exec ansible-controller sh -c "cd /labs-scripts && echo '=== FIRST RUN ===' && ansible-playbook lab023-idempotency.yml"

   # Second run - should show changed=0
   docker exec ansible-controller sh -c "cd /labs-scripts && echo '=== SECOND RUN ===' && ansible-playbook lab023-idempotency.yml"

   ### Output (second run PLAY RECAP)
   # linux-server-1 : ok=6  changed=0  unreachable=0  failed=0
   # linux-server-2 : ok=6  changed=0  unreachable=0  failed=0
   # linux-server-3 : ok=6  changed=0  unreachable=0  failed=0
   ```

3. Use check mode with diff to verify no changes would be made on a third run.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab023-idempotency.yml --check --diff"
   ```

4. Write a NON-idempotent playbook using `shell` with `>>`, run it three times, and observe how the file grows each time. Then rewrite it using `lineinfile` to make it idempotent:

   ??? success "Solution"

   ```sh
   # First, see the non-idempotent behavior
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab023-nonidempotent.yml << 'EOF'
   ---
   - name: Non-Idempotent Example (BAD)
     hosts: linux-server-1
     become: true

     tasks:
       - name: Append line (bad practice)
         ansible.builtin.shell:
           cmd: \"echo 'app_version=1.0' >> /tmp/lab023-bad.conf\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab023-nonidempotent.yml && ansible-playbook lab023-nonidempotent.yml && ansible-playbook lab023-nonidempotent.yml"
   docker exec ansible-controller sh -c "ansible linux-server-1 -m command -a 'cat /tmp/lab023-bad.conf' --become"

   # Now the idempotent version
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab023-idempotent-fix.yml << 'EOF'
   ---
   - name: Idempotent Fix (GOOD)
     hosts: linux-server-1
     become: true

     tasks:
       - name: Set app version (idempotent)
         ansible.builtin.lineinfile:
           path: /tmp/lab023-good.conf
           line: \"app_version=1.0\"
           create: true
           state: present
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab023-idempotent-fix.yml && ansible-playbook lab023-idempotent-fix.yml && ansible-playbook lab023-idempotent-fix.yml"
   docker exec ansible-controller sh -c "ansible linux-server-1 -m command -a 'cat /tmp/lab023-good.conf' --become"
   ```

5. Use `failed_when` to make a task fail only when a specific condition is true - demonstrate that a service check passes even if the service is not found:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab023-failedwhen.yml << 'EOF'
   ---
   - name: Custom Failed/Changed When
     hosts: all
     become: true

     tasks:
       - name: Check if a service exists
         ansible.builtin.command:
           cmd: systemctl is-active nginx
         register: nginx_status
         changed_when: false
         failed_when: false     # Never fail regardless of exit code

       - name: Report nginx status
         ansible.builtin.debug:
           msg: \"nginx is {{ 'RUNNING' if nginx_status.rc == 0 else 'NOT running (rc={{ nginx_status.rc }})' }}\"

       - name: Assert expected state
         ansible.builtin.assert:
           that:
             - nginx_status.rc is defined
           success_msg: \"Service check completed (idempotent read-only task)\"
           fail_msg: \"Something unexpected happened\"
   EOF
   ansible-playbook lab023-failedwhen.yml"
   ```

---

## 07. Summary

- **Idempotent playbooks**: second run produces `changed=0`
- Prefer **modules** over `command`/`shell` - modules are built to be idempotent
- `creates:` / `removes:` make command tasks conditional and idempotent
- `changed_when: false` for read-only tasks; custom `changed_when` for scripts
- Always test idempotency by **running your playbook twice**
- `--check --diff` is the fastest way to verify a playbook won't cause unexpected changes
