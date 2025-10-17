* There are several ways to run the Ansible Labs. 
* Choose the method that works best for you.
    * ![](../assets/images/killercoda-icon.png){:.width-24px} Killercoda  (Recommended)
    * 🐳 Docker
    * 📜 From Source
    * ![](../assets/images/gcp.png){:.width-24px} Using Google Cloud Shell


=== "![](../assets/images/killercoda-icon.png){:. width-24px} Killercoda  (Recommended)"

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

=== "![](../assets/images/gcp.png){:.width-24px} Using Google Cloud Shell"
  
    - Google Cloud Shell provides a free, browser-based environment with all necessary tools pre-installed.
    - Click on the `Open in Google Cloud Shell` button below:

      [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/AnsibleLabs)

    - The repository will automatically be cloned into a free Cloud instance.
    - Use **<kbd>CTRL</kbd>** + click to open it in a new window.
    - Follow the instructions in the README of each lab.
    
    **Benefits:**

    - No local installation required
    - Pre-configured environment
    - Works on any device with a web browser
    - All tools pre-installed
    - Free tier available

---

!!! explore "Lab Breakdown"
      * If you choose to run the labs locally using Docker or From Source, follow the steps below to set up your environment.
      * Make sure you have the necessary tools installed.
      * Follow the instructions in the README of each lab.
      * Review the Dockerfile(s) and docker-compose.yml for container configurations.

---

## 02. Build From Source

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