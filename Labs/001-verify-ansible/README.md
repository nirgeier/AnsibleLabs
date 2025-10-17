# Lab 001 - Verify Ansible configuration

- In this lab we will create the Ansible configuration and verify that it is configured correctly.
- This lab is based upon the [previous lab](../000-setup) and its `docker-compose`.
- In this lab we will learn how to use:
  - `ansible.cfg`
  - `inventory`
  - `ssh.config`

## Pre-Requirements

Clone the repository and start playing with it.

<br>
-- **Option 1:** 
   
   - Use a Linux machine with Docker.

<br>
-- **Option 2:** 


  
  - Click on the `Open in Google Cloud Shell` button below:

    [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/AnsibleLabs)

  - The repository will automatically be cloned into a free Cloud instance.
  - Use **<kbd>CTRL</kbd>** + click to open it in a new window.

<br>

-- **Option 3:** 

  - Open the scenario in [Killercoda](https://killercoda.com/creator/scenarios/codewizard).
  - Use **<kbd>CTRL</kbd>** + click to open it in a new window.

---
- [Lab 001 - Verify ansible configuration](#lab-001---verify-ansible-configuration)
    - [Pre-Requirements](#pre-requirements)
        - [01.00. Create the configuration file](#01-create-the-configuration-file)
            - [01.01. `ansible.cfg` file](#0101-ansiblecfg-file)
            - [01.02. Create the `ansible.cfg` file](#0102-create-the-ansiblecfg-file)
            - [01.02.01 `ansible.cfg` Locations:](#010201-ansiblecfg-locations)
            - [01.02.02 Structure of `ansible.cfg`](#010202-structure-of-ansiblecfg)
            - [01.02.03 Auto Generate `ansible.cfg`](#010203-auto-generate-ansiblecfg)
            - [01.03. Create the `ssh.config` file](#0102-create-the-sshconfig-file)
            - [01.04. Create the `inventory` file](#0103-create-the-inventory-file)
            - [01.05. Prepare the content for execution](#0104-prepare-the-content-for-execution)
        - [02.00. Test ansible configuration](#02-test-ansible-configuration)
            - [02.01. Check ansible configuration](#0201-check-ansible-configuration)
            - [02.02. Basic ansible configuration](#0202-basic-ansible-configuration)

---

### 01.00. Create configuration files

!!! warning "IMPORTANT!"  
    In this lab we will be placing the files under the `/labs-scripts` directory.  
    The directory is **mounted** to our docker container(s) under the `<PROJECT_ROOT>/runtime` directory.  
    You are encouraged to review  the [`docker-compose.yaml`](../000-setup/docker-compose.yaml) file throughout the lab session. 

---

### 01.01. About `ansible.cfg` file
- What is `ansible.cfg` ?
    - The `ansible.cfg` file is an INI-like configuration file used to define various settings and parameters that influence how Ansible operates. 
  
### 01.02. Create the `ansible.cfg` file

- `ansible.cfg` contains the configuration for our Ansible Project and controls Ansible’s behavior.
- `ansible.cfg` uses the `INI` format.

#### 01.02.01 `ansible.cfg` locations: 

  - See Ansible documentation: [Ansible Configuration Settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file)
  - Ansible searches `ansible.cfg` in a specific order. The **first file** it finds will be used while ignoring the rest.
  - Ansible will **search** for the configuration file in the following order: 
    
    | Search resource            | Description                 |
    | -------------------------- | --------------------------- |
    | `ANSIBLE_CONFIG`           | environment variable if set |
    | `ansible.cfg`              | In the current directory    |
    | `~/.ansible.cfg`           | Under the home directory    |
    | `/etc/ansible/ansible.cfg` | OS common path              |

- In this exercise the environment variable `ANSIBLE_CONFIG` is set in the docker container path `/labs-scripts/.ansible.cfg`

#### 01.02.02 `ansible.cfg` structure:
- The `ansible.cfg` file is **divided into sections**, each containing various customizable parameters.
  
- Main configuration settings:
#### `[defaults]`

- The `[defaults]` section contains the general settings for Ansible (such as inventory location, verbosity and log settings).

```ini
[defaults]
    ask_pass            =    false
    host_key_checking   =    false
    inventory           =    /etc/ansible/hosts
    log_path            =    /var/log/ansible.log
    remote_user         =    ansible
    timeout             =    30
```

<br>

#### `[privilege_escalation]`

- The `[privilege_escalation]` section defines settings related to privilege escalation (such as **`sudo`** or **`become`**).

```ini
[privilege_escalation]
    become              =    True
    become_method       =    sudo
    become_user         =    root
    become_ask_pass     =    False
```  
<br>
#### `[ssh_connection]`
- Settings for SSH connections, including timeout and control settings for persistent connections.

```ini
[ssh_connection]
    ssh_args            =    -o ControlMaster=auto -o ControlPersist=60s
    pipelining          =    True
    scp_if_ssh          =    True
```  
<br>

#### `[inventory]`
- Defines options related to inventory parsing and caching.

```ini
[inventory]
    enable_plugins      =    host_list, ini, auto
    cache               =    True
    cache_plugin        =    memory
    cache_timeout       =    3600
```  
<br>
#### `[diff]`
- Controls whether Ansible shows differences when applying configurations.

```ini
[diff]
    always              =    True
    context             =    5
```

<br>

#### `[logging]`
- Ansible does not have a dedicated `[logging]` section in `ansible.cfg`. 
- Instead, logging is typically configured under the `[defaults]` section using the `log_path` directive.
- `log_path` controls where Ansible logs its output. 
- If `log_path` is set, Ansible will write logs to the specified file, where as if it is not set, or left empty, logging will be disabled.
        
```ini
[defaults]
    log_path            =     /var/log/ansible.log
```
<br>

#### 01.02.03 Auto Generate `ansible.cfg` 

  - You can choose to execute `ansible-config init`, which will generate a sample Ansible configuration file. 
  - As this is the main configuration file for our demo application, it is the content of `ansible.cfg` which we will use in this lab.
  
```ini
# File location: $RUNTIME_FOLDER/labs-scripts/ansible.cfg.
# This is the default location of the inventory file, script, or directory that 
  Ansible will use to determine what hosts it has available to talk to.

[defaults]
---

# Defines that the inventory info is in a file named “inventory”.

inventory = inventory
---

# Specifies remote hosts, so we do not need to config them in main SSH config.

[ssh_connection]
transport = ssh
transfer_method = scp
---

# The location of the SSH config file.
# We will create this file in our next step.

ssh_args  =     -F ssh.config                   \
                -o ControlMaster=auto           \
                -o ControlPersist=60s           \
                -o StrictHostKeyChecking=no     \
                -o UserKnownHostsFile=/root/.ssh/known_hosts
```

### 01.02. Create the `ssh.config` file

- Ansible operates in Linux environments using `SSH` protocol, in order to run Ansible playbooks.
- By default, Ansible uses the default SSH keys, unless provided with an SSH configuration file.
- In this demo we will use our own `ssh.config` configuration file.
    
```sh
# File location: $RUNTIME_FOLDER/labs-scripts/ssh.config
# Set up the desired hosts
# keep in mind that we have set up the hosts in the docker-compose

Host *
---

# Disable host key checking
# Avoid asking for the key-print authenticity

StrictHostKeyChecking no        
UserKnownHostsFile    /dev/null
---

# Enable hashing known_host file
HashKnownHosts        yes
---

# IdentityFile allows to specify private keys we wish to use for authentication
# Authentication = the process of authentication
# We will use the auto-generated SSH keys from our Docker container
---

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
    Port            22
```

### 01.03. Create the `inventory` file

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
##
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
  Details are explained in the [variables section](need to add a link to variables section).

### 01.04. Prepare the content for execution

- Place the files under the shared folder or simply execute the script [/Labs/000-setup/02-init-ansible.sh](Labs/000-setup/02-init-ansible.sh)
- Verify that the controller can execute ansible [/Labs/000-setup/01-init-servers.sh](Labs/000-setup/01-init-servers.sh)




## 02 Test Ansible configuration

- Now we are ready to start play with Ansible!

### 02.01. Check Ansible configuration

- The first step is to test Ansible configuration
    ```sh
    # Verify that Ansible is installed correctly
    docker exec ansible-controller ansible --version
    ```  

- Sample output
```text
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

### 02.02. Basic ansible configuration

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

---
<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
    <a href="/Labs/000-setup">:arrow_backward: /Labs/000-setup</a>
    &emsp;<a href="/Labs">Back to labs list</a>
    &emsp;<a href="/Labs/002-no-inventory">/Labs/002-no-inventory :arrow_forward:</a>
</p>
<!--- Labs Navigation End -->
