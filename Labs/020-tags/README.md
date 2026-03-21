---
# Tags

* In this lab we learn how to use **tags** to control which tasks run in a playbook.
* Tags are essential for large playbooks - they let you run only the "install" tasks, or only the "config" tasks, without running the entire playbook.

## What will we learn?

- Adding tags to tasks, plays, roles, and blocks
- Running playbooks with `--tags` and `--skip-tags`
- Special tags: `always` and `never`
- Tag strategies and naming conventions

---

## Prerequisites

- Complete [Lab 009](../009-roles/README.md#usage) in order to have a working understanding of Ansible roles.

---

## 01. Adding Tags to Tasks

```yaml
tasks:
  - name: Install nginx
    ansible.builtin.apt:
      name: nginx
      state: present
    tags:
      - install
      - nginx
      - packages

  - name: Deploy nginx configuration
    ansible.builtin.template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    tags:
      - configure
      - nginx

  - name: Start nginx service
    ansible.builtin.service:
      name: nginx
      state: started
    tags:
      - services
      - nginx
```

---

## 02. Running with Tags

```sh
# Run ONLY tasks tagged with 'install'
ansible-playbook site.yml --tags install

# Run tasks tagged with 'nginx' OR 'configure'
ansible-playbook site.yml --tags nginx,configure

# Skip tasks tagged with 'install'
ansible-playbook site.yml --skip-tags install

# List all tags in a playbook (don't run)
ansible-playbook site.yml --list-tags

# List all tasks that would run with specific tags
ansible-playbook site.yml --tags configure --list-tasks
```

---

## 03. Tags on Plays, Blocks, and Roles

```yaml
---
- name: Web server setup
  hosts: webservers
  tags:
    - web # All tasks in this play get the 'web' tag

  tasks:
    - name: Tagged block
      block:
        - name: Task in block
          ansible.builtin.debug:
            msg: "I'm in a tagged block"
      tags:
        - myblock # All tasks in this block get 'myblock'

- name: Apply role with tags
  hosts: all
  roles:
    - role: nginx
      tags:
        - nginx # All tasks in the nginx role get 'nginx'
```

---

## 04. Special Tags

### `always` - Always Runs

```yaml
tasks:
  - name: This task always runs, even with --tags
    ansible.builtin.debug:
      msg: "I always run"
    tags:
      - always

  - name: Normal task
    ansible.builtin.debug:
      msg: "I only run when appropriate"
    tags:
      - install
```

### `never` - Only Runs When Explicitly Selected

```yaml
tasks:
  - name: Debug task (only when requested)
    ansible.builtin.debug:
      msg: "Debug information"
      var: hostvars
    tags:
      - never
      - debug # Run with: --tags debug

  - name: Reset to factory defaults (dangerous!)
    ansible.builtin.command:
      cmd: /opt/reset.sh
    tags:
      - never
      - factory_reset # Run with: --tags factory_reset
```

---

## 05. Tag Strategies

### By Phase (Install → Configure → Deploy → Verify)

```yaml
tasks:
  - name: Install packages
    tags: [install, setup]

  - name: Configure service
    tags: [configure, config]

  - name: Deploy application
    tags: [deploy, release]

  - name: Verify service
    tags: [verify, check, test]
```

```sh
# Run only installation tasks
ansible-playbook site.yml --tags install

# Run only configuration
ansible-playbook site.yml --tags configure

# Deploy and then verify
ansible-playbook site.yml --tags deploy,verify
```

### By Component

```yaml
tasks:
  - name: Install nginx # tags: web, nginx
  - name: Configure nginx # tags: web, nginx, configure
  - name: Install postgresql # tags: db, postgresql
  - name: Configure postgresql # tags: db, postgresql, configure
  - name: Deploy application # tags: app, deploy
```

```sh
# Only database tasks
ansible-playbook site.yml --tags db

# Only configuration tasks (all components)
ansible-playbook site.yml --tags configure
```

### By Environment

```yaml
tasks:
  - name: Load dev certificates
    tags: [dev, certs]

  - name: Load prod certificates
    tags: [prod, certs]

  - name: Enable debug logging
    tags: [dev, logging]
```

---

## 06. Comprehensive Tagged Playbook

```yaml
---
- name: Full Stack Deployment
  hosts: all
  become: true
  gather_facts: true

  tasks:
    # Phase: setup
    - name: Update package cache
      ansible.builtin.apt:
        update_cache: true
      tags:
        - always
        - setup

    - name: Install system packages
      ansible.builtin.apt:
        name: [curl, git, vim]
        state: present
      tags:
        - install
        - setup
        - packages

    # Phase: configure
    - name: Deploy nginx config
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags:
        - configure
        - nginx

    - name: Deploy app config
      ansible.builtin.template:
        src: app.conf.j2
        dest: /etc/myapp/app.conf
      tags:
        - configure
        - app

    # Phase: services
    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
      tags:
        - services
        - nginx

    # Phase: debug (only when requested)
    - name: Show all variables
      ansible.builtin.debug:
        var: hostvars[inventory_hostname]
      tags:
        - never
        - debug
```

---

## 07. Hands-on

1. Create a tagged playbook `lab020-tags.yml` with tasks covering `install`, `configure`, `always`, and `never`/`debug` tags.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab020-tags.yml << 'EOF'
   ---
   - name: Tags Practice
     hosts: all
     become: true
     gather_facts: true

     tasks:
       - name: Gather facts (always)
         ansible.builtin.debug:
           msg: \"Host: {{ inventory_hostname }}, OS: {{ ansible_distribution }}\"
         tags:
           - always

       - name: Install curl
         ansible.builtin.apt:
           name: curl
           state: present
           update_cache: true
         tags:
           - install
           - packages

       - name: Install vim
         ansible.builtin.apt:
           name: vim
           state: present
         tags:
           - install
           - packages
           - editors

       - name: Create config file
         ansible.builtin.copy:
           content: \"# Configured by Ansible\n\"
           dest: /tmp/tagged-config.txt
         tags:
           - configure

       - name: Debug task (only on request)
         ansible.builtin.debug:
           msg: \"System memory: {{ ansible_memtotal_mb }} MB\"
         tags:
           - never
           - debug
   EOF"
   ```

2. List all tags defined in the playbook without running it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --list-tags"

   ### Output
   # playbook: lab020-tags.yml
   #   play #1 (all): Tags Practice
   #     TASK TAGS: [always, configure, debug, editors, install, never, packages]
   ```

3. Run only the `install` tasks, then skip the `install` tasks.

   ??? success "Solution"

   ```sh
   # Only run install tasks
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --tags install"

   # Skip install tasks
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --skip-tags install"
   ```

4. Run the `debug` task that is tagged `never` by explicitly requesting it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --tags debug"
   ```

5. Run both the `install` and `configure` tags together.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab020-tags.yml --tags install,configure"
   ```

---

## 08. Summary

- Tags can be applied to **tasks, blocks, plays, and roles**
- `--tags X` runs only tagged tasks; `--skip-tags X` skips them
- `always` tag runs even when using `--tags`; `never` tag requires explicit `--tags never`
- `--list-tags` shows all tags; `--list-tasks` shows which tasks match
- Use **phase-based tags** (install/configure/deploy/verify) for large playbooks
- Multiple tags on a single task enable flexible selection strategies
