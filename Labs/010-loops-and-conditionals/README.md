<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-010.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-010.yaml/badge.svg" alt="Build Status">
</a>

---


# Lab 010 - Loops and Conditionals in Ansible

- In this section, we will cover **Loops and Conditionals in Ansible**.
- Loops assist in efficiently performing repetitive tasks.
- Conditions allow tasks to be executed based on specific criteria.
- See documentation about [Loops](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html) and [Conditionals](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html) in Ansible.

<img src="../assets/images/ansible-Loop-With-items.webp" height="800px">

---


## 01. Ansible Loops

#### Basic loop

- Ansible provides a `loop` keyword to execute tasks multiple times with different inputs:

```yaml
---
- hosts: localhost
  tasks:
    - name: Install multiple packages
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - git
        - curl
        - vim
```
<br/>

#### Loop with dictionaries

- Loops can be used with dictionaries to process structured data:

```yaml
---
- hosts: localhost
  tasks:
    - name: Add multiple users
      user:
        name: "{{ item.name }}"
        shell: "{{ item.shell }}"
      loop:
        - { name: "alice", shell: "/bin/bash" }
        - { name: "bob", shell: "/bin/zsh" }
```
<br/>

#### Nested loops

- Nested loops allow iterating over multiple lists:

```yaml
---
- hosts: localhost
  tasks:
    - name: Assign permissions
      file:
        path: "/home/{{ item.0 }}/{{ item.1 }}"
        state: touch
        owner: "{{ item.0 }}"
      loop:
        - ["alice", "bob"]
        - ["file1.txt", "file2.txt"]
      loop_control:
        loop_var: item
```

---

## 02. Ansible Conditionals

#### Using the `when` clause

- Conditionals can be defined using the `when` clause:

```yaml
---
- hosts: localhost
  tasks:
    - name: Install Apache only on Ubuntu
      apt:
        name: apache2
        state: present
      when: ansible_os_family == "Debian"
```
<br/>

#### Complex conditionals

- Multiple conditionals can be combined with `and`, `or`, and `not` clauses:

```yaml
---
- hosts: localhost
  tasks:
    - name: Restart service only if running
      service:
        name: nginx
        state: restarted
      when: ansible_os_family == "RedHat" and ansible_distribution_major_version | int >= 7
```

---

## 03. Combining loops and conditionals

- Loops and conditionals can be used together:

```yaml
---
- hosts: localhost
  tasks:
    - name: Create users only if home directory does not exist
      user:
        name: "{{ item }}"
        state: present
      loop:
        - alice
        - bob
      when: not ansible_facts['getent_passwd'][item] is defined
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>
<br/>


## 04. Hands-on

- Try writing a playbook that installs different packages based on the OS family.
- Try to use as many parts as you can (external vars, vars, loops, conditions etc) while doing so.
