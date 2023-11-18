<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier)
[![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/)
[![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com)
[![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

<!-- inPage TOC start -->

---

## Lab Highlights:

- [Lab Highlights:](#lab-highlights)
  - [01. Install Ansible](#01-install-ansible)
  - [01.01. Build the Ansible container \& servers](#0101-build-the-ansible-container--servers)
  - [01.03. Test the ssh connection to the dummy servers](#0103-test-the-ssh-connection-to-the-dummy-servers)
  - [01.04. Run the Ansible container](#0104-run-the-ansible-container)
  - [01.05. Test without `-c local`](#0105-test-without--c-local)

---

<!-- inPage TOC end -->

### 01. Install Ansible

- You can use `Ansible` locally on your system or use the demo Ansible playground inside docker container
- This lab contains the `Ansible server` demo servers for the playground.

### 01.01. Build the Ansible container & servers

- Build the demo containers
- The docker compose will create 2 servers for us with the names `demo.server1` & `demo.server2`
- Those names will be used later on for our ansible inventory

```sh
# Build the Ansible container & the Demo servers
docker-compose up -d --build
```

### 01.03. Test the ssh connection to the dummy servers

```sh
# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# We mapped the generated certificates to .ssh folder so we can use it.
cd $ROOT_FOLDER/Labs/runtime

# Remove the previous certificates if any
ssh-keygen -f ".ssh/known_hosts" -R "[localhost]:5004"
ssh-keygen -f ".ssh/known_hosts" -R "[localhost]:5005"

# Add the certificates to the authorized_keys on our ansible container
sudo ssh -i .ssh/id_rsa -p 5004 root@localhost -o StrictHostKeyChecking=accept-new
sudo ssh -i .ssh/id_rsa -p 5005 root@localhost -o StrictHostKeyChecking=accept-new
```

### 01.04. Run the Ansible container

- Now lets test the Ansible container

```sh
# The container will start and will wait for commands
docker run -d --name ansible alpine/ansible

# Run the ansible commands on the ansible Container
docker exec -it ansible ansible all -i 'localhost,' -c local -m ping

#
# Output
#
[WARNING]: Platform linux on host localhost is using the discovered Python interpreter at /usr/bin/python,
but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```

### 01.05. Test without `-c local`

```sh
# The same Ansible ping will fail, if run it without the -c local flag:
docker exec -it ansible ansible all -i 'localhost,' -m ping
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
