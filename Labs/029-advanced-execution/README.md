---
# Advanced Execution

* In this lab we explore advanced Ansible execution strategies: rolling updates, task delegation, parallel execution control, and `run_once`.
* These techniques are essential for managing large fleets and zero-downtime deployments.

## What will we learn?

- `serial` for rolling updates (batched execution)
- `delegate_to` to run tasks on a different host
- `run_once` for tasks that should run only on one host
- `throttle` and `forks` for parallel execution control
- `max_fail_percentage` for safe deployments

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) in order to have working Ansible playbooks.

---

## 01. Rolling Updates with `serial`

```yaml
---
- name: Rolling update
  hosts: webservers # 10 servers
  serial: 2 # Update 2 at a time
  become: true

  tasks:
    - name: Take host out of load balancer
      ansible.builtin.uri:
        url: "http://lb.example.com/remove/{{ inventory_hostname }}"
        method: POST
      delegate_to: localhost

    - name: Update application
      ansible.builtin.apt:
        name: myapp
        state: latest

    - name: Restart application
      ansible.builtin.service:
        name: myapp
        state: restarted

    - name: Wait for application to be ready
      ansible.builtin.uri:
        url: "http://{{ inventory_hostname }}/health"
        status_code: 200
      retries: 10
      delay: 5

    - name: Re-add host to load balancer
      ansible.builtin.uri:
        url: "http://lb.example.com/add/{{ inventory_hostname }}"
        method: POST
      delegate_to: localhost
```

### `serial` Options

```yaml
# Process 2 hosts at a time
serial: 2

# Process 30% of hosts at a time
serial: "30%"

# Escalating batch sizes: 1, then 5, then rest
serial:
  - 1
  - 5
  - "100%"

# Max failures before stopping
max_fail_percentage: 10
```

---

## 02. `delegate_to` - Run on a Different Host

```yaml
tasks:
  # Run this task on localhost (the control node), not the target
  - name: Send deployment notification
    ansible.builtin.uri:
      url: https://hooks.example.com/deploy
      method: POST
      body_format: json
      body:
        host: "{{ inventory_hostname }}"
        status: deploying
    delegate_to: localhost

  # Run this task on a specific server in inventory
  - name: Trigger backup on the NAS
    ansible.builtin.command:
      cmd: /opt/backup/backup.sh {{ inventory_hostname }}
    delegate_to: backup-server

  # Copy a file FROM one server TO another
  - name: Sync config from primary to secondary
    ansible.posix.synchronize:
      src: /etc/nginx/nginx.conf
      dest: /etc/nginx/nginx.conf
      mode: push
    delegate_to: primary-web
```

> **TIP:** Use `delegate_facts: true` to store gathered facts under the delegated host's name instead of the original host.

---

## 03. `run_once` - Execute Only Once in the Play

```yaml
tasks:
  # Run this task only ONCE, on the first host in the group
  - name: Create database schema
    ansible.builtin.command:
      cmd: /opt/app/manage.py migrate
    run_once: true

  # Combine with delegate_to
  - name: Send deployment notification to Slack
    community.general.slack:
      token: "{{ slack_token }}"
      msg: "Deploying {{ app_version }} to {{ ansible_play_hosts | length }} servers"
    run_once: true
    delegate_to: localhost
```

---

## 04. `throttle` - Limit Parallel Task Execution

```yaml
tasks:
  # Run this task on max 3 hosts simultaneously (even with high forks)
  - name: Restart memcached (rate limited)
    ansible.builtin.service:
      name: memcached
      state: restarted
    throttle: 3

  # Useful for services that can't all restart simultaneously
  - name: Rolling service restart
    ansible.builtin.service:
      name: elasticsearch
      state: restarted
    throttle: 1 # One at a time to maintain cluster quorum
```

---

## 05. `forks` - Global Parallelism

```ini
# ansible.cfg
[defaults]
forks = 20    # Run tasks on up to 20 hosts simultaneously (default: 5)
```

```sh
# Override at runtime
ansible-playbook site.yml --forks 30

# For sequential execution (1 host at a time)
ansible-playbook site.yml --forks 1
```

---

## 06. Wait for Conditions

