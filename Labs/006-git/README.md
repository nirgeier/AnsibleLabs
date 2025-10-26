<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-006.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-006.yaml/badge.svg" alt="Build Status">
</a>

---

# Lab 006 - Git Integration with Ansible

- In this section, we will cover **`Git` integration with `Ansible`**.
- We will learn how to automate `Git` operations on remote servers using `Ansible` playbooks.
- This is useful for deploying code, managing repositories and keeping your infrastructure up to date.


  <img src="../assets/images/Ansible-Git.png" width="800px">
  <br/>



## 01. **Objectives**
- Understand how to use `Ansible` modules to interact with `Git`.
- Automate cloning, updating and managing `Git` repositories.
- Practice using playbooks to deploy code from version control.

## 02. **Key Concepts**
- **ansible.builtin.git**: Ansible’s built-in module for managing `Git` repositories.
- **Idempotency**: Ensuring thatrepeated playbook runs do not cause unwanted changes.
- **Authentication**: Using `SSH` keys or `HTTPS` for secure repository access.

## 03. **Example Tasks**
- Clone a repository to a target server.
- Update the repository to the latest commit.
- Set up SSH keys for secure `Git` access.

#### **Example: Cloning a `Git` Repository**

```yaml
---
- hosts: all
  tasks:
    - name: Clone a Git repository
      ansible.builtin.git:
        repo: 'https://github.com/example/repo.git'
        dest: /opt/myapp
        version: main
        force: yes
```

---

## 04. **Hands-on**


  <img src="../assets/images/practice.png" width="800px">
  <br/>

- Understand the `Git` Playbook.
- Try cloning a public repository to your server.
- Update the playbook to pull the latest changes.
- Experiment with deploying different branches or tags.
- Try to write it yourself using the sample playbook.
- Review the playbook `vars` section which is new to us.
- In Lab 008 we will also add a task to clone `Git`.
