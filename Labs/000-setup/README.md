<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)
[![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/)
[![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com)
[![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

<!-- inPage TOC start -->

## Lab Highlights:

- [Lab Highlights:](#lab-highlights)
  - [01. Install Ansible](#01-install-ansible)
  - [01.01. Build the Ansible container \& servers](#0101-build-the-ansible-container--servers)
  - [01.03. Verify the ssh service on our demo servers](#0103-verify-the-ssh-service-on-our-demo-servers)
  - [01.03. Test the ssh connection to the dummy servers](#0103-test-the-ssh-connection-to-the-dummy-servers)

---

<!-- inPage TOC end -->

### 01. Install Ansible

- You can use `Ansible` locally on your system or use the demo Ansible playground inside docker container
- This lab contains the `Ansible controller` & `linux-servers` as playground environment.

### 01.01. Build the Ansible container & servers

- Build the demo containers
- The docker compose will create `ansible-controller` which will server as our controller to execute ansible playbooks on our demo servers defined by the names `linux-server-X`
- Those names will be used later on for our ansible inventory as well

```sh
# Build the Ansible container & the Demo servers
# The `00-setup.sh` will build all we will need for this lab
./00-setup.sh
```

### 01.03. Verify the ssh service on our demo servers

```sh
# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# We mapped the generated certificates and content under 
# Labs/runtime folder so we can use it.
cd $ROOT_FOLDER/runtime

# Check that the servers are up and running
# and that the sshd service is running
docker exec -it linux-server-3 bash service --status-all

### Output: 
###  
###  [ ? ]  hwclock.sh
###  [ - ]  procps
###  [ + ]  ssh
###  [ - ]  x11-common
```

### 01.03. Test the ssh connection to the dummy servers

```sh
# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# We mapped the generated certificates and content under 
# Labs/runtime folder so we can use it.
RUNTIME_FOLDER=$ROOT_FOLDER/runtime

clear

for i in {1..3}
do
    echo -e ""
    echo -e ""
    echo -e "-------------- linux-server-$i -------------- "
    
    # Make sure that the ssh service is running
    docker exec linux-server-$i bash service ssh start

    ssh -i $RUNTIME_FOLDER/.ssh/linux-server-$i                     \
        -p 300$i root@localhost                                     \
        -o StrictHostKeyChecking=accept-new                         \
        -o UserKnownHostsFile=$RUNTIME_FOLDER/.ssh/known_hosts      \
        cat /etc/hosts | grep --color=auto -E "linux-server-$i|$"

done
```

<!-- navigation start -->

---

<div align="center">
  <a href="../01-Scripts">01-Scripts</a>
  &nbsp;:arrow_right:</div>

---

<div align="center">
  <small>&copy;CodeWizard LTD</small>
</div>

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)

<!-- navigation end -->
