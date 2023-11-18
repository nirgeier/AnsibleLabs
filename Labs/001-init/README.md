<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)
[![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/)
[![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com)
[![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

## Our First Ansible app

- In this lab we will create our first ansible application
- This lab is based upon the previous lab and its `docker-compose`

### Create the app skeleton

- For this demo we will create 3 files
  - ansible.cfg
  - inventory
  - ssh.config

### 01. Create the configuration file

- `ansible.cfg` will contain the configuration for our ansible project

```sh
#
# This is the main configuration file for our demo application
#

# This is the default location of the inventory file, script, or directory
# that Ansible will use to determine what hosts it has available to talk to
[defaults]

# Define that inventory info is in the file named “inventory”
inventory = inventory

# Specify remote hosts, so we do not need to config them in main ssh config
[ssh_connection]
transport = ssh

# The location of the ssh config file
ssh_args  = -F ssh.config
```

### 02. Create the `ssh.config` file

- When we run Ansible playbooks it will use the default ssh keys unless we supply it with ssh configuration file.
- in this demo we will use the `ssh.config`

```sh
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

# list the desired servers. (the hosts are defined in the docker-compose)
Host  demo.server1
    HostName demo.server1
    IdentityFile          /root/.ssh/demo.server1
    User root
    Port 22

Host  demo.server2
    HostName demo.server2
    IdentityFile          /root/.ssh/demo.server1
    User root
    Port 22
```

### 03. Create the inventory file

```sh
#
# List of servers which we want ansible to connect to
# The names are defined in the docker-compose
#
[servers]
demo.server1
demo.server2
```

### 04. Place the files for the Ansible container

- In this demo we will be placing the files under the `/opt/sources` folder

### 02. Demo Scripts

### 02.01. check version

```sh
./01-version.sh
```

### 02.02. check servers

```sh
./02-check-servers.sh
```

### 02.03. Run playbook

```sh
./02-check-servers.sh
```
