<div align="center">
    <a href="https://stackoverflow.com/users/1755598/codewizard"><img src="https://stackoverflow.com/users/flair/1755598.png" height="50" alt="profile for CodeWizard at Stack Overflow, Q&amp;A for professional and enthusiast programmers" title="profile for CodeWizard at Stack Overflow, Q&amp;A for professional and enthusiast programmers"></a>
  
  ![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)
  [![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/) 
  [![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=flat&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com) [![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=flat&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il) 
  <a href=""><img src="https://img.shields.io/github/stars/nirgeier/AnsibleLabs"></a> 
  <img src="https://img.shields.io/github/forks/nirgeier/AnsibleLabs">  
  <a href="https://discord.gg/U6xW23Ss"><img src="https://img.shields.io/badge/discord-7289da.svg?style=plastic&logo=discord" alt="discord" style="height: 20px;"></a>
  <img src="https://img.shields.io/github/contributors-anon/nirgeier/AnsibleLabs?color=yellow&style=plastic" alt="contributors" style="height: 20px;"></a>
  <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/apache%202.0-blue.svg?style=plastic&label=license" alt="license" style="height: 20px;"></a>
  <a href="https://github.com/nirgeier/AnsibleLabs/pulls"><img src="https://img.shields.io/github/issues-pr/nirgeier/AnsibleLabs?style=plastic&logo=pr" alt="Pull Requests" style="height: 20px;"></a> 

If you appreciate the effort, Please <img src="https://raw.githubusercontent.com/nirgeier/labs-assets/main/assets/images/star.png" height="20px"> this project

</div>

---


# Lab 010 - Loops and Conditions in Ansible

- In this section, we will cover **Loops and Conditions in Ansible**.
- Loops help in performing repetitive tasks efficiently.
- Conditions allow tasks to be executed based on specific criteria.

<img src="../../resources/ansible-loops-conditions.png" height="500px">

---

- [Lab 010 - Loops and Conditions in Ansible](#lab-010---loops-and-conditions-in-ansible)
  - [01. Ansible Loops](#01-ansible-loops)
    - [01.01. Basic Loop](#0101-basic-loop)
    - [01.02. Loop with Dictionaries](#0102-loop-with-dictionaries)
    - [01.03. Nested Loops](#0103-nested-loops)
  - [02. Conditions in Ansible](#02-conditions-in-ansible)
    - [02.01. Using `when`](#0201-using-when)
    - [02.02. Complex Conditions](#0202-complex-conditions)
    - [02.03. Combining Loops and Conditions](#0203-combining-loops-and-conditions)

---

## 01. Ansible Loops

### 01.01. Basic Loop

- Ansible provides a `loop` keyword to execute tasks multiple times with different inputs.

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

### 01.02. Loop with Dictionaries

- Loops can be used with dictionaries to process structured data.

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

### 01.03. Nested Loops

- Nested loops allow iterating over multiple lists.

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

## 02. Conditions in Ansible

### 02.01. Using `when`

- Conditions are defined using the `when` clause.

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

### 02.02. Complex Conditions

- Multiple conditions can be combined with `and`, `or`, and `not`.

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

### 02.03. Combining Loops and Conditions

- Loops and conditions can be used together.

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

<img src="../../resources/practice.png" width="250px">
<br/>

- Try writing a playbook that installs different packages based on the OS family.
- Try to use as many parts as you can (external vars, vars, loops, conditions etc)

---
<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
    <a href="/Labs/009-roles">:arrow_backward: /Labs/009-roles</a>
    &emsp;<a href="/Labs">Back to labs list</a>
    &emsp;<a href="/Labs/011-jinja-templating">/Labs/011-jinja-templating :arrow_forward:</a>
</p>
<!--- Labs Navigation End -->