```yaml
tasks:
  # Wait until a port is open
  - name: Wait for service port to be ready
    ansible.builtin.wait_for:
      host: "{{ inventory_hostname }}"
      port: 8080
      delay: 5
      timeout: 120

  # Wait for a file to exist
  - name: Wait for lock file to disappear
    ansible.builtin.wait_for:
      path: /var/run/deploy.lock
      state: absent
      timeout: 60

  # Wait for HTTP endpoint
  - name: Wait for health check
    ansible.builtin.uri:
      url: "http://{{ inventory_hostname }}:8080/health"
      status_code: 200
    register: health_check
    until: health_check.status == 200
    retries: 12
    delay: 10

  # Pause for a specified time
  - name: Pause to let service stabilize
    ansible.builtin.pause:
      seconds: 30

  # Pause with a message (prompts user to continue)
  - name: Manual approval gate
    ansible.builtin.pause:
      prompt: "Check the deployment. Press Enter to continue or Ctrl+C to abort"
```

---

## 07. Retries on Failure

```yaml
tasks:
  # Retry a task until it succeeds
  - name: Download package (with retries)
    ansible.builtin.get_url:
      url: https://example.com/package.tar.gz
      dest: /tmp/package.tar.gz
    register: download
    until: download is succeeded
    retries: 5
    delay: 10

  # Retry with custom success condition
  - name: Wait for cluster to reach quorum
    ansible.builtin.command:
      cmd: /opt/db/check-quorum.sh
    register: quorum_check
    until: quorum_check.rc == 0
    retries: 10
    delay: 30
    changed_when: false
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 08. Hands-on

1. Create a rolling update playbook `lab029-rolling.yml` that processes one host at a time and stops if more than 50% of hosts fail.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cat > /labs-scripts/lab029-rolling.yml << 'EOF'
   ---
   - name: Rolling Update Simulation
     hosts: all
     serial: 1                    # One host at a time
     max_fail_percentage: 50      # Stop if more than 50% fail

     tasks:
       - name: Simulate taking host offline
         ansible.builtin.debug:
           msg: \"Taking {{ inventory_hostname }} out of rotation\"
         delegate_to: localhost

       - name: Simulate update
         ansible.builtin.command:
           cmd: \"sleep 1 && echo 'Updated!'\"
         register: update_out
         changed_when: true

       - name: Verify update
         ansible.builtin.debug:
           msg: \"{{ update_out.stdout }}\"

       - name: Simulate bringing host back online
         ansible.builtin.debug:
           msg: \"{{ inventory_hostname }} back online\"
         delegate_to: localhost

   - name: Post-update notification
     hosts: all
     gather_facts: false
     tasks:
       - name: Notify completion (once)
         ansible.builtin.debug:
           msg: \"All {{ ansible_play_hosts | length }} hosts updated successfully!\"
         run_once: true
   EOF"
   ```

2. Run the rolling update playbook and observe that hosts are processed one at a time.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-rolling.yml"

   ### Output
   # PLAY [Rolling Update Simulation] ****
   # Each host is processed individually before moving to the next
   ```

3. Create a delegation example playbook `lab029-delegate.yml` that creates a file on remote hosts and then checks it once from the control node.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cat > /labs-scripts/lab029-delegate.yml << 'EOF'
   ---
   - name: Delegation Example
     hosts: all
     gather_facts: false

     tasks:
       - name: Create a remote file
         ansible.builtin.copy:
           content: \"Created on {{ inventory_hostname }}\n\"
           dest: /tmp/remote-file.txt

       - name: Check file from control node
         ansible.builtin.command:
           cmd: \"echo 'Checking from: {{ inventory_hostname }}'\"
         delegate_to: localhost
         run_once: true
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-delegate.yml"
   ```

4. Run a playbook with `--forks 1` to force strictly sequential execution and compare the runtime to the default forks setting.

   ??? success "Solution"

   ```sh
   # Sequential (forks=1)
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-rolling.yml --forks 1"

   # Default forks
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab029-rolling.yml"
   ```

---

## 09. Summary

- `serial: N` enables **rolling updates** - N hosts are updated at a time
- `max_fail_percentage` stops the deployment if too many hosts fail
- `delegate_to: localhost` runs a task on the **control node** (load balancer calls, notifications)
- `run_once: true` runs a task only once per play (DB migrations, Slack notifications)
- `throttle: N` limits concurrent task execution regardless of `forks`
- `until` + `retries` + `delay` creates resilient **polling loops**
