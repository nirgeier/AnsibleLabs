---
# Handlers and Blocks

* In this lab we learn about **handlers** (tasks triggered only when something changes) and **blocks** (grouping tasks with error handling).
* These features enable clean, event-driven automation with proper error recovery.
* Handlers prevent redundant service restarts; blocks provide try/catch/finally semantics.

## What will we learn?

- How handlers work and when they run
- Notifying handlers from tasks
- `block` / `rescue` / `always` for error handling
- `flush_handlers` to run handlers mid-play

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) to understand how playbooks and tasks are structured.

---

## 01. What are Handlers?

- Handlers are tasks that only run when **notified** by another task.
- A handler runs **once** at the end of a play, even if notified multiple times.
- Perfect for service restarts after config changes.

```yaml
---
- name: Handler example
  hosts: webservers
  become: true

  tasks:
    - name: Deploy nginx configuration
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Restart nginx # Only runs if this task changes something

    - name: Deploy virtual host config
      ansible.builtin.copy:
        src: vhost.conf
        dest: /etc/nginx/sites-available/myapp.conf
      notify:
        - Reload nginx # Can notify multiple handlers
        - Clear cache

  handlers:
    - name: Restart nginx
      ansible.builtin.service:
        name: nginx
        state: restarted

    - name: Reload nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded

    - name: Clear cache
      ansible.builtin.file:
        path: /var/cache/nginx
        state: absent
```

---

## 02. Handler Execution Rules

| Rule                                                  | Detail                             |
| ----------------------------------------------------- | ---------------------------------- |
| Handlers run **after all tasks** in a play            | At the end of the play, not inline |
| A handler runs **only once** even if notified 5 times | Deduplication is automatic         |
| If a task **fails**, handlers **don't run**           | Unless `--force-handlers` is used  |
| Handlers respect **tags** like regular tasks          | `--tags` applies to handlers too   |
| Handlers can notify **other handlers**                | Handler chaining is supported      |

---

## 03. `flush_handlers` - Run Handlers Mid-Play

```yaml
tasks:
  - name: Configure nginx
    ansible.builtin.template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: Restart nginx

  # Force handlers to run NOW (before remaining tasks)
  - name: Flush handlers immediately
    ansible.builtin.meta: flush_handlers

  - name: Verify nginx is running
    ansible.builtin.uri:
      url: http://localhost
      return_content: true

handlers:
  - name: Restart nginx
    ansible.builtin.service:
      name: nginx
      state: restarted
```

---

## 04. `block` - Group Tasks

```yaml
tasks:
  - name: Block of related tasks
    block:
      - name: Install nginx
        ansible.builtin.apt:
          name: nginx
          state: present

      - name: Start nginx
        ansible.builtin.service:
          name: nginx
          state: started

      - name: Test nginx
        ansible.builtin.uri:
          url: http://localhost

    # Apply become to all tasks in the block
    become: true

    # Apply a condition to all tasks in the block
    when: ansible_os_family == "Debian"

    # Apply tags to all tasks in the block
    tags:
      - nginx
      - web
```

---

## 05. `block` / `rescue` / `always` - Error Handling

```yaml
tasks:
  - name: Deploy application with error handling
    block:
      - name: Download application archive
        ansible.builtin.get_url:
          url: https://example.com/app-v2.tar.gz
          dest: /tmp/app.tar.gz

      - name: Extract archive
        ansible.builtin.unarchive:
          src: /tmp/app.tar.gz
          dest: /opt/app
          remote_src: true

      - name: Restart application
        ansible.builtin.service:
          name: myapp
          state: restarted

    rescue:
      # These tasks run ONLY if the block fails
      - name: Log the failure
        ansible.builtin.debug:
          msg: "Deployment failed! Rolling back..."

      - name: Restore previous version
        ansible.builtin.copy:
          src: /opt/app-backup/
          dest: /opt/app/
          remote_src: true

    always:
      # These tasks ALWAYS run (success or failure)
      - name: Clean up temp files
        ansible.builtin.file:
          path: /tmp/app.tar.gz
          state: absent

      - name: Send notification
        ansible.builtin.debug:
          msg: "Deployment process completed (check status above)"
```

---

## 06. `ignore_errors` and `failed_when`

