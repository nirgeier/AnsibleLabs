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

# Lab 000 - Setup

- In this lab we will define and build our docker containers which we will be using for the next of labs.
- The lab is based upon ansible controller & 3 linux servers all are docker containers.

--- 

## Lab Highlights: <!-- omit in toc-->

- [Lab 000 - Setup](#lab-000---setup)
  - [Lab Highlights: ](#lab-highlights-)
    - [01. Install Ansible](#01-install-ansible)
  - [02. Build the Ansible container \& servers](#02-build-the-ansible-container--servers)
    - [The setup script(s) in this folder](#the-setup-scripts-in-this-folder)
    - [Verify to see if the container are running](#verify-to-see-if-the-container-are-running)

---

### 01. Install Ansible

- You can use `Ansible` locally on your system or use the [demo Ansible playground](https://killercoda.com/codewizard/scenario/Ansible) based upon docker container(s)
- This lab contains the `Ansible controller` & `linux-servers` as playground environment.

## 02. Build the Ansible container & servers

- Clone the git repo: `git clone https://github.com/nirgeier/AnsibleLabs.git`
- The lab contains the `docker-compose` file along with the Dockerfile(s)
  The containers are based upon ubuntu and are published to DockerHub as well.
- Build the demo containers
- The docker-compose will create `ansible-controller` which will server as our controller to execute ansible playbooks on our demo servers defined by the names `linux-server-X`

> [!NOTE]
> The setup include the following containers:

| Container                             | Content                                              |
| ------------------------------------- | ---------------------------------------------------- |
| :school_satchel: `ansible-controller` | Linux container with ansible installed               |
| :collision: `linux-server-1`          | Linux container with ssh only (no ansible installed) |
| :collision: `linux-server-2`          | Linux container with ssh only (no ansible installed) |
| :collision: `linux-server-3`          | Linux container with ssh only (no ansible installed) |

* For the demo we will also need a shred folder(s) where the certificates and the configuration will be stored

---

> [!TIP]
> 
> * The setup script will build and test the containers  
> * The script check that the `ansible-container` can connect to the servers (SSH).

```sh
# Build the Ansible container & the Demo servers
# The `_setup.sh` will build all we will need for this lab
./_setup.sh
```

### The setup script(s) in this folder

| Script                                    | Content                                                                     |
| ----------------------------------------- | --------------------------------------------------------------------------- |
| :newspaper_roll: `00-build-containers.sh` | :white_check_mark: Init the shared folders                                  |
|                                           | :white_check_mark: Build the container(s)                                   |  |
| :newspaper_roll: `01-init-servers.sh`     | :white_check_mark: Initialize the containers                                |
|                                           | :white_check_mark: Extract the ssh certificates                             |
|                                           | :white_check_mark: verify that the ssh service is running in the containers |
| :newspaper_roll: `02-init-ansible.sh`     | :white_check_mark: Initialize the ansible files                             |
|                                           | :spiral_notepad: `ansible.cfg`                                              |
|                                           | :spiral_notepad: `ssh.config`                                               |
|                                           | :spiral_notepad: `inventory`                                                |

### Verify to see if the container are running

```sh
$ docker ps -a

# Output
IMAGE                       PORTS                                                                  NAMES
---------------------------------------------------------------------------------------------------------------------
nirgeier/ansible-controller 22/tcp                                                                 ansible-controller
nirgeier/linux-server       0.0.0.0:3001->22/tcp, 0.0.0.0:5001->5000/tcp, 0.0.0.0:8081->8080/tcp   linux-server-1
nirgeier/linux-server       0.0.0.0:3002->22/tcp, 0.0.0.0:5002->5000/tcp, 0.0.0.0:8082->8080/tcp   linux-server-2
nirgeier/linux-server       0.0.0.0:3003->22/tcp, 0.0.0.0:5003->5000/tcp, 0.0.0.0:8083->8080/tcp   linux-server-3
```

---
<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
    <a href="">:arrow_backward: </a>
    &emsp;<a href="/Labs">Back to labs list</a>
    &emsp;<a href="/Labs/001-verify-ansible">/Labs/001-verify-ansible :arrow_forward:</a>
</p>
<!--- Labs Navigation End -->
