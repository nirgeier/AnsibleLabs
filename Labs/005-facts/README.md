---



# Facts

* In this section, we will cover [**Ansible Facts**](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html#ansible-facts).
* **Ansible facts** are essentially "Ansible Scripts" and constitute one of the building blocks of Ansible.
* **Ansible facts** are data corresponding to your **remote systems**, which includes operating systems, IP addresses, attached filesystems, and more.
* **Ansible facts** are gathered, and relate to target nodes (host nodes to be configured). They are returned back to the controller node.

## What will we learn?

- How to view and use Ansible facts
- How to use facts in playbooks for conditional logic
- How to disable fact gathering
- How to create and use custom facts

---

## Prerequisites

- Complete the [previous lab](../004-playbooks/README.md) in order to have `Ansible` set up with playbooks.

---

## 01. **How to View Facts?**

- Ansible gathers facts about remote systems using the `setup` module.
- You can view facts of a remote machine by running the following command:

```bash
ansible all -m setup
```

- Example Output (Truncated for brevity):
  ```json
  {
    "ansible_facts": {
      "ansible_distribution": "Ubuntu",
      "ansible_distribution_version": "22.04",
      "ansible_architecture": "x86_64",
      "ansible_memory_mb": {
        "real": {
          "total": 7989,
          "used": 2034
        }
      },
      "ansible_default_ipv4": {
        "address": "192.168.1.10",
        "netmask": "255.255.255.0",
        "gateway": "192.168.1.1"
      }
    }
  }
  ```

---

## 02. **How to use facts in playbooks?**

- Facts allow you to base your playbook logic on the properties of the target hosts.
- All facts are prefixed with `ansible_x`.
- For example, to access the operating system distribution of a host, you would use `ansible_distribution`.
- Here are some examples of how to use facts in playbooks:
  - #### Example: Installing Packages Based on OS

    ```yaml
    ---
    - hosts: all
      tasks:
        - name: Install Nginx on Debian using APT
          ansible.builtin.apt:
            name: nginx
            state: present
          when: ansible_distribution == "Ubuntu"

        - name: Install Nginx on RedHat using DNF
          ansible.builtin.dnf:
            name: nginx
            state: present
          when: ansible_distribution == "CentOS"
    ```

  - #### Example: Conditional execution based on memory

    ```yaml
    - name: Restart Service if Memory is Low
      ansible.builtin.service:
        name: my_service
        state: restarted
      when: ansible_memory_mb.real.total < 4000
    ```

---

## 03. **Commonly used facts**

#### System Information

| Fact                           | Description                         |
| ------------------------------ | ----------------------------------- |
| `ansible_distribution`         | OS name (Ubuntu, CentOS, Windows)   |
| `ansible_distribution_version` | OS version (22.04, 9.1, 10)         |
| `ansible_architecture`         | System architecture (x86_64, arm)   |
| `ansible_hostname`             | Hostname of the machine             |
| `ansible_os_family`            | OS family (Debian, RedHat, Windows) |
| `ansible_facts`                | All gathered facts                  |

#### Networking

| Fact                           | Description                 |
| ------------------------------ | --------------------------- |
| `ansible_default_ipv4.address` | Default IP address          |
| `ansible_default_ipv4.gateway` | Default gateway             |
| `ansible_fqdn`                 | Fully Qualified Domain Name |
| `ansible_dns.nameservers`      | DNS servers                 |

#### Hardware

| Fact                           | Description         |
| ------------------------------ | ------------------- |
| `ansible_memory_mb.real.total` | Total RAM in MB     |
| `ansible_processor_count`      | Number of CPUs      |
| `ansible_processor_cores`      | Number of CPU cores |

#### User-defined Facts

| Fact            | Description   |
| --------------- | ------------- |
| `ansible_user`  | Current user  |
| `ansible_group` | Current group |

---

## 04. **Disabling fact gathering**

- By default, Ansible gathers facts before running a playbook.
- In order to disable it, add the following at the beginning of your playbook:
- To disable fact gathering, set `gather_facts` to `no` in your playbook:

```yaml
- hosts: all
  gather_facts: no
  tasks:
    - name: Print a message
      debug:
        msg: "Facts gathering is disabled!"
```

---

## 05. **Custom Facts**

- You can define custom facts by creating `.fact` files, placing them inside `/etc/ansible/facts.d/` directory on the managed host.

#### Example: Creating a custom fact

- Create the file `/etc/ansible/facts.d/custom.fact` with:

  ```ini
  [custom]
  environment=production
  app_version=1.2.3
  ```

- Retrieve the fact in a playbook:

  ```yaml
  - hosts: all
    tasks:
      - debug:
          msg: "App version is {{ ansible_local.custom.app_version }}"
  ```

#### Using Custom Facts

- Another way to define your own custom facts using the `set_fact` module in your playbooks.
- Here is an example:

  ```yaml
  - hosts: all
    tasks:
      - name: Set custom fact
        ansible.builtin.set_fact:
          my_custom_fact: "Hello, Ansible!"
      - name: Print custom fact
        debug:
          msg: "{{ my_custom_fact }}"
  ```

---

## 06. **Hands-on**

  <img src="../assets/images/practice.png" width="800px">
  <br/>

- Use the `setup` module to gather and print all facts from `linux-server-1`.

  ??? success "Solution"
  `bash
    ansible linux-server-1 -m setup
    `

- Use the `setup` module to gather and print only the network-related facts from `linux-server-2`.

  ??? success "Solution"
  `bash
    ansible linux-server-2 -m setup -a "filter=ansible_default_ipv4*"
    `

- Create a playbook that installs `nginx` only if the target host is running `Ubuntu`.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Install nginx on Ubuntu
          ansible.builtin.apt:
            name: nginx
            state: present
          when: ansible_distribution == "Ubuntu"
    `

- Create a playbook that restarts a service only if the host has less than `4GB` of RAM.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Restart service if memory low
          ansible.builtin.service:
            name: my_service
            state: restarted
          when: ansible_memory_mb.real.total < 4096
    `

- Create a custom fact that defines the environment as `development` and print it in a playbook.

  ??? success "Solution"
  First, create `/etc/ansible/facts.d/custom.fact` on the host:

      ```ini
      [custom]
      environment=development
      ```

      Then playbook:

      ```yaml
      ---
      - hosts: all
        tasks:
          - debug:
              msg: "Environment is {{ ansible_local.custom.environment }}"
      ```

- Create a playbook that sets a custom fact `deployment_stage` to `staging` and prints it.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Set custom fact
          ansible.builtin.set_fact:
            deployment_stage: staging
        - name: Print custom fact
          debug:
            msg: "Deployment stage: {{ deployment_stage }}"
    `

- Disable fact gathering in a playbook and print a message indicating that facts are not gathered.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      gather_facts: no
      tasks:
        - name: Print message
          debug:
            msg: "Facts gathering is disabled!"
    `

- Create a playbook that prints the hostname of each target host using the appropriate fact.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Print hostname
          debug:
            msg: "Hostname: {{ ansible_hostname }}"
    `

- Create a playbook that checks the OS family and installs a package accordingly (e.g., `nginx` for `Debian`, `httpd` for `RedHat`).

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Install nginx on Debian
          ansible.builtin.apt:
            name: nginx
            state: present
          when: ansible_os_family == "Debian"
        - name: Install httpd on RedHat
          ansible.builtin.dnf:
            name: httpd
            state: present
          when: ansible_os_family == "RedHat"
    `

- Create a playbook that gathers facts and prints the total memory of each host.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Print total memory
          debug:
            msg: "Total memory: {{ ansible_memory_mb.real.total }} MB"
    `

- Create a playbook that checks the default gateway and prints it.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Print default gateway
          debug:
            msg: "Default gateway: {{ ansible_default_ipv4.gateway }}"
    `

- Create a playbook that sets a custom fact `backup_required` to `yes` and prints a message if backup is required.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Set custom fact
          ansible.builtin.set_fact:
            backup_required: yes
        - name: Print message if backup required
          debug:
            msg: "Backup is required"
          when: backup_required == "yes"
    `

- Create a playbook that uses the `ansible_user` fact to print the current user on each host.

  ??? success "Solution"
  `yaml
    ---
    - hosts: all
      tasks:
        - name: Print current user
          debug:
            msg: "Current user: {{ ansible_user }}"
    `

- Print the IP addresses of all the machines.

  ??? success "Solution"
  `bash
    ansible all -m setup -a "filter=ansible_default_ipv4.address"
    `

- **Bonus** - Try printing the address of `linux-server-2` only, without modifying the inventory file.

  ??? success "Solution"
  `bash
    ansible linux-server-2 -m setup -a "filter=ansible_default_ipv4.address"
    `

---

## 07. Summary

- Ansible **facts** provide system details dynamically.
- They are automatically gathered using the `setup` module.
- They are useful for **conditional logic** in playbooks.
- Facts may include **OS, networking, CPU, memory and more**.
- Custom facts can be created for **customized automation**.
