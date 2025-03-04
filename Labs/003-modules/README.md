![](../../resources/ansible_logo.png)

<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/003-modules.yaml"><img src="https://img.shields.io/github/actions/workflow/status/nirgeier/AnsibleLabs/003-modules.yaml?branch=main&style=flat" style="height: 20px;"></a> ![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier) [![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/) [![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com) [![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

# Lab 003 - Commands & Modules

- In this section, we will cover **Module** 
- **Modules** are important elements and are the "heart" of ansible.

- [Lab 003 - Commands \& Modules](#lab-003---commands--modules)
  - [What is a Module?](#what-is-a-module)
    - [Sample Module - The build in 'ping' Module](#sample-module---the-build-in-ping-module)
    - [The ping module](#the-ping-module)
  - [List of modules](#list-of-modules)
  - [Ad-hoc command](#ad-hoc-command)
    - [ping](#ping)
    - [shell](#shell)
    - [dnf](#dnf)
    - [setup](#setup)


![Ansible Architecture](../../resources/ansible-engine.jpg)

## What is a Module?

- A module is a unit of code in Ansible that performs **common operations in infrastructure management**, such as configuring systems, installing software, or managing resources. 
- Ansible has a **huge** number of modules. 
- You can browser and search ansible builtin modules under the [Build In Ansible Modules](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html#modules)
- Module are used for task automation.

### Sample Module - The build in 'ping' Module

- In this lab we will explore the build in `ping` Module
- The source code for this module is: https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/ping.py

### 01. The ping module 
- Source: https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/ping.py
- Docs:   https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html
<br/>  
  
  > **From the docs:**
  > 
  > - **ansible.builtin.ping** module – **Try to connect to host, verify a usable python and return pong on success**
  > - This module is part of ansible-core and included in all Ansible installations. 
  > - In most cases, you can use the short module name `ping`


- Now we will break down the code, fell free to browse and look on the full code Browse the code.

### 01.01. The ping source code

- At the time of writing this tutorial, the "implementation" of the `ping` is the following
```python
RETURN = '''
ping:
    description:  Value provided with the O(data) parameter.
    returned:     success
    type:         str
    sample:       pong
'''

from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(
        argument_spec=dict(
            data=dict(type='str', default='pong'),
        ),
        supports_check_mode=True
    )

    if module.params['data'] == 'crash':
        raise Exception("boom")

    result = dict(
        ping=module.params['data'],
    )

    module.exit_json(**result)

if __name__ == '__main__':
    main()
```

## 02. List of modules

- Modules are managed in the form of `collection', and each collection contains multiple related modules. 
- [List of Collections](https://docs.ansible.com/ansible/latest/collections/index.html)

> Note: 
> Up to version 2.9 Ansible included **all modules** by default, 
> but the number of modules increased so much that it was changed to the current format (2.10 and later)

## 02. Using modules

- By default Ansible is installed with `ansible.builtin` as the only collection. 
- A list of modules that are available in the `ansible.builtin` [click here](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html#modules) 

### 02.01. Find modules for you OS 

- To see which modules are available for you OS use this command:
  ```sh
  ansible-doc -l

  ### Output (only first few lines)
  add_host        Add a host (and alternatively a group) to the ansible-playbook in-memory inventor...
  apt             Manages apt-packages
  apt_key         Add or remove an apt key
  apt_repository  Add and remove APT repositories
  assemble        Assemble configuration files from fragments
  assert          Asserts given expressions are true
  async_status    Obtain status of asynchronous task
  blockinfile     Insert/update/remove a text block surrounded by marker lines
  ```

### 02.02. Documentation

- To view documentation for a specific module:
  ```text
  # Display the ping documentation
  $ ansible-doc ping

  > ANSIBLE.BUILTIN.PING    (/opt/homebrew/Cellar/ansible/9.4.0_1/libexec/lib/python3.12/site-packages/ansible/modules/ping>

        A trivial test module, this module always returns `pong' on successful contact. It does
        not make sense in playbooks, but it is useful from `/usr/bin/ansible' to verify the
        ability to login and that a usable Python is configured. This is NOT ICMP ping, this is
        just a trivial test module that requires Python on the remote-node. For Windows targets,
        use the [ansible.windows.win_ping] module instead. For Network targets, use the
        [ansible.netcommon.net_ping] module instead.

  ADDED IN: historical

  OPTIONS (= is mandatory):

  - data
        Data to return for the `ping' return value.
  ```

## 03. Common Ad-hoc command

- Invoking a module is referred to as `Ad-hoc command`.
- The syntax is the following:
  ```sh
  $ ansible <servers> -m <module_name> -a '<parameters>'
  ```
  | CLI option         | Description                                                                 |
  | ------------------ | --------------------------------------------------------------------------- |
  | `<servers>`        | Any server (singel, group or all) as defined in the inventory file          |
  | `-m <module_name>` | Specifies the module name.                                                  |
  | `-a <parameters>`  | Specifies the parameters to be passed to the module. Optional in most cases |


#### 03.01. `ping`

- Docs: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html
- We are already familiar with ping 

  > [!TIP]
  > This is a module that determines whether Ansible can "communicate as Ansible" to the node it is working 
  > on (which is different from ICMP used in the network). 
  > Ping module parameters are optional.

- Usage:
 
  ```sh
  # Ping all server in the inventory
  ansible all -m ping

  # In our demo lab we will execute it like this:
  docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"
  ```

- Output
  ```text
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
  linux-server-2 | SUCCESS => {
      "ansible_facts": {
          "discovered_interpreter_python": "/usr/bin/python3"
      },
      "changed": false,
      "ping": "pong"
  }
  ```

### 03.03. `shell`

- Docs: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html

  > [!TIP]
  > This is a module that Execute shell commands on targets

  ```sh
  # Lets get the hostname of the server
  ansible all -m shell -a 'hostname'

  # In our demo lab we will execute it like this:
  docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m shell -a 'hostname'"
  ```

  - # Output
  ```text
  # ansible all -m shell -a 'hostname' 
  linux-server-3 | CHANGED | rc=0 >>
  linux-server-3
  linux-server-2 | CHANGED | rc=0 >>
  linux-server-2
  linux-server-1 | CHANGED | rc=0 >>
  linux-server-1
  ```

---

<img src="../../resources/practice.png" height="150px">

### Hands-on

01. Figure out way to run the following (shell) command with `Ansible`, on any of the servers:
  
    ```sh
    # Get kernel information
    uname -a

    # Get a date
    date
    ```

02. Use the ansible `command` module to print out the previous shell commands.

03. Try to run the following command: `git config -l`.
    > What is the result of this command?

### Solution

  <details>
    <summary>uname -a</summary>
    
    ```sh
    # Using the shell module
    docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m shell -a 'uname -a'"

    #Using the ansible `command` module
    docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m command -a 'uname -a'"
    ```
  </details>

  <details>
    <summary>date</summary>
    
    ```sh
    # Using the shell module
    docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m shell -a 'date'"

    #Using the ansible `command` module
    docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m command -a 'date'"
    ```
  </details>

---

<p style="text-align: center;">
    <a href="/Labs/002-no-inventory/">
    :arrow_backward: 002-no-inventory
    </a>
    &emsp;
    <a href="/Labs">
    Back to labs list
    </a>    
    &emsp;
    <a href="/Labs/004-playbooks">
    004-playbooks :arrow_forward:
    </a>
</p>