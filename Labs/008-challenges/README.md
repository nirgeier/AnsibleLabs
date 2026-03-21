---
# Lab 008 - Challenges

* This lab is a set of challenges that combine skills from the previous labs (000-007).
* You will practice creating users, building inventories, and managing Git repositories using Ansible.
* Each challenge has a clear goal - try to solve it yourself before checking the solution.
* Completing these challenges will reinforce your understanding of core Ansible concepts.

## What will we learn?

- How to apply the `user` module to create system accounts on remote hosts
- How to write an inventory file that references the created users as `ansible_ssh_user`
- How to use the `git` module to clone and push to repositories on remote hosts
- How to chain multiple modules in a single playbook to complete a real-world workflow

---

## Prerequisites

- Complete all previous labs (000-007)

---

## 01. Challenge 1 - User Management

### Goal

Create a user named after the hostname on each managed host, verify the user exists, then update the inventory to connect as that user.

### Tasks

1. Write a playbook that creates a user named `{{ inventory_hostname }}` on all hosts.
2. Verify the user was created by displaying its name in a debug message.
3. Add an SSH key for the user during creation.
4. Update your inventory so the connection uses the new user:

```ini
server-1    ansible_host=server-1 ansible_ssh_user=server-1
server-2    ansible_host=server-2 ansible_ssh_user=server-2
server-3    ansible_host=server-3 ansible_ssh_user=server-3
```

??? success "Solution"

    ```yaml
    ---
    - name: Challenge 1 - Create user per hostname
      hosts: all
      tasks:
        - name: Create user named after the host
          ansible.builtin.user:
            name: "{{ inventory_hostname }}"
            groups: root
            shell: /bin/bash
            state: present
            generate_ssh_key: true
            ssh_key_bits: 2048
            ssh_key_file: .ssh/id_rsa
            create_home: true

        - name: Verify user was created
          ansible.builtin.debug:
            msg: "Created user: {{ inventory_hostname }}"
    ```

---

## 02. Challenge 2 - Git Repository Management

### Goal

On a remote host, install `git`, clone a repository, make a change, commit it, and push it back to the remote.

### Tasks

1. Ensure `git` is installed on the target host using the `apt` module.
2. Clone a repository from GitHub or GitLab to `/tmp/ansible-git-demo`.
3. Write a file to the cloned directory using the `copy` module.
4. Commit and push the change using the `shell` module.

??? success "Solution"

    ```yaml
    ---
    - name: Challenge 2 - Clone, modify, and push a git repository
      hosts: server-2
      gather_facts: false
      tasks:
        - name: Ensure git is installed
          ansible.builtin.apt:
            name: git
            state: present
          become: true

        - name: Clone the repository
          ansible.builtin.git:
            repo: https://github.com/yourusername/yourrepository.git
            dest: /tmp/ansible-git-demo
            clone: true
            update: true

        - name: Write a change file
          ansible.builtin.copy:
            dest: /tmp/ansible-git-demo/ansible-change.txt
            content: "Change made by Ansible on {{ ansible_date_time.iso8601 }}\n"
            mode: "0644"

        - name: Commit and push changes
          ansible.builtin.shell: |
            cd /tmp/ansible-git-demo
            git config user.email "you@example.com"
            git config user.name "Ansible Bot"
            git add ansible-change.txt
            git commit -m "Automated commit by Ansible"
            git push origin main
          args:
            executable: /bin/bash
          changed_when: true
    ```

---

## 03. Hands-on

1. Run the user-creation playbook against all three lab servers.
2. Verify each user exists by running `ansible all -m shell -a "id {{ inventory_hostname }}"`.
3. Update your inventory file to use the new users and re-run `ansible all -m ping` to confirm connectivity.
4. Clone a public GitHub repo to `server-2` using the `git` module.
5. Add a file to the cloned repo and commit the change using a `shell` task.

---

## 04. Summary

- 🔹 The `ansible.builtin.user` module can create, update, and remove system users, including SSH key generation
- 🔹 Using `{{ inventory_hostname }}` as a username ties each host's account to its identity in the inventory
- 🔹 Inventories can specify `ansible_ssh_user` per host to control which account Ansible connects with
- 🔹 The `ansible.builtin.git` module handles clone and update operations; push requires a `shell` task
- 🔹 Challenge labs combine multiple modules in sequence - this mirrors real automation workflows
