---
# Create User with Ansible

* In this section we will understand how to use the `Create User Playbook`.
* We will have hands-on experience in writing it ourselves using a sample playbook.
* We will review the playbook's `vars`, `become`, `changed_when` sections.
* We will edit the script to create another user with different name and password.
* <img src="../assets/images/ansible-user.jpeg" width="400px"> <br/> ---

## What will we learn?

- How to use Ansible's `user` module to create and manage users
- How to handle password hashing securely
- How to generate SSH keys for users
- How to use `become` for privilege escalation

---

## Prerequisites

- Complete the [previous lab](../006-git/README.md) in order to have `Ansible` set up.

---

## 01. Ansible's `user` module

- Ansible's `user` module is a powerful tool for managing user accounts on remote systems. It allows you to create, update, and remove users, set passwords, manage groups, and configure SSH keys. This is essential in automating system administration tasks.
- See the [Ansible `user module` documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html).

---

## 02. Create a user

- See the below basic example for creating a user named `username` with a hashed password, adding them to the `wheel` group, and generating an SSH key.

```yaml
- name: Create a new user
  ansible.builtin.user:
    name: "username"
    password: "{{ 'password' | password_hash('sha512') }}"
    groups: "wheel"
    shell: /bin/bash
    state: present
    create_home: true
    generate_ssh_key: true
```

- See the below advanced example, including `custom home`, `expiry`, and `comment`

```yaml
- name: Create a user with custom options
  ansible.builtin.user:
    name: "devops"
    comment: "DevOps Engineer"
    home: "/opt/devops"
    expires: 1751328000 # Unix timestamp for expiry
    password: "{{ 'SuperSecret123' | password_hash('sha512') }}"
    groups: "sudo"
    shell: /bin/zsh
    state: present
    create_home: true
```

---

## 03. Password management

- Always hash passwords using the `password_hash` filter for security.
- Example:
  ```yaml
  password: "{{ 'mysecret' | password_hash('sha512') }}"
  ```
- You can generate a hash in Python:
  ```python
  import crypt
  print(crypt.crypt('mysecret', crypt.mksalt(crypt.METHOD_SHA512)))
  ```
- See the [`password hash` in Ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html#hashing).

---

## 04. SSH key setup

- Use `generate_ssh_key: true` to automatically create an SSH key for the user.
- You can specify key type and file:
  ```yaml
  generate_ssh_key: true
  ssh_key_type: rsa
  ssh_key_bits: 4096
  ssh_key_file: .ssh/id_rsa
  ```

## 05. Troubleshooting & verification

- Use the `command` module to verify user creation:
  ```yaml
  - name: Verify user
    ansible.builtin.command: "id username"
    register: user_info
    changed_when: false
    failed_when: user_info.rc != 0
  ```
- See `/etc/passwd` and `/etc/group` for user and group info.

## 06. Best practices

- Use `become: true` for privilege escalation.
- Use variables for usernames and passwords to avoid hardcoding.
- Document your playbooks for clarity.
- Clean up users with `state: absent` when needed.

---

## 07. Summary

- The `ansible.builtin.user` module creates, modifies, and removes OS users idempotently
- `state: present` creates the user; `state: absent` with `remove: true` deletes it and its home directory
- `become: true` is required for user management - Ansible escalates to root via `sudo`
- SSH authorized keys are managed with the `ansible.posix.authorized_key` module, separate from user creation
- Running the same playbook twice produces `changed=0` on the second run - demonstrating idempotency
