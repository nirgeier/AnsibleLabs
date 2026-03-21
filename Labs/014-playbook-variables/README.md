---
# Playbook Variables

* In this lab we explore how to define, pass, and use variables in Ansible playbooks.
* Variables make playbooks reusable across different environments and hosts.
* We will cover inline vars, variable files, `register`, `set_fact`, and Jinja2 filters.

## What will we learn?

- Defining variables inline, in files, and from the command line
- Using `vars_files` to load variable files
- Accessing variables with Jinja2 `{{ variable }}` syntax
- Using `register` to capture task output and `set_fact` to create derived variables

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) to understand how playbooks are structured.

---

## 01. Defining Variables

### In the Playbook (Inline)

```yaml
---
- name: Inline variables example
  hosts: all
  vars:
    app_name: myapp
    app_port: 8080
    app_user: deploy
    app_packages:
      - nginx
      - curl
      - git
    app_config:
      max_connections: 100
      timeout: 30

  tasks:
    - name: Print app name
      ansible.builtin.debug:
        msg: "App: {{ app_name }} running on port {{ app_port }}"

    - name: Access list variable
      ansible.builtin.debug:
        msg: "Packages to install: {{ app_packages | join(', ') }}"

    - name: Access dictionary variable
      ansible.builtin.debug:
        msg: "Max connections: {{ app_config.max_connections }}"
```

### In Separate Variable Files

```yaml
# vars/main.yml
---
app_name: myapp
app_port: 8080
app_user: deploy
db_host: localhost
db_port: 5432
db_name: production_db
```

```yaml
# Reference in playbook
---
- name: Load variables from file
  hosts: all
  vars_files:
    - vars/main.yml
    - vars/secrets.yml # Can load multiple files

  tasks:
    - name: Show app name
      ansible.builtin.debug:
        var: app_name
```

---

## 02. Variable Types and Syntax

```yaml
---
- name: Variable types
  hosts: localhost
  vars:
    # String
    greeting: "Hello, World!"

    # Integer
    max_retries: 3

    # Boolean
    debug_mode: true

    # List
    servers:
      - web1
      - web2
      - web3

    # Dictionary
    database:
      host: localhost
      port: 5432
      name: mydb

    # Multiline string
    config_file: |
      [server]
      host = localhost
      port = 8080

  tasks:
    - name: Use string
      ansible.builtin.debug:
        msg: "{{ greeting }}"

    - name: Use list item
      ansible.builtin.debug:
        msg: "First server: {{ servers[0] }}"

    - name: Use dict value (dot notation)
      ansible.builtin.debug:
        msg: "DB host: {{ database.host }}"

    - name: Use dict value (bracket notation)
      ansible.builtin.debug:
        msg: "DB port: {{ database['port'] }}"
```

---

## 03. Command-Line Variables

```sh
# Pass a single variable
ansible-playbook site.yml -e "env=production"

# Pass multiple variables
ansible-playbook site.yml -e "env=production app_port=443"

# Pass a YAML/JSON string
ansible-playbook site.yml -e '{"env": "production", "app_port": 443}'

# Pass from a file (prefix with @)
ansible-playbook site.yml -e "@vars/production.yml"
```

---

## 04. `register` - Capture Task Output

```yaml
---
- name: Capture command output
  hosts: all

  tasks:
    - name: Get disk usage
      ansible.builtin.command:
        cmd: df -h /
      register: disk_usage

    - name: Show disk usage
      ansible.builtin.debug:
        var: disk_usage.stdout

    - name: Show return code
      ansible.builtin.debug:
        msg: "Return code: {{ disk_usage.rc }}"

    - name: Show all registered data
      ansible.builtin.debug:
        var: disk_usage
```

### Common `register` attributes

| Attribute      | Description                        |
| -------------- | ---------------------------------- |
| `stdout`       | Standard output as a string        |
| `stderr`       | Standard error as a string         |
| `stdout_lines` | Standard output as a list of lines |
| `rc`           | Return code (0 = success)          |
| `changed`      | Whether the task made a change     |
| `failed`       | Whether the task failed            |

---

## 05. `set_fact` - Create Variables During Play

```yaml
---
- name: Create facts dynamically
  hosts: all
  gather_facts: true

  tasks:
    - name: Set a fact based on OS
      ansible.builtin.set_fact:
        package_manager: "{{ 'apt' if ansible_os_family == 'Debian' else 'yum' }}"

    - name: Calculate a derived value
      ansible.builtin.set_fact:
        app_url: "http://{{ ansible_default_ipv4.address }}:{{ app_port | default(80) }}"

    - name: Show derived facts
      ansible.builtin.debug:
        msg:
          - "Package manager: {{ package_manager }}"
          - "App URL: {{ app_url }}"
```

