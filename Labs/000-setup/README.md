<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/000-setup.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/000-setup.yaml/badge.svg" alt="Build Status">
</a>

---

# Lab 000 - Setup

- In this lab we will define and build our docker containers which we will be using for the next of labs.
- The lab is based upon ansible controller & 3 linux servers all are docker containers.

---

### Usage


* There are several ways to run the Ansible Labs. 
* Choose the method that works best for you.
    * ![](../assets/images/killercoda-icon.png){:. height-16px} Killercoda  (Recommended)
    * 🐳 Docker
    * 📜 From Source


=== "![](../assets/images/killercoda-icon.png){:. height-16px} Killercoda  (Recommended)"

    * The easiest way to get started with the labs
    * Learn Ansible in your browser without any local installation

    🌐 <a href="https://killercoda.com/codewizard/scenario/Ansible" target="_blank">**Launch on Killercoda**</a>

      **Benefits:**

      - No installation required
      - Pre-configured environment
      - Works on any device with a web browser
      - All tools pre-installed
       
=== "🐳 Docker"

    Using Docker is the easiest way to get started locally with the labs:

    ```bash
    # Change to the Labs directory
    cd Labs/000-setup

    # Run the setup lab using Docker Compose
    docker-compose up -d
    ```

    **Prerequisites:**

    - Docker and Docker Compose installed on your system
    - No additional setup required

=== "📜 From Source"

    For those who prefer to run it directly on their machine:

    ```bash
    # Clone the repository
    git clone https://github.com/nirgeier/AnsibleLabs.git
    # Change to the Labs directory
    cd AnsibleLabs/Labs
    # Start with the setup lab
    cd 000-setup
    # Follow the instructions in the README of each lab
    cat README.md
    ```
    **Prerequisites:**

    - Ansible installed on your system
    - A Unix-like operating system (Linux, macOS, or Windows with WSL)
    - Basic command-line tools

---

!!! explore "Lab Breakdown"
      * If you choose to run the labs locally using Docker or From Source, follow the steps below to set up your environment.
      * Make sure you have the necessary tools installed.
      * Follow the instructions in the README of each lab.
      * Review the Dockerfile(s) and docker-compose.yml for container configurations.

---

### From Source

**Build the Ansible container**

- Clone the git repo: `git clone https://github.com/nirgeier/AnsibleLabs.git`
- Navigate to the Labs directory: `cd AnsibleLabs/Labs/000-setup`
- The lab contains the `docker-compose` file along with the Dockerfile(s)
  The containers are based upon ubuntu and are published to DockerHub as well.
- Build the demo containers
- The docker-compose will create `ansible-controller` which will server as our controller to execute ansible playbooks on our demo servers defined by the names `linux-server-X`

!!! warning "Labs containers"
      
      | Container                | Content                                              |
      |--------------------------|------------------------------------------------------|
      | 🐳  `ansible-controller` | Linux container with ansible installed               |
      | 🐳  `linux-server-1`     | Linux container with ssh only (no ansible installed) |
      | 🐳  `linux-server-2`     | Linux container with ssh only (no ansible installed) |
      | 🐳   `linux-server-3`    | Linux container with ssh only (no ansible installed) |

* For the demo we will also need a shared folder(s) where the certificates and the configuration will be stored
* The shared folder(s) will be mounted into the containers
* The containers will have access to the shared folder(s) for reading and writing files
* The shared folder(s) will be used to store the Ansible playbooks and inventory files
* The shared folder(s) will be mounted at `/labs-scripts` in the containers

---

### Core Concepts

- Create `Ansible Controller` container, which will be used to manage the other containers
- `SSH Keys` - The SSH keys will be generated and mounted into the containers
- Initialize servers: Set up runtime directories, start demo containers via `Docker Compose`, verify `Ansible` installation, extract `SSH keys` from servers, configure known hosts, check SSH services, and test SSH connections to each Linux server

### The setup script(s) 

  ```sh
  # Build the Ansible container & the Demo servers
  # The `_setup.sh` will build all we will need for this lab
  ./_setup.sh
  ```

### Setup Scripts Breakdown

| Script                                    | Content                                                                     |
| ----------------------------------------- | --------------------------------------------------------------------------- |
| 🗞️ `00-build-containers.sh` | 📒 Init the shared folders                                  |
|                                           | 🐳 Build the container(s)                                   |  |
| 🗞️ `01-init-servers.sh`     | ⏯ Initialize the containers                                |
|                                           | 🔐 Extract the ssh certificates                             |
|                                           | ✓ verify that the ssh service is running in the containers |
| 🗞️ `02-init-ansible.sh`     | 🚀 Initialize the ansible files                             |
|                                           | 📚 `ansible.cfg`                                              |
|                                           | 📚 `ssh.config`                                               |
|                                           | 📚 `inventory`                                                |

### Verify Containers

```bash
$ docker ps -a

# Output
IMAGE                       PORTS                                                                  NAMES
---------------------------------------------------------------------------------------------------------------------
nirgeier/ansible-controller 22/tcp                                                                 ansible-controller
nirgeier/linux-server       0.0.0.0:3001->22/tcp, 0.0.0.0:5001->5000/tcp, 0.0.0.0:8081->8080/tcp   linux-server-1
nirgeier/linux-server       0.0.0.0:3002->22/tcp, 0.0.0.0:5002->5000/tcp, 0.0.0.0:8082->8080/tcp   linux-server-2
nirgeier/linux-server       0.0.0.0:3003->22/tcp, 0.0.0.0:5003->5000/tcp, 0.0.0.0:8083->8080/tcp   linux-server-3
```


