<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-005.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-005.yaml/badge.svg" alt="Build Status">
</a>

---



# Lab 005 - Facts

- In this section, we will cover [**Ansible Facts**](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html#ansible-facts).
- **Ansible facts** are essentially "Ansible Scripts" and constitute one of the building blocks of Ansible.
- **Ansible facts** are data corresponding to your **remote systems**, which includes operating systems, IP addresses, attached filesystems, and more.
- **Ansible facts** are gathered, and relate to target nodes (host nodes to be configured). They are returned back to the controller node.

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
- all facts are prefixed with `ansible_x`.

<br>

#### **Example: Installing Packages Based on OS**

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

<br>

#### **Example: Conditional execution based on memory**
```yaml
- name: Restart Service if Memory is Low
  ansible.builtin.service:
    name: my_service
    state: restarted
  when: ansible_memory_mb.real.total < 4000
```

---

## 03. **Commonly used facts**

#### **System Information**

| Fact                           | Description                       |
| ------------------------------ | --------------------------------- |
| `ansible_distribution`         | OS name (Ubuntu, CentOS, Windows) |
| `ansible_distribution_version` | OS version (22.04, 9.1, 10)       |
| `ansible_architecture`         | System architecture (x86_64, arm) |

#### **Networking**

| Fact                           | Description                 |
| ------------------------------ | --------------------------- |
| `ansible_default_ipv4.address` | Default IP address          |
| `ansible_default_ipv4.gateway` | Default gateway             |
| `ansible_fqdn`                 | Fully Qualified Domain Name |
| `ansible_dns.nameservers`      | DNS servers                 |

#### **Hardware**

| Fact                           | Description         |
| ------------------------------ | ------------------- |
| `ansible_memory_mb.real.total` | Total RAM in MB     |
| `ansible_processor_count`      | Number of CPUs      |
| `ansible_processor_cores`      | Number of CPU cores |

* * *

## 04. **Disabling fact gathering**

- By default, Ansible gathers facts before running a playbook. 
- In order to disable it, add the following at the beginning of your playbook:

```yaml
- hosts: all
  gather_facts: no
  tasks:
    - name: Print a message
      debug:
        msg: "Facts gathering is disabled!"
```

* * *

## 05. **Custom Facts**

You can define custom facts by creating `.fact` files, placing them inside `/etc/ansible/facts.d/` directory on the managed host.

#### **Example: Creating a custom fact**

1️⃣ Create the file `/etc/ansible/facts.d/custom.fact` with:

```ini
[custom]
environment=production
app_version=1.2.3
```

2️⃣ Retrieve the fact in a playbook:

```yaml
- hosts: all
  tasks:
    - debug:
        msg: "App version is {{ ansible_local.custom.app_version }}"
```

---

## 06. **Hands-on**

  <img src="../assets/images/practice.png" width="800px">
  <br/>

- Print the IP addresses of all the machines.
- **Bonus** - Try printing the address of `linux-server-2` only, without modifying the inventory file.

---

## 07. **Summary**

🔹 Ansible **facts** provide system details dynamically.  
🔹 They are automatically gathered using the `setup` module.  
🔹 They are useful for **conditional logic** in playbooks.  
🔹 Facts may include **OS, networking, CPU, memory and more**.  
🔹 Custom facts can be created for **customized automation**.