---

## 06. `vars_prompt` - Interactive Variables

```yaml
---
- name: Interactive variable input
  hosts: all
  vars_prompt:
    - name: app_env
      prompt: "Which environment? (dev/staging/prod)"
      default: dev
      private: false

    - name: db_password
      prompt: "Database password"
      private: true # Hides input (like a password field)

  tasks:
    - name: Show environment
      ansible.builtin.debug:
        msg: "Deploying to: {{ app_env }}"
```

---

## 07. Variable Filters

```yaml
---
- name: Variable filters
  hosts: localhost
  vars:
    my_list: [3, 1, 4, 1, 5, 9, 2, 6]
    my_string: "  hello world  "
    my_path: /etc/nginx/nginx.conf

  tasks:
    - name: String filters
      ansible.builtin.debug:
        msg:
          - "Upper: {{ my_string | upper }}"
          - "Trimmed: {{ my_string | trim }}"
          - "Length: {{ my_string | length }}"
          - "Replace: {{ my_string | replace('world', 'ansible') }}"

    - name: List filters
      ansible.builtin.debug:
        msg:
          - "Sorted: {{ my_list | sort }}"
          - "Unique: {{ my_list | unique }}"
          - "Min: {{ my_list | min }}"
          - "Max: {{ my_list | max }}"
          - "Joined: {{ my_list | join(', ') }}"

    - name: Default filter
      ansible.builtin.debug:
        msg: "Port: {{ undefined_var | default(8080) }}"

    - name: Basename filter
      ansible.builtin.debug:
        msg: "Filename: {{ my_path | basename }}"
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 08. Hands-on

1. Create a `vars/` directory inside the controller and write a `vars/lab014.yml` file containing a `greeting` string, a `lab_number` integer, a `packages` list, and a `server_config` dictionary with `port` and `max_connections` keys.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p vars"
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > vars/lab014.yml << 'EOF'
   ---
   greeting: \"Welcome to Ansible Labs!\"
   lab_number: 14
   packages:
     - curl
     - vim
     - git
   server_config:
     port: 8080
     max_connections: 50
     debug: false
   EOF"
   ```

2. Write a playbook `lab014-variables.yml` that loads `vars/lab014.yml` via `vars_files`, prints the greeting, the package list joined by commas, and the server port.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab014-variables.yml << 'EOF'
   ---
   - name: Variables Practice
     hosts: all
     gather_facts: true
     vars_files:
       - vars/lab014.yml
     vars:
       inline_var: \"I was defined inline\"

     tasks:
       - name: Show the greeting
         ansible.builtin.debug:
           msg: \"{{ greeting }}\"

       - name: Show lab number
         ansible.builtin.debug:
           msg: \"Lab {{ lab_number }}\"

       - name: Show package list
         ansible.builtin.debug:
           msg: \"Packages: {{ packages | join(', ') }}\"

       - name: Show server config
         ansible.builtin.debug:
           msg:
             - \"Port: {{ server_config.port }}\"
             - \"Max connections: {{ server_config.max_connections }}\"
   EOF"
   ```

3. Add a task that runs `hostname` and registers the output, then prints it with `debug`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat >> lab014-variables.yml << 'EOF'

       - name: Get hostname
         ansible.builtin.command:
           cmd: hostname
         register: hostname_output

       - name: Show registered hostname
         ansible.builtin.debug:
           msg: \"Hostname: {{ hostname_output.stdout }}\"
   EOF"
   ```

4. Run the playbook, then re-run it overriding `greeting` from the command line.

   ??? success "Solution"

   ```sh
   # Normal run
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab014-variables.yml"

   # Override greeting at runtime
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab014-variables.yml -e \"greeting='Override greeting!'\""
   ```

5. Add a `set_fact` task that builds a `server_url` variable combining `ansible_default_ipv4.address` and `server_config.port`, then print it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat >> lab014-variables.yml << 'EOF'

       - name: Create derived fact
         ansible.builtin.set_fact:
           server_url: \"http://{{ ansible_default_ipv4.address }}:{{ server_config.port }}\"

       - name: Show server URL
         ansible.builtin.debug:
           msg: \"Server URL: {{ server_url }}\"
   EOF"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab014-variables.yml"
   ```

---

## 09. Summary

- Variables can be defined inline (`vars:`), in files (`vars_files:`), or from the command line (`-e`)
- Use `{{ variable }}` Jinja2 syntax to reference variables in any string value
- `register` captures task output; access it with `.stdout`, `.rc`, `.changed`, `.stdout_lines`
- `set_fact` creates new variables mid-play that persist for the rest of the play
- Filters like `| default()`, `| upper`, `| join()` transform variable values inline
- Extra vars (`-e`) always override any other variable definition
