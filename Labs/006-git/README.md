<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-006.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-006.yaml/badge.svg" alt="Build Status">
</a>

---

# Lab 006 - Git Integration with Ansible

- In this section, we will cover [**Git integration with Ansible**](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/git_module.html).
- We will learn how to automate **Git** operations on remote servers using **Ansible** playbooks.
- This is useful for deploying code, managing repositories, and keeping your infrastructure up to date.

<img src="../assets/images/Ansible-Git.png" width="800px" style="border-radius: 10px;">

---

## 01. Git Module Basics

- Ansible provides the `ansible.builtin.git` module to manage Git repositories on remote hosts.
- The module supports cloning, pulling, checking out branches/tags, and more.
- Key parameters:

    | Parameter | Description                                                     |
    |-----------|-----------------------------------------------------------------|
    | `repo`    | URL of the Git repository                                       |
    | `dest`    | Destination path on the remote host                             |
    | `version` | Branch, tag, or commit to checkout (default: HEAD)              |
    | `force`   | Force checkout/update even if working directory is dirty        |
    | `update`  | Pull latest changes if repository already exists (default: yes) |
    | `clone`   | Perform clone operation (default: yes)                          |

    - For more details, refer to the [Ansible Git module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/git_module.html).

---

#### Ansible Git `ansible.builtin.git` examples: 

## 02. Cloning Repositories

- Use the `git` module to clone a repository to a remote server.
- Specify the `repo` and `dest` parameters.
- If the repository already exists at the destination, it will not be cloned again unless `force` is set to `yes`.
- By default, the latest commit from the default branch is checked out.
- Here is an example playbook that clones a public Git repository:

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Clone a public Git repository
          ansible.builtin.git:
            repo: 'https://github.com/octocat/Hello-World.git'
            dest: /opt/hello-world
    ```

-  **Example: Cloning with Specific Branch**

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Clone repository and checkout specific branch
          ansible.builtin.git:
            repo: 'https://github.com/example/repo.git'
            dest: /opt/myapp
            version: develop
    ```

---

## 03. **Updating Repositories**

- The `git` module automatically pulls changes if the repository exists and `update` is true.
- Use `force: yes` to overwrite local changes.

#### **Example: Pull Latest Changes**

```yaml
---
- hosts: all
  tasks:
    - name: Update repository to latest commit
      ansible.builtin.git:
        repo: 'https://github.com/example/repo.git'
        dest: /opt/myapp
        update: yes
        force: yes
```

---

## 04. **Working with Branches and Tags**

- Use the `version` parameter to checkout specific branches, tags, or commits.

#### **Example: Checkout a Tag**

```yaml
---
- hosts: all
  tasks:
    - name: Checkout specific tag
      ansible.builtin.git:
        repo: 'https://github.com/example/repo.git'
        dest: /opt/myapp
        version: v1.0.0
```

#### **Example: Switch Branches**

```yaml
---
- hosts: all
  tasks:
    - name: Switch to main branch
      ansible.builtin.git:
        repo: 'https://github.com/example/repo.git'
        dest: /opt/myapp
        version: main
```

---

## 05. **Authentication and SSH**

- For private repositories, use SSH keys or HTTPS with credentials.
- Ensure SSH keys are properly configured on the Ansible controller and remote hosts.

#### **Example: Using SSH Key**

```yaml
---
- hosts: all
  tasks:
    - name: Clone private repo using SSH
      ansible.builtin.git:
        repo: 'git@github.com:example/private-repo.git'
        dest: /opt/private-app
        key_file: /home/ansible/.ssh/id_rsa
```

#### **Example: Using HTTPS with Token**

```yaml
---
- hosts: all
  vars:
    git_token: "{{ lookup('env', 'GIT_TOKEN') }}"
  tasks:
    - name: Clone with HTTPS authentication
      ansible.builtin.git:
        repo: "https://{{ git_token }}@github.com/example/repo.git"
        dest: /opt/myapp
```

---

## 06. **Common Patterns and Best Practices**

- Always use absolute paths for `dest`.
- Handle idempotency by letting the module manage updates.
- Use `force: yes` carefully as it can overwrite changes.
- Store sensitive information like tokens in Ansible Vault.

#### **Example: Idempotent Deployment**

```yaml
---
- hosts: all
  tasks:
    - name: Ensure application is at latest version
      ansible.builtin.git:
        repo: 'https://github.com/example/app.git'
        dest: /opt/myapp
        version: main
      register: git_result

    - name: Restart service if code changed
      ansible.builtin.service:
        name: myapp
        state: restarted
      when: git_result.changed
```

---

## 07. **Hands-on**

<img src="../assets/images/practice.png" width="800px">
<br/>

* Clone a public Git repository to `/opt/hello-world` on your target servers.

    <details>
    <summary>Solution</summary>

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Clone Hello World repository
          ansible.builtin.git:
            repo: 'https://github.com/octocat/Hello-World.git'
            dest: /opt/hello-world
    ```

    </details>

* Create a playbook that clones a repository and checks out a specific branch called `develop`.

    <details>
    <summary>Solution</summary>

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Clone and checkout develop branch
          ansible.builtin.git:
            repo: 'https://github.com/example/repo.git'
            dest: /opt/myapp
            version: develop
    ```

    </details>

* Write a playbook that updates an existing repository to the latest commit on the main branch.

    <details>
    <summary>Solution</summary>

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Update repository to latest main
          ansible.builtin.git:
            repo: 'https://github.com/example/repo.git'
            dest: /opt/myapp
            version: main
            update: yes
    ```

    </details>

* Create a playbook that checks out a specific tag (e.g., `v1.0.0`) from a repository.

    <details>
    <summary>Solution</summary>

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Checkout specific tag
          ansible.builtin.git:
            repo: 'https://github.com/example/repo.git'
            dest: /opt/myapp
            version: v1.0.0
    ```

    </details>

* Modify a playbook to force update a repository, overwriting any local changes.

    <details>
    <summary>Solution</summary>

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Force update repository
          ansible.builtin.git:
            repo: 'https://github.com/example/repo.git'
            dest: /opt/myapp
            force: yes
    ```

    </details>

* Create a playbook that clones a repository and restarts a service if the code was updated.

    <details>
    <summary>Solution</summary>

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Deploy application
          ansible.builtin.git:
            repo: 'https://github.com/example/app.git'
            dest: /opt/myapp
          register: git_deploy

        - name: Restart service if changed
          ansible.builtin.service:
            name: myapp
            state: restarted
          when: git_deploy.changed
    ```

    </details>

* Set up SSH key authentication for cloning a private repository.

    <details>
    <summary>Solution</summary>

    First, ensure SSH key is copied to the remote host:

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Copy SSH private key
          ansible.builtin.copy:
            src: ~/.ssh/id_rsa
            dest: /home/ansible/.ssh/id_rsa
            mode: '0600'

        - name: Clone private repository
          ansible.builtin.git:
            repo: 'git@github.com:example/private-repo.git'
            dest: /opt/private-app
            key_file: /home/ansible/.ssh/id_rsa
    ```

    </details>

---

## 08. **Summary**

🔹 Use `ansible.builtin.git` module for Git operations in playbooks.  
🔹 Supports cloning, pulling, and checking out branches/tags.  
🔹 Ensure proper authentication for private repositories.  
🔹 Leverage idempotency for safe repeated runs.  
🔹 Combine with other modules for complete deployment workflows.

