---

# No Inventory

* In this lab we will learn about Ansible inventory and how it affects automation tasks.
* We will start with an empty inventory and observe Ansible's behavior with no hosts defined. Later, we will create and test the inventory file.
* This lab is based upon the previous lab and its docker-compose setup.

## What will we learn?

- How Ansible behaves with no inventory defined
- How to create and configure an inventory file in various formats (`INI`, `YAML`, `JSON`)
- How to use inventory variables and groups
- The difference between static and dynamic inventory

---

## Prerequisites

- Complete the [previous lab](../001-verify-ansible/README.md#usage) in order to have `Ansible` configured.

---

## 01. "Clear" the inventory

- Let's clear the inventory from previous labs and walk through what is `inventory`.
- Create an empty inventory file or remove all host entries from existing inventory:

  ```sh
  # Option 1: Create empty inventory file
  touch $RUNTIME_FOLDER/labs-scripts/inventory

  # Option 2: Clear existing inventory
  echo "# Empty inventory" > $RUNTIME_FOLDER/labs-scripts/inventory
  ```

---

## 02. Create the `inventory` file

#### Ansible Inventory

- An `Ansible` `inventory` can either be a single file or a **collection of files**
- The `inventory` defines the **`[hosts]`** and **`[groups]`** of hosts upon which `Ansible` will operate.
- It's simply a list of servers that `Ansible` can connect with and manage.

#### Key features of Ansible inventory

- Can be in various formats, such as `INI`, `JSON`, `YAML` and more.
- `YAML` being the most common format.
- `inventory` defines the target hosts for `playbook` execution.
- `inventory` organizes hosts into **logical groups** for easier management.
- `inventory` can store **host-specific** variables and **group** variables.
- `inventory` supports nested groups (groups of groups).

---

## 03. `inventory` samples

- ##### `INI` format (basic)

  ```ini
  [webservers]
  web1.example.com
  web2.example.com

  [database]
  db1.example.com
  ```

- ##### `INI` format with variables

  ```ini
  [webservers]
  web1.example.com ansible_port=2222 ansible_user=admin
  web2.example.com ansible_port=2223 ansible_user=admin

  [webservers:vars]
  http_port=80
  max_connections=100

  [database]
  db1.example.com ansible_port=5432

  [database:vars]
  db_type=postgresql
  ```

- ##### `YAML` format

  ```yaml
  all:
    children:
      webservers:
        hosts:
          web1.example.com:
            ansible_port: 2222
            ansible_user: admin
          web2.example.com:
            ansible_port: 2223
            ansible_user: admin
        vars:
          http_port: 80
          max_connections: 100
      database:
        hosts:
          db1.example.com:
            ansible_port: 5432
        vars:
          db_type: postgresql
  ```

- `JSON` format
  ```json
  {
    "all": {
      "hosts": {
        "web1.example.com": {
          "ansible_port": 2222,
          "http_port": 80
        },
        "web2.example.com": {
          "ansible_port": 2223,
          "http_port": 8080
        }
      },
      "children": {
        "database": {
          "hosts": ["db1.example.com"]
        }
      }
    }
  }
  ```

---

## 04. Special Groups in Ansible

- **`all`** - Contains every host in the inventory (automatically created)
- **`ungrouped`** - Contains hosts not assigned to any group (automatically created)

  ```ini
  # Hosts in 'all' group but not in any specific group
  standalone-server.example.com

  [webservers]
  web1.example.com
  web2.example.com
  ```

---

## 05. Inventory Variables

Ansible allows you to define variables at different levels:

- ##### Host Variables

  Variables specific to individual hosts:

  ```ini
  [webservers]
  web1.example.com ansible_port=2222 environment=production
  web2.example.com ansible_port=2223 environment=staging
  ```

- ##### Group Variables

  Variables shared by all hosts in a group:

  ```ini
  [webservers:vars]
  ansible_user=admin
  http_port=80
  ```

- ##### Common Ansible Variables

      | Variable                       | Description                   | Example            |
      |--------------------------------|-------------------------------|--------------------|
      | `ansible_host`                 | Target IP address or hostname | `192.168.1.10`     |
      | `ansible_port`                 | SSH port                      | `2222`             |
      | `ansible_user`                 | SSH username                  | `admin`            |
      | `ansible_ssh_private_key_file` | SSH key path                  | `/path/to/key`     |
      | `ansible_connection`           | Connection type               | `ssh`, `local`     |
      | `ansible_python_interpreter`   | Python path on target         | `/usr/bin/python3` |

---

## 06. Inventory types in Ansible

- **Static Inventory**
  - This is generally a simple text file (usually in INI or YAML format) that lists the hosts and their corresponding groups.

- **Dynamic Inventory**
  - This is generated by a script or a program that retrieves host information from an external source (such as cloud providers like `AWS`, `Azure`, etc.), `LDAP` or from a `database`.
    - This allows for real-time updates and adaptability as environments change.

    ##### Simple Dynamic Inventory Example

    > A basic Python script that generates inventory:

    ```python
    #!/usr/bin/env python3
    import json

    def get_inventory():
        inventory = {
            'webservers': {
                'hosts': ['web1.example.com', 'web2.example.com'],
                'vars': {'http_port': 80}
            },
            'database': {
                'hosts': ['db1.example.com'],
                'vars': {'db_port': 5432}
            }
        }
        return inventory

    if __name__ == "__main__":
        print(json.dumps(get_inventory()))
    ```

    ##### Advanced Dynamic Inventory with Database

    > Example of generating a `dynamic inventory` using `Python` code for fetching data from a database:

    ```python
    #!/usr/bin/env python
    import sqlite3
    import json

    def get_inventory():
        conn = sqlite3.connect('servers.db')
        cursor = conn.cursor()

        cursor.execute('SELECT hostname, group_name, ansible_user FROM servers')
        rows = cursor.fetchall()

        inventory = {'all': {'hosts': [], 'vars': {}}}

        for row in rows:
            hostname, group_name, ansible_user = row

            if group_name not in inventory:
                inventory[group_name] = {'hosts': [], 'vars': {}}

            inventory['all']['hosts'].append(hostname)
            inventory[group_name]['hosts'].append(hostname)
            inventory[group_name]['vars']['ansible_user'] = ansible_user

        conn.close()
        return inventory

    if __name__ == "__main__":
        print(json.dumps(get_inventory()))
    ```

---

## 07. Best Practices for Inventory Management

- **Organization**
  - Use descriptive group names that reflect server roles
  - Create parent-child group relationships for complex infrastructures
  - Keep inventory files in version control

- **Variables**
  - Store sensitive data in Ansible Vault, not plain text inventory
  - Use `group_vars/` and `host_vars/` directories for complex variable structures
  - Keep inventory-specific variables in inventory, playbook-specific ones in playbooks

- **Scalability**
  - Use dynamic inventory for cloud environments
  - Organize large inventories into multiple files
  - Use inventory plugins for modern Ansible versions

- ##### Example: Nested Groups

  ```ini
  [web_prod]
  web-prod-1.example.com
  web-prod-2.example.com

  [web_staging]
  web-staging-1.example.com

  [webservers:children]
  web_prod
  web_staging

  [production:children]
  web_prod
  db_prod
  ```

---

<img src="../assets/images/practice.png" width="800px">
<br/>

## 08. Lab exercise

- Let's create the inventory configuration that we will use for the rest of our labs:

  ```ini
  ### File location: $RUNTIME_FOLDER/labs-scripts/inventory
  ###
  ### List of servers which we want Ansible to connect to
  ### The names are defined in the docker-compose
  ###

  [servers]
  # No server will be defined at this step
  ```

---

## 09. No inventory invocation

- Once all is ready, let's check if the controller can connect to the servers using `ping`

  ```sh
  # Ping the servers and check that they are "alive"
  docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"

  ## Output
  ## -------------------------------------------------------------------------------
  [WARNING]: provided hosts list is empty, only localhost is available. Note that
  the implicit localhost does not match 'all'
  ```

---

## 10. `inventory` invocation

- Fill in the inventory based upon the previous labs' configuration and test it.
- Verify that the inventory is defined correctly with:
  ```sh
  ansible-inventory -i <inventory_file> --graph
  ```
- Test the inventory file with
  ```sh
  ansible -i <inventory_file> -m ping
  ```
-     ??? success "Suggested Solution"
        ```ini
        ###
        ### List of servers which we want ansible to connect to
        ### The names are defined in the docker-compose
        ###

        [servers]
          linux-server-1 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'
          linux-server-2 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'
          linux-server-3 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'

        ```

  ***

## 11. More Hands-on Exercises

- Create an inventory file with two groups: `webservers` and `databases`, with at least 2 hosts each.

  ??? success "Solution"
  ```ini
  [webservers]
  web1.example.com
  web2.example.com

      [databases]
      db1.example.com
      db2.example.com
      ```

- Add host variables to set different SSH ports for each host in your inventory.

  ??? success "Solution"
  ```ini
  [webservers]
  web1.example.com ansible_port=2222
  web2.example.com ansible_port=2223

      [databases]
      db1.example.com ansible_port=2224
      db2.example.com ansible_port=2225
      ```

- Create an inventory with group variables that set `ansible_user=admin` for all webservers.

  ??? success "Solution"
  ```ini
  [webservers]
  web1.example.com
  web2.example.com

      [webservers:vars]
      ansible_user=admin
      ```

- Create a nested group structure where `production` contains both `web_prod` and `db_prod` groups.

  ??? success "Solution"
  ```ini
  [web_prod]
  web-prod-1.example.com
  web-prod-2.example.com

      [db_prod]
      db-prod-1.example.com

      [production:children]
      web_prod
      db_prod
      ```

- Use `ansible-inventory` command to list all hosts in a specific group.

  ??? success "Solution"
  ```sh # List all hosts in webservers group
  ansible-inventory -i inventory --list --limit webservers

      # Show graph view
      ansible-inventory -i inventory --graph webservers
      ```

- Create a YAML format inventory with the same structure as your INI inventory.

  ??? success "Solution"
  `yaml
    all:
      children:
        webservers:
          hosts:
            web1.example.com:
              ansible_port: 2222
            web2.example.com:
              ansible_port: 2223
          vars:
            ansible_user: admin
        databases:
          hosts:
            db1.example.com:
              ansible_port: 5432
    `

- Test your inventory by pinging only hosts in the `webservers` group.

  ??? success "Solution"
  `sh
    ansible webservers -i inventory -m ping
    `

---

## 12. Summary

- `Inventory` is the foundation of Ansible automation - it defines what hosts to manage
- Supports multiple formats: `INI`, `YAML`, and `JSON`
- Can be `static` (text files) or `dynamic` (generated by scripts)
- Use `groups` to organize hosts logically by role, environment, or location
- `Variables` can be set at host or group level for flexibility
- Special groups `all` and `ungrouped` are automatically created
- Use `ansible-inventory` command to validate and inspect inventory
- Follow `best practices`: version control, nested groups, and Ansible Vault for secrets
- Dynamic inventory is essential for cloud and large-scale environments
