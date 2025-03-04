![](../../resources/ansible_logo.png)

<a href="https://stackoverflow.com/users/1755598"><img src="https://stackexchange.com/users/flair/1951642.png" width="208" height="58" alt="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites" title="profile for CodeWizard on Stack Exchange, a network of free, community-driven Q&amp;A sites"></a>

<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/004-playbooks.yaml"><img src="https://img.shields.io/github/actions/workflow/status/nirgeier/AnsibleLabs/004-playbooks.yaml?branch=main&style=flat" style="height: 20px;"></a> ![Visitor Badge](https://visitor-badge.laobi.icu/badge?page_id=nirgeier) [![Linkedin Badge](https://img.shields.io/badge/-nirgeier-blue?style=flat&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/nirgeier/)](https://www.linkedin.com/in/nirgeier/) [![Gmail Badge](https://img.shields.io/badge/-nirgeier@gmail.com-fcc624?style=plastic&logo=Gmail&logoColor=red&link=mailto:nirgeier@gmail.com)](mailto:nirgeier@gmail.com) [![Outlook Badge](https://img.shields.io/badge/-nirg@codewizard.co.il-fcc624?style=plastic&logo=microsoftoutlook&logoColor=blue&link=mailto:nirg@codewizard.co.il)](mailto:nirg@codewizard.co.il)

---

# Lab 005 - Facts

- In this section, we will cover **Ansible Facts** 
- **Ansible facts** are "Ansible Scripts" and are one of the building blocks of Ansible.
- **Ansible facts** are data related to your **remote systems**, including operating systems, IP addresses, attached filesystems, and more. 
- **Ansible facts** are gathered about target nodes (host nodes to be configured) and returned back to controller nodes.

## **How to View Facts?**

You can view facts of a remote machine by running:

```bash
ansible all -m setup
```

🔹 Example Output (Truncated for brevity):

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


## **How to Use Facts in Playbooks?**

- Facts allows you to base your playbook logic on the properties of the target hosts.
- all facts are prefixed with `ansible_x`.

### **Example: Installing Packages Based on OS**

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

### **Example: Conditional Execution Based on Memory**

```yaml
- name: Restart Service if Memory is Low
  ansible.builtin.service:
    name: my_service
    state: restarted
  when: ansible_memory_mb.real.total < 4000
```


## **Commonly Used Facts**

### **System Information**

| Fact | Description |
| --- | --- |
| `ansible_distribution` | OS name (Ubuntu, CentOS, Windows) |
| `ansible_distribution_version` | OS version (22.04, 9.1, 10) |
| `ansible_architecture` | System architecture (x86_64, arm) |

### **Networking**

| Fact | Description |
| --- | --- |
| `ansible_default_ipv4.address` | Default IP address |
| `ansible_default_ipv4.gateway` | Default gateway |
| `ansible_fqdn` | Fully Qualified Domain Name |
| `ansible_dns.nameservers` | DNS servers |

### **Hardware**

| Fact | Description |
| --- | --- |
| `ansible_memory_mb.real.total` | Total RAM in MB |
| `ansible_processor_count` | Number of CPUs |
| `ansible_processor_cores` | Number of CPU cores |

* * *

## **Disabling Fact Gathering**

By default, Ansible gathers facts before running a playbook. To disable it:

```yaml
- hosts: all
  gather_facts: no
  tasks:
    - name: Print a message
      debug:
        msg: "Facts gathering is disabled!"
```

* * *

## **Custom Facts**

You can define custom facts by creating `.fact` files in `/etc/ansible/facts.d/` on the managed host.

### **Example: Creating a Custom Fact**

1️⃣ Create a file `/etc/ansible/facts.d/custom.fact` with:

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


## **Summary**

🔹 Ansible **facts** provide system details dynamically.  
🔹 They are automatically gathered using the `setup` module.  
🔹 Useful for **conditional logic** in playbooks.  
🔹 Facts include **OS, networking, CPU, memory, and more**.  
🔹 Custom facts can be created for **customized automation**.

---

  <img src="../../resources/practice.png" width="250px">
  <br/>

- Print the IP addresses of all the machines
- **Bonus** - Try print the addresss of `linux-server-2` only without modifying the inventory file.
---

<p style="text-align: center;">
    <a href="/Labs/004-playbooks/">
    :arrow_backward: 004-playbooks
    </a>
    &emsp;
    <a href="/Labs">
    Back to labs list
    </a>    
    &emsp;
    <a href="/Labs/006-git/">
    006-git :arrow_forward:
    </a>
</p>