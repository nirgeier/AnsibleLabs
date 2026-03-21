---
# Galaxy and Collections

* In this lab we explore **Ansible Galaxy** - the community hub for sharing and downloading roles and collections.
* We also learn about **Collections** - the modern format for bundling modules, plugins, and roles together.

## What will we learn?

- How to find, install, and use roles from Ansible Galaxy
- What Collections are and how they differ from roles
- Installing collections with `ansible-galaxy collection install`
- Managing dependencies with `requirements.yml`
- Fully Qualified Collection Names (FQCNs)

---

## Prerequisites

- Complete [Lab 009](../009-roles/README.md#usage) in order to have a working understanding of Ansible roles.

---

## 01. Ansible Galaxy Overview

- Ansible Galaxy: [https://galaxy.ansible.com](https://galaxy.ansible.com)
- A free repository of community-contributed roles and collections
- Over 30,000 roles available

```sh
# Search for a role
ansible-galaxy search nginx

# Show info about a role
ansible-galaxy info geerlingguy.nginx

# Install a role
ansible-galaxy install geerlingguy.nginx

# Install to a specific path
ansible-galaxy install geerlingguy.nginx --roles-path ./roles

# List installed roles
ansible-galaxy list

# Remove a role
ansible-galaxy remove geerlingguy.nginx
```

---

## 02. Using Galaxy Roles

```yaml
# site.yml
---
- name: Configure web server with Galaxy role
  hosts: webservers
  become: true

  roles:
    - geerlingguy.nginx # Galaxy role (namespace.rolename)

    - role: geerlingguy.nginx
      vars:
        nginx_vhosts:
          - listen: "80"
            server_name: "example.com"
            root: /var/www/example
```

---

## 03. `requirements.yml` - Declare Dependencies

```yaml
# requirements.yml
---
roles:
  # From Galaxy (namespace.role_name)
  - name: geerlingguy.nginx
    version: "3.1.0"

  - name: geerlingguy.postgresql
    version: ">=3.0.0"

  # From GitHub
  - name: my_custom_nginx
    src: https://github.com/myorg/ansible-role-nginx
    version: main

  # From a tarball
  - name: offline_role
    src: https://example.com/releases/role.tar.gz

collections:
  # From Galaxy
  - name: community.general
    version: ">=7.0.0"

  - name: community.docker
    version: "3.4.0"

  - name: amazon.aws
    version: ">=6.0.0"

  # From Automation Hub
  - name: redhat.rhel_system_roles
    source: https://cloud.redhat.com/api/automation-hub/
```

```sh
# Install all requirements
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install -r requirements.yml

# Install both at once
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
```

---

## 04. What are Collections?

Collections bundle:

- **Modules** - e.g., `community.docker.docker_container`
- **Plugins** - connection, filter, lookup, callback
- **Roles** - distributed inside collections
- **Playbooks** - included playbooks

```
namespace.collection_name
└── plugins/
│   ├── modules/
│   ├── filter/
│   └── lookup/
├── roles/
├── playbooks/
├── galaxy.yml        # Collection manifest
└── README.md
```

---

## 05. Fully Qualified Collection Names (FQCNs)

All modules and plugins should be referenced by their FQCN:

```yaml
tasks:
  # Built-in modules (ansible.builtin)
  - ansible.builtin.apt:
      name: nginx
      state: present

  - ansible.builtin.copy:
      src: file.txt
      dest: /tmp/file.txt

  # Community modules
  - community.general.slack:
      token: "{{ slack_token }}"
      msg: "Deployment complete!"

  - community.docker.docker_container:
      name: myapp
      image: nginx:latest
      state: started
      ports:
        - "80:80"

  # Amazon AWS
  - amazon.aws.ec2_instance:
      name: my-server
      instance_type: t3.micro
      image_id: ami-12345678
      state: present
```

---

## 06. Installing Collections

```sh
# Install a single collection
ansible-galaxy collection install community.docker

# Install a specific version
ansible-galaxy collection install community.docker:3.4.0

# Install multiple collections
ansible-galaxy collection install community.docker community.general amazon.aws

# From requirements.yml
ansible-galaxy collection install -r requirements.yml

# Upgrade an installed collection
ansible-galaxy collection install community.docker --upgrade

# List installed collections
ansible-galaxy collection list

# Show collection info
ansible-galaxy collection info community.docker
```

---

## 07. Building and Publishing Your Own Collection

```sh
# Create a collection skeleton
ansible-galaxy collection init myorg.mytools

# Structure created:
# myorg/mytools/
# ├── docs/
# ├── galaxy.yml        # Collection manifest
# ├── plugins/
# │   └── README.md
# ├── README.md
# └── roles/
```

```yaml
# galaxy.yml - Collection manifest
namespace: myorg
name: mytools
version: 1.0.0
authors:
  - Your Name <you@example.com>
description: My custom Ansible tools
license:
  - GPL-2.0-or-later
dependencies:
  community.general: ">=7.0.0"
```

```sh
# Build the collection tarball
ansible-galaxy collection build

# Publish to Galaxy (requires API token)
ansible-galaxy collection publish myorg-mytools-1.0.0.tar.gz --token YOUR_API_TOKEN
```

---

## 08. Hands-on

1. Create a `requirements.yml` file inside the controller and install the listed collections.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > requirements.yml << 'EOF'
   ---
   collections:
     - name: community.general
     - name: community.docker
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection install -r requirements.yml"
   ```

2. Verify the collections are installed and list them.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection list"

   ### Output
   # /root/.ansible/collections/ansible_collections
   # Collection        Version
   # ----------------- -------
   # community.docker  3.x.x
   # community.general 7.x.x
   ```

3. Create and run a playbook that uses the `community.general` collection to generate a random string and query JSON data.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab018-galaxy.yml << 'EOF'
   ---
   - name: Galaxy Collections Practice
     hosts: localhost
     gather_facts: false

     tasks:
       - name: Generate a random password (community.general)
         ansible.builtin.set_fact:
           my_password: \"{{ lookup('community.general.random_string', length=16, special=false) }}\"

       - name: Show the password (masked)
         ansible.builtin.debug:
           msg: \"Generated password: {{ my_password }}\"

       - name: Use the json_query filter (community.general)
         vars:
           data:
             servers:
               - { name: web1, port: 80, active: true }
               - { name: web2, port: 8080, active: false }
               - { name: db1, port: 5432, active: true }
         ansible.builtin.debug:
           msg: \"Active servers: {{ data | community.general.json_query('servers[?active==\`true\`].name') }}\"
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab018-galaxy.yml"
   ```

4. List available modules from the `community.general` collection.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-doc -t module -l | grep community.general | head -10"
   ```

---

## 09. Summary

- **Ansible Galaxy** hosts thousands of free, community-contributed roles and collections
- `requirements.yml` declares all role and collection dependencies for reproducible installs
- **Collections** are the modern format - they bundle modules, plugins, AND roles
- Always use **FQCNs** (`ansible.builtin.copy`) to avoid module name conflicts
- `ansible-galaxy collection list` shows what's installed and where
- Use `ansible-galaxy collection build` and `publish` to share your own collections
