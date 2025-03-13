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

# Lab 001 - Verify ansible configuration

- In this lab we will create the ansible configuration and will verify that the configuration is correct
- This lab is based upon the [previous lab](../000-setup) and its `docker-compose`
- In this lab we will learn to use:
  - `ansible.cfg`
  - `inventory`
  - `ssh.config`

---

### Pre-Requirements

Clone the repository and start playing with it

**Option 1:** 
  - Linux machine with docker

**Option 2:** 

  [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/AnsibleLabs)
  
  - Clicking on the `Open in Google Cloud Shell` button.
  - It will clone the repository into free Cloud instance
  - **<kbd>CTRL</kbd> + click to open in new window** 

**Option 3:** 
  - Open the scenario in [Killercoda](https://killercoda.com/creator/scenarios/codewizard)
  - **<kbd>CTRL</kbd> + click to open in new window** 

---
- [Lab 001 - Verify ansible configuration](#lab-001---verify-ansible-configuration)
    - [Pre-Requirements](#pre-requirements)
    - [01. Create the configuration file](#01-create-the-configuration-file)
    - [01.01. `ansible.cfg` file](#0101-ansiblecfg-file)
    - [01.02. Create the `ansible.cfg` file](#0102-create-the-ansiblecfg-file)
      - [01.02.01 `ansible.cfg` Locations:](#010201-ansiblecfg-locations)
      - [01.02.02 Structure of `ansible.cfg`](#010202-structure-of-ansiblecfg)
      - [01.02.03 Auto Generate `ansible.cfg`](#010203-auto-generate-ansiblecfg)
    - [01.02. Create the `ssh.config` file](#0102-create-the-sshconfig-file)
    - [01.03. Create the `inventory` file](#0103-create-the-inventory-file)
    - [01.04. Prepare the content for execution](#0104-prepare-the-content-for-execution)
  - [02 Test ansible configuration](#02-test-ansible-configuration)
    - [02.01. Check ansible configuration](#0201-check-ansible-configuration)
    - [02.02. Basic ansible configuration](#0202-basic-ansible-configuration)

---


### 01. Create the configuration file

> [!IMPORTANT]  
> In this lab we will be placing the files under the `/labs-scripts` folder.  
> The folder is **mounted** to our docker container(s) under `<PROJECT_ROOT>/runtime` folder.  
> You're encouraged to review  the [`docker-compose.yaml`](../000-setup/docker-compose.yaml) file throughout the lab session. 


### 01.01. `ansible.cfg` file
- What is `ansible.cfg` ?
    - The `ansible.cfg` file is an INI-like configuration file used to define various settings and parameters that influence how Ansible operates. 
  
### 01.02. Create the `ansible.cfg` file

- `ansible.cfg` contains the configuration for our ansible project and to control Ansible’s behavior.
- `ansible.cfg` uses the `INI` format.

#### 01.02.01 `ansible.cfg` Locations: 

  - Docs: [Ansible Configuration Settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file)
  - Ansible searches `ansible.cfg` in a specific order. 
  - Ansible will **search** for the configuration file in the following order: 
    the **first file** it finds will be used while ignoring the rest
    | Search resource            | Description                 |
    | -------------------------- | --------------------------- |
    | `ANSIBLE_CONFIG`           | environment variable if set |
    | `ansible.cfg`              | In the current directory    |
    | `~/.ansible.cfg`           | Under the home directory    |
    | `/etc/ansible/ansible.cfg` | OS common path              |
- In this exercise the environment variable `ANSIBLE_CONFIG` is set in the docker container `/labs-scripts/.ansible.cfg` 

#### 01.02.02 Structure of `ansible.cfg`
- The `ansible.cfg` file is **divided into sections**, each containing various parameters that can be customized. 
  
- Main configuration settings:
    ##### `[defaults]`
    - The `[defaults]` section contains the general settings for Ansible, such as inventory location, verbosity, and log settings.

        ```ini
        [defaults]
            ask_pass            = false
            host_key_checking   = false
            inventory           = /etc/ansible/hosts
            log_path            = /var/log/ansible.log
            remote_user         = ansible
            timeout             = 30
        ```  

    ##### `[privilege_escalation]`
    - The `[privilege_escalation]` section defines settings related to privilege escalation, such as using **`sudo`** or **`become`**.

        ```ini
        [privilege_escalation]
            become          = True
            become_method   = sudo
            become_user     = root
            become_ask_pass = False
        ```  

    ##### `[ssh_connection]`
    - Settings for SSH connections, including timeout and control settings for persistent connections.

        ```ini
        [ssh_connection]
            ssh_args    = -o ControlMaster=auto -o ControlPersist=60s
            pipelining  = True
            scp_if_ssh  = True
        ```  

    ##### `[inventory]`
    - **`[inventory]`** Defines options related to inventory parsing and caching.

        ```ini
        [inventory]
            enable_plugins = host_list, ini, auto
            cache = True
            cache_plugin = memory
            cache_timeout = 3600
        ```  

    ##### `[diff]`
    - Controls whether Ansible shows differences when applying configurations.

        ```ini
        [diff]
            always = True
            context = 5
        ```

    ##### `logging`
    - Ansible does not have a dedicated `[logging]` section in ansible.cfg. 
    - Instead, logging is typically configured under the `[defaults]` section using the log_path directive.
    - **`log_path`** Controls where Ansible logs its output. 
      - If log_path is set, Ansible writes logs to the specified file. 
      - If it is not set or is empty, logging is disabled.
        
        ```ini
        [defaults]
            log_path = /var/log/ansible.log
        ```
#### 01.02.03 Auto Generate `ansible.cfg` 

  - You can execute `ansible-config init` will generate a sample ansible configuration file 
  - This is the content of `ansible.cfg` which we will use in this lab
  
    ```ini
    ### File Location: $RUNTIME_FOLDER/labs-scripts/ansible.cfg
    ##
    ## This is the main configuration file for our demo application
    ##

    # This is the default location of the inventory file, script, or directory
    # that Ansible will use to determine what hosts it has available to talk to
    [defaults]

    # Define that inventory info is in the file named “inventory”
    inventory = inventory

    # Specify remote hosts, so we do not need to config them in main ssh config
    [ssh_connection]
    transport = ssh
    transfer_method = scp

    # The location of the ssh config file
    # We will create this file in our next step
    ssh_args  =     -F ssh.config                   \
                    -o ControlMaster=auto           \
                    -o ControlPersist=60s           \
                    -o StrictHostKeyChecking=no     \
                    -o UserKnownHostsFile=../.ssh/known_hosts
    ```

### 01.02. Create the `ssh.config` file

- In Linux Ansible is based upon `ssh`, in order to run Ansible playbooks.
- By default it will use the default ssh keys unless we supply it with ssh configuration file.
- In this demo we will use our own `ssh.config` configuration file.
    
    ```sh
    ### File location: $RUNTIME_FOLDER/labs-scripts/ssh.config
    # Set up the desired hosts
    # keep in mind that we have set up the hosts in the docker-compose
    Host *
        # Disable host key checking: 
        # avoid asking for the key-print authenticity
        StrictHostKeyChecking no
        
        UserKnownHostsFile    /dev/null
        
        # Enable hashing known_host file
        HashKnownHosts        yes
        
        # IdentityFile allows to specify private keys we wish to use for authentication
        # Authentication = the process of Authentication
        # We will use the auto-generated ssh keys from our Docker container

    # List the desired servers. 
    # the hosts are defined in the docker-compose which we created in the setup lab)
    Host                linux-server-1
        HostName        linux-server-1
        IdentityFile    ../.ssh/linux-server-1
        User            root
        Port            22

    Host                linux-server-2
        HostName        linux-server-2
        IdentityFile    ../.ssh/linux-server-2
        User            root
        Port            22

    Host                linux-server-3
        HostName        linux-server-3
        IdentityFile    ../.ssh/linux-server-3
        User            root
        Port            22
    ```

### 01.03. Create the `inventory` file

- Docs: [How to build your inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).
- An Ansible inventory file is a `configuration file` that **lists and categorizes** the hosts Ansible will **manage**. 
- It provides a structured way to define `hosts` and `groups`, enabling efficient targeting and execution of tasks on specific hosts or groups of hosts.
- The simplest inventory is a **single file** with a list of `hosts` and `groups`.
- This inventory is written in the `ini` format.
- `inventory` can be written in other formats as well, such as `YAML` and `Dynamic Inventory` which dynamically configure the inventory with scripts. 
- The default location for this file is `/etc/ansible/hosts`.
- If `/etc/ansible/hosts` doesn't exists, ansible will look for user specific inventory file at `$HOME/.ansible/hosts`
- You can specify a different inventory file at the command line using the `-i <path>` when executing ansible commands or by exporting the `ANSIBLE_INVENTORY` environment variable.
- Using `-i <path>` takes precedence over environment variable.

- The inventory configuration we will use for the labs:
    ```ini
    ### File location: $RUNTIME_FOLDER/labs-scripts/inventory
    ###
    ### List of servers which we want ansible to connect to
    ### The names are defined in the docker-compose
    ###

    [servers]
    linux-server-1 ansible_ssh_common_args='-o UserKnownHostsFile=../.ssh/known_hosts'
    linux-server-2 ansible_ssh_common_args='-o UserKnownHostsFile=../.ssh/known_hosts'
    linux-server-3 ansible_ssh_common_args='-o UserKnownHostsFile=../.ssh/known_hosts'

    [all:vars]
    # Extra "global" variables for the inventory
    ```

**This inventory file is written by the following rules:**

- Information is described by **one node per line**, such as `linux-server-xx`.
  - A node line consists of `identifier of the node (ex. linux-server-X)` and `host variable(s) (ex. ansible_host=xxxx)` to be given to the node .
  - You can also specify an IP address or FQDN for the `linux-server-xx` part.
- You can create a group of hosts with `[group_name]`. In our inventory the group name is `[servers]`.
  - You can use any group name except `all` and `localhost`.
    - e.g. `[webservers]`, `[databases]` can be used to **group** the servers

**`[all]`**
- `all` is a special group, a group that points to all nodes described in the inventory.
- The `[all:vars]` & `group variables` are defined for the group `all`.
  - When we use **group** we can use the whole group as "hosts" for ansible 
- A [magic variable](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html) represented by `ansible_xxxx`, 
  which contains special values that control Ansible's behavior and environment information that Ansible will automatically retrieve.  
  Details are explained in the variables section.

### 01.04. Prepare the content for execution

- Place the files under the shared folder os simply execute the script [/Labs/000-setup/02-init-ansible.sh](Labs/000-setup/02-init-ansible.sh)
- Verify that the controller can execute ansible [/Labs/000-setup/01-init-servers.sh](Labs/000-setup/01-init-servers.sh)

---

## 02 Test ansible configuration

- Now we are ready to start play with ansible 

### 02.01. Check ansible configuration

- The first step is to test ansible configuration
    ```sh
    # Verify that ansible is installed correctly
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

- Once all is ready lets check is the controller can connect to the servers with the ansible `ping` command
- `ping` is an `Ad-Hoc` ansible command, we will cover it later on.
    
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

<p style="text-align: center;">
  <a href="/Labs/000-setup">
  :arrow_backward: 000-setup
  </a>
  &emsp;
  <a href="/Labs">
  Back to labs list
  </a>    
  &emsp;
  <a href="/Labs/002-no-inventory">
  002-no-inventory :arrow_forward:
  </a>
</p>