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

- [Roles](#roles)
    - [What are Ansible roles?](#what-are-ansible-roles)
    - [Ansible roles file structure](#ansible-roles-file-structure)
    - [Building Ansible role](#building-ansible-role)
    - [01. Initialize file structure](#01-initialize-file-structure)
    - [02. Create the role content](#02-create-the-role-content)
      - [02.01. Create the `defaults/main.yml`](#0201-create-the-defaultsmainyml)
      - [02.02. Create the templates](#0202-create-the-templates)
      - [02.03. Create the tasks for the role](#0203-create-the-tasks-for-the-role)

---
<!-- header end -->
# Roles

### What are Ansible roles?

- Roles let you **automatically load** related vars, files, tasks, handlers, and other Ansible artifacts based on a **known file structure**. 
- After you group your content into roles, you can easily reuse them and share them with other users.
- By default, Ansible will look in **each directory** within a role for file names `main`/`main.yml`/`main.yaml`.

### Ansible roles file structure

| Files         | Description                                                                                                                                                                                                                            |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **tasks**     | the main list of tasks that the role executes.                                                                                                                                                                                         |
| **handlers**  | handlers, which may be used within or outside this role.                                                                                                                                                                               |
| **library**   | modules, which may be used within this role (see Embedding modules and plugins in roles for more information).                                                                                                                         |
| **defaults**  | default variables for the role (see Using Variables for more information). <br/>These variables have the lowest priority of any variables available and can be easily overridden by any other variable, including inventory variables. |
| **vars**      | other variables for the role (see Using Variables for more information).                                                                                                                                                               |
| **files**     | files that the role deploys.                                                                                                                                                                                                           |
| **templates** | templates that the role deploys.                                                                                                                                                                                                       |
| **meta**      | metadata for the role, including role dependencies and optional Galaxy metadata such as platforms supported.                                                                                                                           |

### Building Ansible role

- In this demo we will create a role for deploying a nodeJS app
- The app will be deployed from a pre-defined code.
- Each server will be deployed with its own configuration (values)
- We will also deploy some other files for learning purposes

### 01. Initialize file structure

```sh
# Lets create the roles file structure
ansible-galaxy init codewizard_lab_role

# The file system of the role will look like
```

![](../../resources/ansible-role-structure.png)

### 02. Create the role content

#### 02.01. Create the `defaults/main.yml`
  
  ```yaml
  ---
  ### defaults/main.yml
  ###
  ### This file contain the variables for the Demo lab
  ###

  # Defaults file for codewizard_lab_role
  motd_message: "Welcome to Ansible Roles Lab"

  ### The package we wish to install on the servers
  apt_packages:
    - python3
    - nodejs
    - npm

  # Packages to verify that they were installed
  apt_packages_verify:
    - python3
    - npm

  package_state: latest
  ```

#### 02.02. Create the templates

  ```yaml
  ### templates/motd.j2

  _____             _          _    _  _                      _ 
  /  __ \           | |        | |  | |(_)                    | |
  | /  \/  ___    __| |  ___   | |  | | _  ____ __ _  _ __  __| |
  | |     / _ \  / _` | / _ \  | |/\| || ||_  // _` || '__|/ _` |
  | \__/\| (_) || (_| ||  __/  \  /\  /| | / /| (_| || |  | (_| |
  \____/ \___/  \__,_| \___|   \/  \/ |_|/___|\__,_||_|   \__,_|
  
  {{ motd_message }}

  System information:
  -------------------

  OS:         {{ ansible_distribution }} {{ ansible_distribution_version }}
  Hostname:   {{ inventory_hostname }}

  {{ custom_message | default('') }}
  ```

  ```yaml
  ### templates/node-server.j2
  const
      // Set the server port which will be listening to
      // Those 2 values are passed from the env file
      SERVER_PORT = 5000,
      SERVER_NAME = "{{ inventory_hostname }}";

  // Create the basic http server
  require('http')
      .createServer((request, response) => {

          // Send reply to user
          response.end(`<h1>Hello from ${SERVER_NAME}.</h1>`);

      }).listen(SERVER_PORT, () => {
          // Notify users that the server is up and running
          console.log(`${SERVER_NAME} is up. 
              Please click or point your browser to:
              http://localhost:${SERVER_PORT}`);
      });
  ```

#### 02.03. Create the tasks for the role

- In this example we will have multiple tasks for learning purposes
- We will need to create the tasks for each role
- Once the task are ready we can define them in the main task file

  ```yaml 
  ### tasks/pre-requirements.yaml
  ---
  - name: Install Packages
    ansible.builtin.apt:
      name: "{{ item }}"
      state: "{{ package_state }}"
    # Loop over the required packages to install
    with_items: "{{ apt_packages }}"

  - name: Verify Packages Installation
    ansible.builtin.command: "{{ item }} --version"
    register: packages_version
    with_items: "{{ apt_packages_verify }}"

  - name: Print package version
    ansible.builtin.debug:
      msg: "{{ item.stdout_lines  }}"
    with_items: "{{ packages_version.results }}"
  ```

  ```yaml 
  ### tasks/node-server.yaml
  ---
  - name: Copy Node server
    ansible.builtin.template:
      src: templates/node-server.j2
      dest: /node-server.js
      mode: 600
    become: true
    become_method: ansible.builtin.su

  - name: Install "pm2" node.js package.
    community.general.npm:
      name: "pm2"
      global: true
    become: true
    become_method: ansible.builtin.su

  - name: Get running node processes
    shell: "ps -ef | grep -v grep | grep -w node | awk '{print $2}'"
    register: running_processes

  - name: Kill running node server (if any)
    shell: "kill {{ item }}"
    with_items: "{{ running_processes.stdout_lines }}"

  - name: Wait for the process to die
    wait_for:
      path: "/proc/{{ item }}/status"
      state: absent
    with_items: "{{ running_processes.stdout_lines }}"
    ignore_errors: true
    register: killed_processes

  - name: Force kill stuck processes
    shell: "kill -9 {{ item }}"
    with_items: "{{ killed_processes.results | select('failed') | map(attribute='item') | list }}"

  - name: Start Node server
    ansible.builtin.command:
      chdir: /
      cmd: "pm2 start -f /node-server.js"
    register: server_status
    changed_when: server_status.rc != 0

  - name: Print server status
    ansible.builtin.debug:
      msg: "{{ server_status.stdout_lines }}"
    when: server_status.rc == 0

  - name: Check server
    uri:
      url: http://localhost:5000
      method: GET
      status_code: 200
    register: server_status

  - name: Print server status
    ansible.builtin.debug:
      msg: "{{ server_status.status }} - {{ server_status.msg }}"
    ```

    ```yaml
    ### tasks/motd.j2
    ---
    - name: Copy template
      ansible.builtin.template:
        src: templates/motd.j2
        dest: /etc/motd
        mode: preserve
      become: true
      become_method: ansible.builtin.su
    ```

    ```yaml
    ### tasks/main.yml
    ---
    - name: Include Pre-Requirements task
      ansible.builtin.include_tasks:
        file: pre-requirements.yaml

    - name: Include motd task
      ansible.builtin.include_tasks:
        file: motd.yaml

    - name: Deploy node server
      ansible.builtin.include_tasks:
        file: node-server.yaml
    ```        

  #### 02.04. Create the playbook for the role

  ```yaml
  ### 009-role-playbook.yml
  ---
  ###
  ### The playbook for using our role
  ### 
  - name: Executing codewizard_lab_role
    hosts: all
    become: true
    become_method: ansible.builtin.su

    roles:
      - codewizard_lab_role  
  ```


---
<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
    <a href="/Labs/008-challenges">:arrow_backward: /Labs/008-challenges</a>
    &emsp;<a href="/Labs">Back to labs list</a>
    &emsp;<a href="/Labs/010-loops-and-conditionals">/Labs/010-loops-and-conditionals :arrow_forward:</a>
</p>
<!--- Labs Navigation End -->
