<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)
[![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/)
[![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com)
[![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

## Our First Ansible app

- In this lab we will create our first ansible application
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
> 001-check-servers.sh
> ```


- [Our First Ansible app](#our-first-ansible-app)
  - [Pre-requirements](#pre-requirements)
  - [01. Create the configuration file](#01-create-the-configuration-file)
    - [01.01. Create the `ansible.cfg` file](#0101-create-the-ansiblecfg-file)
  - [01.02. Create the `ssh.config` file](#0102-create-the-sshconfig-file)
  - [01.03. Create the `inventory` file](#0103-create-the-inventory-file)
  - [01.04. Prepare the content for execution](#0104-prepare-the-content-for-execution)



### 01. Create the configuration file

> [!IMPORTANT]  
> In this lab we will be placing the files under the `/labs-scripts` folder.  
> The folder is mounted to our docker container under `<PROJECT_ROOT>/runtime` folder


#### 01.01. Create the `ansible.cfg` file

- `ansible.cfg` is a configuration file for Ansible which contains the configuration for our ansible project and to control Ansible’s behavior.

- `ansible.cfg` is an `INI` file.

* **File Locations**: 
  * Ansible will search for the configuration file in the following order ,the **first file** it finds will be used while ignoring the rest

    * `ANSIBLE_CONFIG` - an environment variable if set
    * `ansible.cfg`    - in the current directory
    * `~/.ansible.cfg` - in the home directory
    * `/etc/ansible/ansible.cfg`. 

* **Auto Generate**: 
  * `ansible-config init` will generate a sample ansible configuration file 

* This is the content of `ansible.cfg` which we wil use in this lab
  
```sh
###
### File: $RUNTIME_FOLDER/labs-scripts/ansible.cfg
###

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

# The location of the ssh config file
# We will create this file in our next step
ssh_args  = -F ssh.config
```

### 01.02. Create the `ssh.config` file

- In Linux Ansible is based upon `ssh`, so in order to run Ansible playbooks.
- By default it will use the default ssh keys unless we supply it with ssh configuration file.
- In this demo we will use use our own `ssh.config`

```sh
###
### File: $RUNTIME_FOLDER/labs-scripts/ssh.config
###
# Set up the desired hosts
# keep in mind that we have set up the hosts in the docker-compose
Host *
    #disable host key checking: avoid asking for the key-print authenticity
    StrictHostKeyChecking no
    UserKnownHostsFile    /dev/null
    # Enable hashing known_host file
    HashKnownHosts        yes
    # IdentityFile allows to specify private keys we wish to use for authentication
    # Authentication = the process of Authentication
    # We will need to use the auto-generated ssh keys from our Docker container

# List the desired servers. 
# the hosts are defined in the docker-compose which we created in the setup lab)
Host                linux-server-1
    HostName        linux-server-1
    IdentityFile    /root/.ssh/linux-server-1
    User            root
    Port            3001

Host                linux-server-2
    HostName        linux-server-2
    IdentityFile    /root/.ssh/linux-server-2
    User            root
    Port            3002

Host                linux-server-3
    HostName        linux-server-3
    IdentityFile    /root/.ssh/linux-server-3
    User            root
    Port            3003
```

### 01.03. Create the `inventory` file

* An Ansible inventory file is a `configuration file` that lists and categorizes the hosts Ansible will manage. 
* It provides a structured way to define `hosts` and `groups`, enabling efficient targeting and execution of tasks on specific hosts or groups of hosts.

- The simplest inventory is a **single file** with a list of `hosts` and `groups`. 
- The default location for this file is `/etc/ansible/hosts`. 
- You can specify a different inventory file at the command line using the `-i <path>` when executing ansible commands.

```sh
###
### File: $RUNTIME_FOLDER/labs-scripts/inventory
### 
#
# List of servers which we want ansible to connect to
# The names are defined in the docker-compose
#
[servers]
linux-server-1
linux-server-2
linux-server-3
```

### 01.04. Prepare the content for execution

* Place the files under the shared folder
* Verify that the controller can execute ansible

```sh
# Verify that the ansible is installed and ready
docker exec -it ansible-controller bash
```