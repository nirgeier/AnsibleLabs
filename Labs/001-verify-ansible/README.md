![](../../resources/ansible_logo.png)

<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/001-verify-ansible.yaml"><img src="https://img.shields.io/github/actions/workflow/status/nirgeier/AnsibleLabs/001-verify-ansible.yaml?branch=main&style=flat" style="height: 20px;"></a> ![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier) [![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/) [![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com) [![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

# Lab 001 - Verify ansible configuration

- In this lab we will create the ansible configuration and will verify that the configuration is correct
- This lab is based upon the previous lab and its `docker-compose`

- For this demo we will create 3 files
  - `ansible.cfg`
  - `inventory`
  - `ssh.config`

### Pre-requirements

> [!NOTE]
> We need to have our container running before we start this lab
> ```sh
> # Verify that the container are running as expected (with ansible and certificates)
> 001-init-servers.sh
> ```


- [Lab 001 - Verify ansible configuration](#lab-001---verify-ansible-configuration)
    - [Pre-requirements](#pre-requirements)
    - [01. Create the configuration file](#01-create-the-configuration-file)
    - [01.01. Create the `ansible.cfg` file](#0101-create-the-ansiblecfg-file)
    - [01.02. Create the `ssh.config` file](#0102-create-the-sshconfig-file)
    - [01.03. Create the `inventory` file](#0103-create-the-inventory-file)
    - [01.04. Prepare the content for execution](#0104-prepare-the-content-for-execution)
  - [02 Test ansible configuration](#02-test-ansible-configuration)
    - [02.01. Check ansible configuration](#0201-check-ansible-configuration)
    - [02.02. Basic ansible configuration](#0202-basic-ansible-configuration)



### 01. Create the configuration file

> [!IMPORTANT]  
> In this lab we will be placing the files under the `/labs-scripts` folder.  
> The folder is mounted to our docker container under `<PROJECT_ROOT>/runtime` folder.
> You're encouraged to review  the `docker-compose.yaml` file throughout the lab session. 


### 01.01. Create the `ansible.cfg` file

- `ansible.cfg` contains the configuration for our ansible project and to control Ansible’s behavior.
- `ansible.cfg` uses the `INI` format.

* **File Locations**: 

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



- **Auto Generate**: 
  - You can execute `ansible-config init` will generate a sample ansible configuration file 
  - This is the content of `ansible.cfg` which we will use in this lab
  
    ```ini
    ### $RUNTIME_FOLDER/labs-scripts/ansible.cfg
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
                    -o UserKnownHostsFile=/root/.ssh/known_hosts
    ```

### 01.02. Create the `ssh.config` file

- In Linux Ansible is based upon `ssh`, so in order to run Ansible playbooks.
- By default it will use the default ssh keys unless we supply it with ssh configuration file.
- In this demo we will use use our own `ssh.config`

    ```sh
    ### $RUNTIME_FOLDER/labs-scripts/ssh.config
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
        IdentityFile    /root/.ssh/linux-server-1
        User            root
        Port            22

    Host                linux-server-2
        HostName        linux-server-2
        IdentityFile    /root/.ssh/linux-server-2
        User            root
        Port            22

    Host                linux-server-3
        HostName        linux-server-3
        IdentityFile    /root/.ssh/linux-server-3
        User            root
        Port            22
    ```

### 01.03. Create the `inventory` file

- Docs: [How to build your inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).
- An Ansible inventory file is a `configuration file` that lists and categorizes the hosts Ansible will manage. 
- It provides a structured way to define `hosts` and `groups`, enabling efficient targeting and execution of tasks on specific hosts or groups of hosts.

- The simplest inventory is a **single file** with a list of `hosts` and `groups`. 
- The default location for this file is `/etc/ansible/hosts`. 
- You can specify a different inventory file at the command line using the `-i <path>` when executing ansible commands.
- This inventory is written in the form of an `ini` file. 
- It also can be written in other formats such as `YAML` and `Dynamic Inventory` which dynamically configure the inventory with scripts. 

- The inventory configuration we will use for the labs:
    ```ini
    ### $RUNTIME_FOLDER/labs-scripts/inventory
    ###
    ### List of servers which we want ansible to connect to
    ### The names are defined in the docker-compose
    ###

    [servers]
    linux-server-1 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'
    linux-server-2 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'
    linux-server-3 ansible_ssh_common_args='-o UserKnownHostsFile=/root/.ssh/known_hosts'

    [all:vars]
    # Extra "global" variables for the inventory
    ```

This inventory file is described by the following rules.

- Information is described by one node per line, such as `linux-server-xx`.
  - A node line consists of `identifier of the node (linux-server-X)` and `host variable(s) to be given to the node (ansible_host=xxxx)`.
  - You can also specify an IP address or FQDN for the `linux-server-xx` part.
- You can create a group of hosts with `[web]`. Here, a group named `web` will be created.
  - You can use any group name except `all` and `localhost`.
    - e.g. `[webservers]`, `[databases]` can be used to **group** the servers
- In `[all:vars]`, `group variables` are defined for the group `all`.
  - When we user **group** we can use the whole group as "hosts" for ansible 
  - `all` is a special group, a group that points to all nodes described in the inventory.
- A [magic variable](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html) represented by `ansible_xxxx`, which contains special values that control Ansible's behavior and environment information that Ansible will automatically retrieve.  Details are explained in the variables section.

### 01.04. Prepare the content for execution

- Place the files under the shared folder
- Verify that the controller can execute ansible

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
    ansible [core 2.16.5]
    config file = /labs-scripts/ansible.cfg
    configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
    ansible python module location = /usr/lib/python3/dist-packages/ansible
    ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
    executable location = /usr/bin/ansible
    python version = 3.10.12 (main, Nov 20 2023, 15:14:05) [GCC 11.4.0] (/usr/bin/python3)
    jinja version = 3.0.3
    libyaml = True
  ```  
- We are looking for the following line:
    ```text
    config file = /labs-scripts/ansible.cfg
    ```

### 02.02. Basic ansible configuration

- Once all is ready lets check is teh controller can connect to the servers with the using `ping`
- `ping ` is an `Ad-Hoc` ansible command, we will cover it in the following section
    
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