```yaml
tasks:
  # Continue even if this task fails
  - name: Try to stop a service that might not exist
    ansible.builtin.service:
      name: myapp
      state: stopped
    ignore_errors: true

  # Custom failure condition
  - name: Check free disk space
    ansible.builtin.command:
      cmd: df -BG / --output=avail
    register: disk_space
    failed_when: disk_space.stdout_lines[1] | int < 5

  # Custom changed condition
  - name: Check config checksum
    ansible.builtin.command:
      cmd: md5sum /etc/nginx/nginx.conf
    register: config_hash
    changed_when: false # This command never changes anything
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 07. Hands-on

1. Write a playbook `lab015-handlers.yml` that installs `nginx`, creates a custom `/var/www/html/index.html`, and uses handlers to start and reload nginx when each task changes something. Run it with `docker exec`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab015-handlers.yml << 'EOF'
   ---
   - name: Nginx Setup with Handlers
     hosts: all
     become: true

     tasks:
       - name: Install nginx
         ansible.builtin.apt:
           name: nginx
           state: present
           update_cache: true
         notify: Start nginx

       - name: Create custom index page
         ansible.builtin.copy:
           content: \"<h1>Hello from {{ inventory_hostname }}!</h1>\n\"
           dest: /var/www/html/index.html
           mode: \"0644\"
         notify: Reload nginx

     handlers:
       - name: Start nginx
         ansible.builtin.service:
           name: nginx
           state: started
           enabled: true

       - name: Reload nginx
         ansible.builtin.service:
           name: nginx
           state: reloaded
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-handlers.yml"
   ```

2. Run the same playbook a second time and observe that handlers do **not** fire again (because nothing changed).

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-handlers.yml"

   ### Output
   # All tasks show "ok" (not "changed") so no handlers are triggered
   # PLAY RECAP shows changed=0
   ```

3. Write a playbook `lab015-blocks.yml` with a `block` that creates `/tmp/lab015/result.txt`, a `rescue` that prints a recovery message, and an `always` section that prints a cleanup message. Run it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab015-blocks.yml << 'EOF'
   ---
   - name: Block and Error Handling
     hosts: all
     gather_facts: false

     tasks:
       - name: Try a risky operation
         block:
           - name: Create a temp directory
             ansible.builtin.file:
               path: /tmp/lab015
               state: directory

           - name: Write to the temp directory
             ansible.builtin.copy:
               content: \"Block succeeded!\n\"
               dest: /tmp/lab015/result.txt

         rescue:
           - name: Handle the failure
             ansible.builtin.debug:
               msg: \"Rescue block executed! Handling the error gracefully.\"

         always:
           - name: Always clean up
             ansible.builtin.debug:
               msg: \"Always block: cleaning up regardless of outcome\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-blocks.yml"
   ```

4. Modify `lab015-blocks.yml` to intentionally fail inside the block (add a task running `command: cmd: "false"`) and confirm the `rescue` section executes.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab015-blocks-fail.yml << 'EOF'
   ---
   - name: Block with intentional failure
     hosts: all
     gather_facts: false

     tasks:
       - name: Demonstrate rescue
         block:
           - name: This will fail
             ansible.builtin.command:
               cmd: \"false\"

         rescue:
           - name: Rescue triggered
             ansible.builtin.debug:
               msg: \"Rescue block executed as expected!\"

         always:
           - name: Always runs
             ansible.builtin.debug:
               msg: \"Always block runs regardless.\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-blocks-fail.yml"
   ```

5. Add `ignore_errors: true` to a task and confirm the playbook continues past the failure.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab015-ignore.yml << 'EOF'
   ---
   - name: Ignore errors demo
     hosts: all
     gather_facts: false

     tasks:
       - name: This fails but is ignored
         ansible.builtin.command:
           cmd: \"false\"
         ignore_errors: true

       - name: This still runs
         ansible.builtin.debug:
           msg: \"Playbook continued past the failure!\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab015-ignore.yml"
   ```

---

## 08. Summary

- Handlers only run when **notified** by a changed task - and only once per play regardless of how many times notified
- `meta: flush_handlers` forces pending handlers to run at a specific point in the play
- `block` groups tasks so that shared attributes (`become`, `when`, `tags`) apply to all of them
- `rescue` runs when the block fails - Ansible's equivalent of a `catch` clause
- `always` runs whether the block succeeded or failed - Ansible's equivalent of `finally`
- `ignore_errors: true` lets a task fail without stopping the rest of the playbook
- `failed_when` and `changed_when` let you customize what counts as failure or change
