---
# Ansible Lint and Testing

* In this lab we learn how to use `ansible-lint` to enforce code quality and `Molecule` to test roles in isolated environments.
* Quality tools catch bugs early and enforce consistent coding standards.

## What will we learn?

- Installing and running `ansible-lint`
- Understanding and fixing lint warnings
- An introduction to Molecule for role testing
- Integrating lint into CI/CD pipelines

---

## Prerequisites

- Complete [Lab 009](../009-roles/README.md#usage) in order to have working Ansible roles.

---

## 01. What is `ansible-lint`?

- `ansible-lint` is a static analysis tool that checks YAML syntax and Ansible best practices.
- It detects common mistakes such as deprecated modules and bad patterns.
- It enforces consistent code style across your codebase.
- It integrates with pre-commit hooks and CI/CD pipelines.

---

## 02. Installing `ansible-lint`

```sh
# Install via pip
pip install ansible-lint

# Install in a virtual environment
python3 -m venv lint-env
source lint-env/bin/activate
pip install ansible-lint

# Check version
ansible-lint --version
```

---

## 03. Running `ansible-lint`

```sh
# Lint a specific playbook
ansible-lint site.yml

# Lint all playbooks in current directory
ansible-lint

# Lint a role
ansible-lint roles/nginx/

# List available rules
ansible-lint --list-rules

# Show only specific rule violations
ansible-lint --include-list fqcn

# Skip specific rules
ansible-lint site.yml --skip-list yaml[line-length],name[casing]

# Output formats
ansible-lint --format full        # Detailed (default)
ansible-lint --format pep8        # PEP8-style
ansible-lint --format sarif       # For GitHub Code Scanning
ansible-lint --format codeclimate # For GitLab CI
```

---

## 04. Common Lint Warnings

### `fqcn` - Use Fully Qualified Collection Names

```yaml
# BAD: Short module name
- apt:
    name: nginx
    state: present

# GOOD: FQCN
- ansible.builtin.apt:
    name: nginx
    state: present
```

### `name[casing]` - Task Names Should Be Capitalized

```yaml
# BAD
- name: install nginx
  ansible.builtin.apt:
    name: nginx

# GOOD
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
```

### `yaml[truthy]` - Use true/false, not yes/no

```yaml
# BAD
become: yes
enabled: no

# GOOD
become: true
enabled: false
```

### `no-changed-when` - command/shell should have changed_when

```yaml
# BAD: shell without changed_when
- ansible.builtin.shell:
    cmd: /opt/app/update.sh

# GOOD
- ansible.builtin.shell:
    cmd: /opt/app/update.sh
  register: update_result
  changed_when: "'updated' in update_result.stdout"
```

### `risky-file-permissions` - Files should have explicit permissions

```yaml
# BAD: No permissions set
- ansible.builtin.copy:
    src: myfile.conf
    dest: /etc/app/myfile.conf

# GOOD
- ansible.builtin.copy:
    src: myfile.conf
    dest: /etc/app/myfile.conf
    mode: "0644"
    owner: root
    group: root
```

---

## 05. `.ansible-lint` Configuration File

```yaml
# .ansible-lint
---
profile: moderate # minimal, moderate, safety, shared, production

skip_list:
  - yaml[line-length] # Lines can exceed 80 chars

warn_list:
  - experimental # Warn but don't fail

exclude_paths:
  - .git/
  - .venv/
  - tests/

offline: false # Allow downloading schemas
```

---

## 06. Introduction to Molecule

- Molecule is a testing framework for Ansible roles.
- It creates test environments (Docker, Vagrant, EC2), runs your role, verifies the result with tests, and destroys the environment after testing.

```sh
# Install Molecule
pip install molecule[docker]

# Create a new role with Molecule
molecule init role myorg.nginx --driver-name docker

# Initialize Molecule in existing role
cd roles/nginx
molecule init scenario --driver-name docker
```

---

## 07. Molecule Directory Structure

```
roles/nginx/
└── molecule/
    └── default/
        ├── converge.yml      # Playbook that applies your role
        ├── molecule.yml      # Molecule configuration
        └── verify.yml        # Tests to verify the role worked
```

```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy

driver:
  name: docker

platforms:
  - name: instance
    image: ubuntu:22.04
    pre_build_image: true

provisioner:
  name: ansible

verifier:
  name: ansible
```

```yaml
# molecule/default/converge.yml
---
- name: Converge
  hosts: all
  become: true

  roles:
    - role: nginx
```

```yaml
# molecule/default/verify.yml
---
- name: Verify
  hosts: all
  gather_facts: false

  tasks:
    - name: Check nginx is installed
      ansible.builtin.command:
        cmd: nginx -v
      register: nginx_version
      failed_when: nginx_version.rc != 0
      changed_when: false

    - name: Check nginx is running
      ansible.builtin.service_facts:

    - name: Assert nginx is running
      ansible.builtin.assert:
        that:
          - "'nginx' in services"
          - "services['nginx'].state == 'running'"
```

---

## 08. Running Molecule Tests

```sh
# Full test cycle: create → converge → verify → destroy
molecule test

# Individual stages
molecule create          # Create test instances
molecule converge        # Apply the role
molecule verify          # Run verification tests
molecule idempotency     # Run role twice to check idempotency
molecule destroy         # Remove test instances

# Login to the test instance for manual inspection
molecule login

# Run without destroying (for debugging)
molecule test --destroy never
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 09. Hands-on

1. Install `ansible-lint` and verify the version.

   ??? success "Solution"

   ```sh
   pip install ansible-lint
   ansible-lint --version
   ```

2. Create a playbook with lint issues and run `ansible-lint` against it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab024-unlinted.yml << 'EOF'
   ---
   - name: unlinted playbook example
     hosts: all
     become: yes

     tasks:
       - apt:
           name: curl
           state: present

       - shell: echo \"hello\" >> /tmp/test.txt

       - copy:
           src: /tmp/test.txt
           dest: /tmp/test2.txt
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint lab024-unlinted.yml"
   ```

3. Fix the lint issues in the playbook by using FQCNs, `true`/`false`, explicit permissions, and `changed_when`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab024-linted.yml << 'EOF'
   ---
   - name: Linted playbook example
     hosts: all
     become: true

     tasks:
       - name: Install curl
         ansible.builtin.apt:
           name: curl
           state: present

       - name: Write to test file
         ansible.builtin.shell:
           cmd: \"echo 'hello' >> /tmp/test.txt\"
         changed_when: true

       - name: Copy test file
         ansible.builtin.copy:
           src: /tmp/test.txt
           dest: /tmp/test2.txt
           mode: \"0644\"
           remote_src: true
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint lab024-linted.yml"
   ```

4. Create an `.ansible-lint` config file that skips the `yaml[line-length]` rule.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > .ansible-lint << 'EOF'
   ---
   profile: moderate
   skip_list:
     - yaml[line-length]
   EOF"
   ```

---

## 10. Summary

- `ansible-lint` enforces YAML best practices and Ansible conventions
- Use **FQCNs**, `true`/`false`, explicit permissions, and `changed_when` to pass lint
- `.ansible-lint` configures which rules to skip or treat as warnings
- **Molecule** automates role testing: create → converge → verify → destroy
- Integrate `ansible-lint` into pre-commit hooks and CI/CD for automatic checks
