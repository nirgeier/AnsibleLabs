<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-001.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-001.yaml/badge.svg" alt="Build Status">
</a>

---

# Lab 001 - Verify Ansible configuration

- In this lab we will create the Ansible configuration and verify that it is configured correctly.
- This lab is based upon the [previous lab](../000-setup) and its `docker-compose`.
- In this lab we will learn how to use:
    - `ansible.cfg`
    - `inventory`
    - `ssh.config`

## Pre-Requirements

- Complete the [previous lab](../000-setup#usage) in order to have the `Ansible` controller and the `Linux` servers up and running.

---

## 01. Create configuration files

!!! warning "IMPORTANT!"  
    
    - In this lab we will be placing the files under the `/labs-scripts` directory.  
    - The directory is **mounted** to our docker container(s) under the `<PROJECT_ROOT>/runtime` directory.  
    - You are encouraged to review  the [`docker-compose.yaml`](../000-setup/docker-compose.yaml) file throughout the lab session. 

---

## 02. About `ansible.cfg` file
- What is `ansible.cfg` ?
    - The `ansible.cfg` file is an INI-like configuration file used to define various settings and parameters that influence how Ansible operates. 
    - It allows users to customize Ansible's behavior, such as specifying inventory locations, default module settings, connection options, and more.
    - The `ansible.cfg` file can be placed in several locations, and Ansible will search for it in a specific order.
    - The configuration file is divided into sections, each containing various customizable parameters that control different aspects of Ansible's functionality.
    - Below we will create the `ansible.cfg` file, the `ssh.config` file and the `inventory` file.

---

## 03. `ansible.cfg` locations: 

  - Reference: [Official Ansible documentation: - Ansible Configuration Settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file)
  - Ansible searches `ansible.cfg` in a specific order. 
  - The **first file** it finds will be used while ignoring the rest.
  - Ansible will **search** for the configuration file in the following order: 
    
    | Search resource            | Description                 |
    | -------------------------- | --------------------------- |
    | `ANSIBLE_CONFIG`           | environment variable if set |
    | `ansible.cfg`              | In the current directory    |
    | `~/.ansible.cfg`           | Under the home directory    |
    | `/etc/ansible/ansible.cfg` | OS common path              |

- In this exercise the environment variable `ANSIBLE_CONFIG` is set in the docker container path `/labs-scripts/.ansible.cfg`

---

## 04. `ansible.cfg` structure:
- The `ansible.cfg` file is **divided into sections**, each containing various customizable parameters.
  
- Main `ansible.cfg` settings:

| Setting | Description | Ansible Docs |
|---------|-------------|----------------------|
| [callback_plugins] | Specifies directories for callback plugins that customize output or trigger actions. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#callback-plugins) |
| [connection] | Defines general connection settings that apply to all connection types. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#connection) |
| [defaults] | Contains general settings for Ansible such as inventory location, verbosity, and log settings. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#defaults) |
| [diff] | Controls whether Ansible shows differences when applying configurations. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#diff) |
| [galaxy] | Configures settings for Ansible Galaxy, a hub for sharing roles and collections. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#galaxy) |
| [inventory] | Defines options related to inventory parsing and caching. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#inventory) |
| [logging] | Logging configuration, typically under [defaults] section using log_path. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#defaults) |
| [paramiko_connection] | Configures settings specific to the Paramiko SSH library. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#paramiko-connection) |
| [privilege_escalation] | Defines settings related to privilege escalation, such as sudo or become. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#privilege-escalation) |
| [ssh_connection] | Settings for SSH connections, (timeout, control settings etc). | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ssh-connection) |
| [winrm] | Configures settings for Windows Remote Management (WinRM) connections. | [Docs](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#winrm) |

---

### `[callback_plugins]`

- The `[callback_plugins]` section specifies directories where Ansible looks for callback plugins, which can customize output or trigger actions based on playbook events.
    ```ini
    [callback_plugins]
        stdout_callback     =    yaml
        callback_whitelist  =    timer, profile_tasks
    ```

### `[connection]`

- The `[connection]` section defines general connection settings that apply to all connection types.
    ```ini
    [connection]
        pipelining          =    True
        control_path_dir    =    ~/.ansible/cp
    ```

### `[defaults]`

- The `[defaults]` section contains the general settings for Ansible (such as inventory location, verbosity and log settings).
- It is the most commonly used section and is often the first place users look to customize their Ansible environment.
- Here are some commonly used settings in the `[defaults]` section:

    - `ask_pass` - If set to true, Ansible will prompt for the SSH password.
    - `host_key_checking` - If set to false, Ansible will not check SSH host keys.
    - `inventory` - Specifies the path to the inventory file.
    - `log_path` - Specifies the path to the log file.
    - `remote_user` - Specifies the default remote user for SSH connections.
    - `timeout` - Specifies the timeout for SSH connections in seconds.
    - `private_key_file` - Specifies the path to the private key file for SSH authentication.
    - `become` - If set to true, privilege escalation (e.g., sudo) will be used.
    - `become_method` - Specifies the method to use for privilege escalation (e.g., sudo, su).
    - `become_user` - Specifies the user to become when using privilege escalation.
    - `retry_files_enabled` - If set to false, Ansible will not create retry files.
    - `gathering` - Specifies how facts are gathered (e.g., smart, explicit, none).
    
    ```ini
    [defaults]
        ask_pass            =    false
        host_key_checking   =    false
        inventory           =    /etc/ansible/hosts
        log_path            =    /var/log/ansible.log
        remote_user         =    ansible
        timeout             =    30
    ```

### `[diff]`

- Controls whether Ansible shows differences when applying configurations.
- This can be useful for debugging and understanding changes.
    - `always` - Show differences even when the playbook is not run in check mode.
    - `context` - The number of lines of context to show around changes.
    - `ignore` - Do not show differences.
    - `diff` - Show a unified diff of changes.
    - `unified` - Show a unified diff of changes with context lines.

    ```ini
    [diff]
        always              =    True
        context             =    5
    ```

### `[galaxy]`

- The `[galaxy]` section configures settings for Ansible Galaxy, which is a hub for sharing and downloading Ansible roles and collections.
- This section can be used to specify custom Galaxy servers, caching options, and other related settings.
- Here is an example configuration for the `[galaxy]` section:
    - `server_list` - Specifies the list of Galaxy servers to use.
    - `cache_dir` - Specifies the directory to cache downloaded roles and collections.
    - `role_file` - Specifies the path to the file containing role definitions.
    - `collection_file` - Specifies the path to the file containing collection definitions.
    - `requirements_file` - Specifies the path to the file containing Galaxy requirements.
    - `role_file` - Specifies the path to the file containing role definitions.
  
    ```ini
    [galaxy]
        server_list         =    release_galaxy
        cache_dir           =    ~/.ansible/galaxy_cache
    ```

### `[inventory]`

- Defines options related to inventory parsing and caching.
- Inventory is a critical component of Ansible, as it defines the hosts and groups of hosts that Ansible will manage.
- The inventory can be specified in various formats, including `INI` files, `YAML` files, and dynamic inventory scripts.
- The inventory can also be cached to improve performance.
- Here are some commonly used settings in the `[inventory]` section:
    - `enable_plugins` - Specifies the inventory plugins to use.
    - `cache` - If set to true, inventory caching will be enabled.
    - `cache_plugin` - Specifies the inventory cache plugin to use.
    - `cache_timeout` - Specifies the timeout for inventory caching in seconds.
    - `inventory_ignore_extensions` - Specifies file extensions to ignore when loading inventory files.
    - `inventory_loader` - Specifies the inventory loader to use.
    - `strict` - If set to true, Ansible will enforce strict inventory parsing.
    - `host_key_checking` - If set to true, Ansible will check SSH host keys for inventory hosts.
    - `enable_inventory_cache` - If set to true, inventory caching will be enabled.
    - `inventory_cache_timeout` - Specifies the timeout for inventory caching in seconds.
    - `inventory_cache_connection` - Specifies the connection string for the inventory cache plugin.
    
    ```ini
    [inventory]
        enable_plugins      =    host_list, ini, auto
        cache               =    True
        cache_plugin        =    memory
        cache_timeout       =    3600
    ```  

### `[logging]`

- Ansible does not have a dedicated `[logging]` section in `ansible.cfg`. 
- Instead, logging is typically configured under the `[defaults]` section using the `log_path` directive.
- `log_path` controls where Ansible logs its output. 
- If `log_path` is set, Ansible will write logs to the specified file, where as if it is not set, or left empty, logging will be disabled.
- Here is an example of how to configure logging in the `[defaults]` section:
    ```ini       
    [defaults]
        log_path            =     /var/log/ansible.log
        log_level           =     info
        log_format          =     default
        log_date_format     =     iso8601
        log_ansi            =     True
        log_color           =     auto
        log_file            =     /var/log/ansible.log
        log_rotate          =     True
        log_max_size        =     10485760
        log_compress        =     True
        log_backup_count    =     5
        log_http            =     False
        log_json            =     True
    ```

### `[paramiko_connection]`

- The `[paramiko_connection]` section configures settings specific to the Paramiko SSH library, an alternative to OpenSSH for SSH connections.
- Here are some commonly used settings in the `[paramiko_connection]` section:
    - `pty` - If set to true, a pseudo-terminal will be allocated for the connection.
    - `look_for_keys` - If set to true, Paramiko will look for SSH keys
    - `banner_timeout` - Specifies the timeout for receiving the SSH banner.
    - `keepalive` - If set to true, keepalive messages will be sent to
    
    ```ini
    [paramiko_connection]
        pty                 =    False
        look_for_keys       =    True
    ```

### `[privilege_escalation]`

- The `[privilege_escalation]` section defines settings related to privilege escalation (such as **`sudo`** or **`become`**).
- The `become` directive is used to enable privilege escalation.
  
- Here are some commonly used settings in the `[privilege_escalation]` section:
    - `become` - If set to true, privilege escalation will be used.
    - `become_method` - Specifies the method to use for privilege escalation (e.g., sudo, su).
    - `become_user` - Specifies the user to become when using privilege escalation.
    - `become_ask_pass` - If set to true, Ansible will prompt for the privilege escalation password.
    - `become_flags` - Specifies any additional flags to pass to the privilege escalation command.
    - `become_exe` - Specifies the path to the privilege escalation executable.
    - `become_pass` - Specifies the password to use for privilege escalation.
  

    ```ini
    [privilege_escalation]
        become              =    True
        become_method       =    sudo
        become_user         =    root
        become_ask_pass     =    False
    ```  

### `[ssh_connection]`

- Settings for SSH connections, (timeout, control settings etc).
- ControlMaster and ControlPersist options are used for SSH multiplexing, allowing multiple SSH sessions to share a single connection.
- `ssh_args` can be used to pass additional options to the SSH command.
- `pipelining` can be enabled to reduce the number of SSH connections.
- `scp_if_ssh` specifies whether to use `SCP` for file transfers when using SSH.
  
    ```ini
    [ssh_connection]
        ssh_args            =    -o ControlMaster=auto -o ControlPersist=60s
        pipelining          =    True
        scp_if_ssh          =    True
    ```  

### `[winrm]`

- The `[winrm]` section configures settings for Windows Remote Management (WinRM) connections, used for managing Windows hosts.
- Here are some commonly used settings in the `[winrm]` section:
    - `transport` - Specifies the transport method to use (e.g., basic, ntlm).
    - `cert_validation` - Controls certificate validation (e.g., ignore, validate).
    - `read_timeout_sec` - Specifies the read timeout for WinRM connections in seconds.
    - `operation_timeout_sec` - Specifies the operation timeout for WinRM connections in seconds.
    - `max_retries` - Specifies the maximum number of retries for WinRM connections.
    - `retry_delay` - Specifies the delay between retries for WinRM connections.
    
    ```ini
    [winrm]
        transport           =    basic
        cert_validation     =    ignore
    ```

---

## 05. Auto Generate `ansible.cfg` 

  - You can choose to execute `ansible-config init`, which will generate a sample Ansible configuration file. 
  - As this is the main configuration file for our demo application, it is the content of `ansible.cfg` which we will use in this lab.
  
    ```ini
    # File location: $RUNTIME_FOLDER/labs-scripts/ansible.cfg.
    # This is the default location of the inventory file, script, or directory that 
    Ansible will use to determine what hosts it has available to talk to.

    # Defines that the inventory info is in a file named “inventory”.
    [defaults]
        inventory = inventory

    # Specifies remote hosts, so we do not need to config them in main SSH config.
    [ssh_connection]
        transport = ssh
        transfer_method = scp
    
        # The location of the SSH config file.
        # We will create this file in our next step.
        ssh_args  = -F ssh.config                   \
                    -o ControlMaster=auto           \
                    -o ControlPersist=60s           \
                    -o StrictHostKeyChecking=no     \
                    -o UserKnownHostsFile=/root/.ssh/known_hosts
    ```

---

## 06. Create the `ssh.config` file

- Ansible operates in Linux environments using `SSH` protocol, in order to run Ansible playbooks.
- By default, Ansible uses the default SSH keys, unless provided with an SSH configuration file.
- Ansible ssh.config file allows you to define custom SSH settings for connecting to remote hosts.
- In this demo we will use our own `ssh.config` configuration file.
    ```ini
    # File location: $RUNTIME_FOLDER/labs-scripts/ssh.config
    # Set up the desired hosts
    # keep in mind that we have set up the hosts in the docker-compose

    Host *

    # Disable host key checking
    # Avoid asking for the key-print authenticity
    StrictHostKeyChecking no        
    UserKnownHostsFile    /dev/null

    # Enable hashing known_host file
    HashKnownHosts        yes

    # IdentityFile allows to specify private keys we wish to use for authentication
    # Authentication = the process of authentication
    # We will use the auto-generated SSH keys from our Docker container

    # List the desired servers
    # The hosts are defined in the docker-compose which we created in the setup lab

    Host                  linux-server-1
        HostName          linux-server-1
        IdentityFile      /root/.ssh/linux-server-1
        User              root
        Port              22

    Host                  linux-server-2
        HostName          linux-server-2
        IdentityFile      /root/.ssh/linux-server-2
        User              root
        Port              22

    Host                  linux-server-3
        HostName          linux-server-3
        IdentityFile      /root/.ssh/linux-server-3
        User              root
        Port              22
    ```

---

## 07. Create the `inventory` file

- See Ansible documentation: [How to build your inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).
- An Ansible inventory file is a `configuration file` that **lists and categorizes** the hosts Ansible will **manage**. 
- It provides a structured way to define `hosts` and `groups`, enabling efficient targeting and execution of tasks on specific hosts or groups of hosts.
- The simplest inventory is a **single file** with a list of `hosts` and `groups`.
- The inventory is written using the `INI` format.
- `inventory` can be written in other formats as well, such as `YAML` and `Dynamic Inventory` which dynamically configure the inventory with scripts. 
- The default location for this file is `/etc/ansible/hosts`.
- If `/etc/ansible/hosts` doesn't exists, ansible will look for user specific inventory file, to be placed at `$HOME/.ansible/hosts`
- You can specify a different inventory file at the command line using the `-i <path>` inventory option when executing Ansible commands or by exporting the `ANSIBLE_INVENTORY` environment variable.
- Using `-i <path>` inventory option takes precedence over environment variable.
- The inventory configuration we will use for the labs:
    ```ini
    # File location: $RUNTIME_FOLDER/labs-scripts/inventory

    # List of servers which we want ansible to connect to
    # The names are defined in the docker-compose

    [servers]
        linux-server-1 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'
        linux-server-2 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'
        linux-server-3 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'

    [all:vars]

    # Extra "global" variables for the inventory
    ```

**This inventory file is written following these rules:**

- Information is described by **one node per line**, such as `linux-server-xx`.
  - A node line consists of an `identifier of the node (ex. linux-server-X)` and a `host variable(s) (ex. ansible_host=xxxx)`, to be given to the node .
  - You can also specify an IP address or FQDN for the `linux-server-xx` part.
- You can create a group of hosts with `[group_name]`. In our inventory the group name is `[servers]`.
  - You can use any group name except `[all]` and `[localhost]` (e.g., `[webservers]` or `[databases]` can be used as **group** names for servers).

    **`[all]`**

    - `all` is a special group that points to all nodes described in the inventory.
    - The `[all:vars]` & `group variables` are defined for the group `all`.
        - When we use a **group**, we can use the whole group as "hosts" for ansible.
    - A [magic variable](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html), represented by `ansible_xxxx`, 
    contains special values that control Ansible's behavior and environment information that Ansible will automatically retrieve.  
    - Details are explained in the [variables section](need to add a link to variables section).

---

## 08. Prepare for execution

- Place the files under the shared folder or simply execute the script [/Labs/000-setup/02-init-ansible.sh](Labs/000-setup/02-init-ansible.sh)
- Verify that the controller can execute ansible [/Labs/000-setup/01-init-servers.sh](Labs/000-setup/01-init-servers.sh)

---




## 09. Test Ansible configuration

- Now we are ready to start play with `Ansible`!

- The first step is to test `Ansible` configuration
    ```sh
    # Verify that Ansible is installed correctly
    docker exec ansible-controller ansible --version
    ```  

- Sample output
    
    ```bash
    ansible [core 2.17.9]
    config file = /labs-scripts/ansible.cfg
    configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
    ansible python module location = /usr/lib/python3/dist-packages/ansible
    ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
    executable location = /usr/bin/ansible
    python version = 3.12.3 (main, Feb  4 2025, 14:48:35) [GCC 13.3.0] (/usr/bin/python3)
    jinja version = 3.1.2
    libyaml = True
    ```

- We are looking for the following line:
    ```sh
    config file = /labs-scripts/ansible.cfg
    ```

---

## 10. Basic ansible configuration

- Once all is ready, lets check if the controller can connect to the servers with the Ansible `ping` command.
- `ping` is an `Ad-Hoc` Ansible command that we will cover later on.
    
    ```sh
    # Ping the servers and check that they are "alive"
    docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"

    ### Output
    * Executing: ansible all -m ping
    linux-server-2 | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3"
        },
        "changed": false,
        "ping": "pong"
    }
    linux-server-1 | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3"
        },
        "changed": false,
        "ping": "pong"
    }
    linux-server-3 | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3"
        },
        "changed": false,
        "ping": "pong"
    }
    ```
