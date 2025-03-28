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

# Lab 004 - Playbooks

- In this section, we will cover **Ansible Playbooks** 
- **Playbook** are "Ansible Scripts" and are one of the building blocks of Ansible.

<img src="../../resources/ansible-playbook-yaml.png" style="background-color: white; border-radius: 15px" height="500px">

---

- [Lab 004 - Playbooks](#lab-004---playbooks)
  - [What are Playbook](#what-are-playbook)
    - [Ansible Playbooks Key Points:](#ansible-playbooks-key-points)
  - [01. Playbook Basics](#01-playbook-basics)
    - [01.01. YAML](#0101-yaml)
    - [01.02. Our first playbook](#0102-our-first-playbook)
    - [01.02. Writing Playbook](#0102-writing-playbook)
      - [Playbook content:](#playbook-content)
    - [01.03. Hands-on - Our first playbook](#0103-hands-on---our-first-playbook)
    - [02. Playbook syntax (Playbook Keywords)](#02-playbook-syntax-playbook-keywords)
    - [02.01. `Play`](#0201-play)
      - [02.02. Quiz:](#0202-quiz)
    - [02.03. Playbook demo](#0203-playbook-demo)
    - [02.03.01. Setting the env variable in the ansible controller](#020301-setting-the-env-variable-in-the-ansible-controller)
    - [02.03.02. Passing the variable to the playbook](#020302-passing-the-variable-to-the-playbook)
    - [02.03.03. Using the environment](#020303-using-the-environment)
    - [02.03.04. Permanently Set Environment Variables on Remote Hosts](#020304-permanently-set-environment-variables-on-remote-hosts)
    - [02.03.05. Using `var_files` to include variables](#020305-using-var_files-to-include-variables)
    - [03. Tasks](#03-tasks)
    - [03.01 Additional Tasks](#0301-additional-tasks)

---

## What are Playbook

- In the previous labs, we executed ansible Ad-Hoc command which invoked modules.
- In real life we need more that just Modules...
- This is where `Ansible Playbook` is jumping in.
- `Ansible Playbooks` are essentially **blueprints of automation tasks**. 
- They are written in `YAML`, and are used to **automate tasks on remote hosts**. 
- In summary, `Ansible Playbooks` offer a repeatable, reusable, simple configuration management and multi-machine deployment system, well suited to deploying complex applications. 
- They are a **powerful** tool for automating infrastructure management.

### Ansible Playbooks Key Points:

- **Structure** 
  A playbook is composed of one or more `plays` in an **ordered list** (Sequence). 
  Each play executes **part** of the overall goal of the playbook, running one or more tasks
  Each task calls an `Ansible module`.
- **Execution**
  - A playbook runs in order from top to bottom.
  - Within each play, tasks also run in order from top to bottom. 
  - Playbooks with multiple `plays` can orchestrate **multi-machine deployments**.
- **Functionality** 
  - Playbooks can declare **configurations**, **orchestrate steps** of any manual ordered process, on **multiple** sets of machines, in a defined order, and launch tasks synchronously or asynchronously.
- **Use Cases**
  - They are regularly used to automate IT infrastructure, networks, security systems, and code repositories like GitHub. 
  - IT staff can use playbooks to program applications, services, server nodes, and other devices.
- **Reusability**
  - The conditions, variables, and tasks within playbooks can be saved, shared, or reused indefinitely. 
  - This makes it easier for IT teams to codify operational knowledge and ensure that the same actions are performed consistently.



## 01. Playbook Basics

### 01.01. YAML

- The `playbook` is written in [YAML](https://ja.wikipedia.org/wiki/YAML) format.
- **Playbooks can also be written in JSON format**
  - In this course we will only use YAML format.
- YAML is a text file .
- YAML uses Python-style indentation to indicate nesting and does not **require quotes** around most string values
- Files should start with `---`.
- **Indentation has meanings** and is extremely import !!! 
  - Indentation should be written in `space`. `tab` will result in an error.
  - The level of indentation (using spaces, not tabs) is used to denote structure
- `key`: `value` makes it a dictionary format.
- **Key-Value Pairs**: A dictionary in YAML is represented in a simple `key`: `value` form. 
  - The colon **must** be followed by a space
- **Lists**: All members of a list are lines beginning at the **same indentation level** starting with a `-` (a dash and a space).
- **Multi-Line Strings**: Values can span multiple lines using `|` or `>`. 
  - Using a `Literal Block Scalar`  [`|`] will include the newlines and any trailing spaces. 
  - Using a `Folded Block Scalar`   [`>`] will fold newlines to spaces.
- **Boolean Values**: You can specify a boolean value (true/false) in several forms. 
  - Use lowercase `true` or `false` for boolean values in dictionaries if you want to be compatible with default yamllint options.

**YAML is case sensitive, so be careful with your capitalization.**

### 01.02. Our first playbook

- Here is our first playbook example
- This example will list files in a given directory

  ```yaml
  ---
  # Run on all the hosts
  - hosts: all
    
    # Here we define our tasks
    tasks:  
      # This is the first task 
      - name: List files in a directory  
        # As learned before this is the command module
        # This command will list files in the home directory
        command: ls ~  
        
        # register is used whenever we wish to save the output 
        # In this case it will be saved to a variable called 'files'
        register: files  

      # This is the second tasks
      # In this case the tasks will run in the declared sequence 
      - name: Print the list of files  
        # Using the builtin debug module 
        # The debug will print out our files list
        # ** We need to use `stdout_lines` for that
        debug:  
          msg: "{{ files.stdout_lines }}"  
  ```

### 01.02. Writing Playbook

- Playbook are `YAML` files
- Lets open editor and write the first playbook

#### Playbook content:

- `YAML` should start with the `---`
- Define the hosts we wish to run on. In this sample we will use `localhost`  
- Define the playbook tasks

**Its as simple as that**

### 01.03. Hands-on - Our first playbook

- Use this skeleton for our first playbook
  ```YAML
  # List of hosts
  - hosts: 
    
    # List of tasks
    tasks:
      - name: Execute 'uname -a'
        
      - name: Print 'uname -a' output
        
      - name: Execute 'id'
        
      - name: Print 'id' output
  ```

- Now lets fill in with content
- First lets define localhost as the host for this playbook
  ```YAML
  ---
  - hosts: localhost
  ```
- Next steps is to define the tasks

> [!TIP]
>
> Like in every other programming/scripting language there is no "right"
> solution and the bellow solution will work like any solution that will work
> for you, so feel free to write it any way which works for you.

  ```YAML
  # List of hosts
  - hosts: localhost
    
    ###
    ### In this sample we display several solutions
    ### 
    ### We combine few commands like: `shell`, `debug`, `command` and more
    ###
    
    # List of tasks
    tasks:
      # Using shell it will work, but no out put will be displayed out
      # We will need to use register to display output
      - name: Execute 'uname -a'
        shell: uname -a
        register: task_output
      
      # Using register we can now display the output contents
      # We must use `.stdout` to display the output itself
      - name: Print 'uname -a' output
        debug: 
          msg: "{{ task_output.stdout}}"    
  ```

- Output:
  ```sh
  * Executing ansible Ad-Hoc commands

  $ ansible localhost -m shell -a 'uname -a'
  localhost | CHANGED | rc=0 >>
  Linux 1fa29998d58c 5.15.0-105-generic #115-Ubuntu SMP Mon Apr 15 09:52:04 
  UTC 2024 aarch64 aarch64 aarch64 GNU/Linux
  -----------------------------------

  * Executing ansible playbook

  $ cat 004-playbook.yaml
    # List of hosts
    - hosts: localhost

      ###
      ### In this sample we display several solutions
      ###
      ### We combine few commands like: `shell`, `debug`, `command` and more
      ###

      # List of tasks
      tasks:
        # Using shell it will work, but no out put will be displayed out
        # We will need to use register to display output
        - name: Execute 'uname -a'
          shell: uname -a
          register: task_output

        # Using register we can now display the output contents
        # We must use `.stdout` to display the output itself
        - name: Print 'uname -a' output
          debug:
            msg: "{{ task_output.stdout}}"   
  ```

  ```sh
  $ ansible-playbook 004-install-nginx.yaml
  
  PLAY [localhost] ***************************************************************

  TASK [Gathering Facts] *********************************************************
  ok: [localhost]

  TASK [Execute 'uname -a'] ******************************************************
  changed: [localhost]

  TASK [Display the output] ******************************************************
  ok: [localhost] => {
      "msg": "Linux 1fa29998d58c 5.15.0-105-generic #115-Ubuntu SMP Mon Apr 15
      09:52:04 UTC 2024 aarch64 aarch64 aarch64 GNU/Linux"
  }

  PLAY RECAP *********************************************************************
  localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
  ```

---

  <img src="../../resources/practice.png" width="250px">
  <br/>

- Complete the playbook, this time use `command` instead of shell
---


### 02. Playbook syntax (Playbook Keywords)

- In this section, we will more about playbooks syntax

### 02.01. `Play`
- [Official documentation](https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html#play)
- The **top** part of the playbook is called `Play` and it **defines** the **global behavior** of for the **entire** playbook.
- Here are some definitions which defined in the `Play`  

  ```yaml
  ---
  - name: The name of the play
    # A list of groups, hosts or host pattern that translates into a list 
    # of hosts that are the play’s target.
    hosts: localhost
    
    # Boolean that controls if privilege escalation is used or not on 
    # Task execution.
    # Implemented by the become plugin
    become: yes

    # User that you ‘become’ after using privilege escalation. 
    # The remote/login user must have permissions to become this user.
    become_user: 

    # A dictionary that gets converted into environment vars to be provided 
    # for the task upon execution. 
    # This can ONLY be used with modules. 
    # This is not supported for any other type of plugins nor Ansible itself 
    # nor its configuration, it just sets the variables for the code responsible
    # for executing the task. 
    # This is not a recommended way to pass in confidential data.
    environment: 
    
    # Dictionary/map of variables
    vars: 
  ```

#### 02.02. Quiz:

  - Review the example below and try to answer the following questions:
    - On which hosts the playbook should be executed?
    - How we define the play?
    - Which directives are defined in this playbook?
    - How do we define variables?
    - How do we use variables?
    - How do we set up root user?
    -   
      ```yaml
      #
      # Install nginx
      #
      name: Install and start nginx
      
      # We should have this group in our inventory
      hosts: webservers
      
      # Variables
      # The `lookup` function is used to fetch the value of the environment variables 
      vars:
        env:
          PORT: "{{ lookup('env','PORT') }}"
          PASSWORD: "{{ lookup('env','PASSWORD') }}"

      # Define the tasks    
      tasks:
        - name: Install nginx
          apt:
            name: nginx
            state: present
          become: yes

        - name: Start nginx service
          service:
            name: nginx
            state: started
          become: yes

        - name: Create a new secret with environment variable
          shell: echo "secret:{{ PASSWORD }}" > /etc/secret
          become: yes

        - name: Open the port in firewall
          ufw:
            rule: allow
            port: "{{ PORT }}"
            proto: tcp
          become: yes
      ```

### 02.03. Playbook demo

- Execute the playbook by adding the required parameters to teh playbook
- This can be done by setting up the parameter prior to executing the playbook
Or by adding the parameters to the playbook itself.

### 02.03.01. Setting the env variable in the ansible controller
  
  ```yaml
  # Example: 
  
  # 01. Setting the env variable in the ansible controller
  export PORT=8080
  
  # Use the -e/--extra-vars to inject environment variables into the playbook
  ansible-playbook playbook.yaml -e "my_var=$MY_VAR"

  # Using the lookup Plug to fetch the value of the environment variables
  PORT: "{{ lookup('env','PORT') }}"
  ```

### 02.03.02. Passing the variable to the playbook
  
  ```yaml
  # Example:

  # 02. Passing the variable to the playbook
  PORT="8080" ansible-playbook playbook.yaml
  ```

### 02.03.03. Using the environment
  
  - Using the environment keyword in a **task** to set variables for that task:
  
  ```yaml
  # Example:
  - name: Open the port in firewall
    environment:
      PORT: "8080"
    ufw:
      rule: allow
      port: "{{ PORT }}"
      proto: tcp
  ```

  - Passing the environment to all the tasks in Playbook:
  
  ```yaml
  # Example:
  - hosts: all
    environment:
      PORT: "8080"
    tasks:
      - name: Open the port in firewall
      ...
  ```

### 02.03.04. Permanently Set Environment Variables on Remote Hosts

  - To persist variables (e.g., in .bashrc or /etc/environment):
  
  ```yaml
  # Example:
  - name: Set permanent environment variable
    lineinfile:
      path: /etc/environment
      line: 'PORT="8080"'
      state: present
    become: yes
  ```

### 02.03.05. Using `var_files` to include variables

  - We can use a variable file to pass variables in a playbook
  
  ```yaml
    # Example
    # Check the vars.yaml file in the same directory
    
    - hosts: all
      vars_files:
        - vars.yaml  # Include variables from vars.yaml
      tasks:
        - name: Print a variable
          debug:
            msg: "{{ http_port }}"
  ```

### 03. Tasks

  - https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html#running-playbooks-in-check-mode
  
    ```sh
    # To run a playbook in check mode, 
    # you can pass the -C or --check flag to 
    # the ansible-playbook command:
    ansible-playbook --check playbook.yaml
    ```

- Lets write some playbooks tasks with parameters
- Take a look on `004-list-files.yaml` and follow the instructions in the comments
- Answer the questions in the comments about the `with_items` the output of the playbook
  
### 03.01 Additional Tasks  

- Run the playbook and see the output
- Run the playbook in `check` mode and see the output
- Run the playbook with `--diff` flag and see the output
- Run the playbook with `--verbose` flag and see the output
- Run the playbook with `--verbose`, `--diff` flags and see the output
- Run the playbook with `--verbose`, `--diff`, `--check` flags and see the output
 
---

> [!TIP]
> It's considered best practice to use the FQDN name of all modules used in your playbook.
> It is done to prevent naming collision between builtin modules and community/self made ones.

---
<!--- Labs Navigation Start -->  
<p style="text-align: center;">  
    <a href="/Labs/003-modules">:arrow_backward: /Labs/003-modules</a>
    &emsp;<a href="/Labs">Back to labs list</a>
    &emsp;<a href="/Labs/005-facts">/Labs/005-facts :arrow_forward:</a>
</p>
<!--- Labs Navigation End -->

