---
# Ansible Facts Deep Dive

* In this lab we explore Ansible **facts** - system information automatically gathered from managed hosts before tasks run.
* Facts enable OS-aware playbooks that adapt to the target system without hardcoding values.
* Custom facts let you extend the facts namespace with your own application metadata.

## What will we learn?

- How the `setup` module gathers facts
- Navigating the facts namespace
- Custom facts (`/etc/ansible/facts.d/`)
- Caching facts for performance
- Using facts in conditionals and templates

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) in order to have a working knowledge of Ansible playbooks.

---

## 01. How Facts Are Gathered

```yaml
---
- name: Gather facts example
  hosts: all
  gather_facts: true # Default: true; set false to skip (faster)

  tasks:
    - name: All facts are available
      ansible.builtin.debug:
        var: ansible_facts
```

```sh
# Manually gather facts (useful for exploration)
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup"

# Filter facts
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_os_family'"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_*_mb'"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_interfaces'"

# Save to files
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup --tree /tmp/facts/"
```

---

## 02. Key Facts Categories

### OS and Distribution

```yaml
{{ ansible_os_family }}              # Debian, RedHat, Darwin, etc.
{{ ansible_distribution }}           # Ubuntu, CentOS, macOS, etc.
{{ ansible_distribution_version }}   # 22.04, 8.5, etc.
{{ ansible_distribution_major_version }} # 22, 8, etc.
{{ ansible_distribution_release }}   # jammy, focal, etc.
{{ ansible_kernel }}                 # Linux kernel version
{{ ansible_architecture }}           # x86_64, aarch64, etc.
```

### Network

```yaml
{{ ansible_hostname }}               # Short hostname
{{ ansible_fqdn }}                   # Fully qualified domain name
{{ ansible_default_ipv4.address }}   # Primary IPv4 address
{{ ansible_default_ipv4.interface }} # Primary network interface
{{ ansible_default_ipv6.address }}   # Primary IPv6 address
{{ ansible_all_ipv4_addresses }}     # List of all IPv4 addresses
{{ ansible_interfaces }}             # List of all interfaces
{{ ansible_eth0.ipv4.address }}      # IP of specific interface (eth0)
{{ ansible_dns.nameservers }}        # DNS servers
```

### Hardware

```yaml
{{ ansible_processor_vcpus }}        # Number of vCPUs
{{ ansible_processor_count }}        # Physical CPU count
{{ ansible_memtotal_mb }}            # Total RAM in MB
{{ ansible_memfree_mb }}             # Free RAM in MB
{{ ansible_swaptotal_mb }}           # Total swap
{{ ansible_mounts }}                 # List of mounted filesystems
```

### Time

```yaml
{{ ansible_date_time.date }}         # 2024-03-15
{{ ansible_date_time.time }}         # 14:30:00
{{ ansible_date_time.iso8601 }}      # 2024-03-15T14:30:00Z
{{ ansible_date_time.epoch }}        # Unix timestamp
{{ ansible_date_time.weekday }}      # Friday
{{ ansible_date_time.tz }}           # UTC
```

### Python

```yaml
{{ ansible_python.version.major }}   # 3
{{ ansible_python.executable }}      # /usr/bin/python3
```

---

## 03. Using Facts in Conditionals

```yaml
tasks:
  - name: Install apt packages (Debian only)
    ansible.builtin.apt:
      name: nginx
      state: present
    when: ansible_os_family == "Debian"

  - name: Install yum packages (RHEL only)
    ansible.builtin.yum:
      name: nginx
      state: present
    when: ansible_os_family == "RedHat"

  - name: Apply extra config for Ubuntu 22.04+
    ansible.builtin.template:
      src: ubuntu22.conf.j2
      dest: /etc/app/extra.conf
    when:
      - ansible_distribution == "Ubuntu"
      - ansible_distribution_major_version | int >= 22

  - name: High-memory server config
    ansible.builtin.copy:
      content: "max_connections=500\n"
      dest: /etc/app/db.conf
    when: ansible_memtotal_mb > 8192
```

---

## 04. Facts in Templates

```jinja2
{# templates/system-report.j2 #}
System Report for {{ inventory_hostname }}
==========================================
Generated: {{ ansible_date_time.date }} {{ ansible_date_time.time }}

OS:          {{ ansible_distribution }} {{ ansible_distribution_version }}
Kernel:      {{ ansible_kernel }}
Architecture: {{ ansible_architecture }}

Hardware:
  CPUs:      {{ ansible_processor_vcpus }}
  RAM:       {{ ansible_memtotal_mb }} MB
  Free RAM:  {{ ansible_memfree_mb }} MB

Network:
  Hostname:  {{ ansible_hostname }}
  FQDN:      {{ ansible_fqdn }}
  IP:        {{ ansible_default_ipv4.address }}
  Interface: {{ ansible_default_ipv4.interface }}

Mounts:
{% for mount in ansible_mounts %}
  {{ mount.mount }}: {{ mount.size_total | filesizeformat }} total, {{ mount.size_available | filesizeformat }} free
{% endfor %}
```

---

## 05. Custom Facts

```sh
# Create the facts directory on managed nodes
mkdir -p /etc/ansible/facts.d/

# Write a static fact file (INI format)
cat > /etc/ansible/facts.d/application.fact << 'EOF'
[app]
name=mywebservice
version=2.1.0
environment=production
deployment_date=2024-03-15
EOF

# Or JSON format
cat > /etc/ansible/facts.d/config.json << 'EOF'
{
  "role": "webserver",
  "tier": "frontend",
  "datacenter": "us-east-1"
}
EOF
```

```yaml
# Access custom facts in playbooks
{{ ansible_local.application.app.name }}
{{ ansible_local.application.app.version }}
{{ ansible_local.config.role }}
```

---

## 06. Deploy Custom Facts with Ansible

```yaml
tasks:
  - name: Create facts directory
    ansible.builtin.file:
      path: /etc/ansible/facts.d
      state: directory
      mode: "0755"

  - name: Deploy custom facts
    ansible.builtin.copy:
      content: |
        {
          "role": "{{ server_role | default('generic') }}",
          "environment": "{{ env | default('development') }}",
          "team": "{{ team | default('platform') }}"
        }
      dest: /etc/ansible/facts.d/custom.json
      mode: "0644"

  - name: Refresh facts to pick up new custom facts
    ansible.builtin.setup:
      filter: ansible_local

  - name: Show custom facts
    ansible.builtin.debug:
      var: ansible_local.custom
```

---

## 07. Caching Facts for Performance

```ini
# ansible.cfg
[defaults]
# Enable fact caching
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible-facts
fact_caching_timeout = 86400    # Cache for 24 hours
```

```sh
# Clear cache manually
rm -rf /tmp/ansible-facts/

# Disable cache for a single run
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --flush-cache"
```

---

## 08. Gathering Specific Facts Only

```yaml
---
- name: Gather only what you need
  hosts: all
  gather_facts: false # Skip auto-gather

  tasks:
    - name: Gather only network facts
      ansible.builtin.setup:
        gather_subset:
          - network # Only network facts
          - "!all" # Exclude all others
          - "!min" # Exclude minimum set

    # Available subsets: all, min, hardware, network, virtual, ohai, facter
    - name: Gather hardware and network
      ansible.builtin.setup:
        gather_subset:
          - hardware
          - network
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 09. Hands-on

1. Explore all facts for one host and then filter for distribution-related facts:

   ??? success "Solution"

   ```sh
   # See all facts for a host
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m setup | head -100"

   # Filter specific facts
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_distribution*'"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_memtotal_mb'"
   ```

2. Create a system report template and a playbook that generates a report file on each managed host:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p templates && cat > templates/system-report.j2 << 'EOF'
   System Report: {{ inventory_hostname }}
   ======================================
   Date: {{ ansible_date_time.date }}
   OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
   CPUs: {{ ansible_processor_vcpus }}
   RAM: {{ ansible_memtotal_mb }} MB
   IP: {{ ansible_default_ipv4.address }}
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab031-facts.yml << 'EOF'
   ---
   - name: Facts Deep Dive
     hosts: all
     gather_facts: true

     tasks:
       - name: Show key facts
         ansible.builtin.debug:
           msg:
             - \"OS Family: {{ ansible_os_family }}\"
             - \"Distribution: {{ ansible_distribution }} {{ ansible_distribution_version }}\"
             - \"Architecture: {{ ansible_architecture }}\"
             - \"CPUs: {{ ansible_processor_vcpus }}\"
             - \"RAM: {{ ansible_memtotal_mb }} MB\"
             - \"IP: {{ ansible_default_ipv4.address }}\"

       - name: Generate system report
         ansible.builtin.template:
           src: templates/system-report.j2
           dest: \"/tmp/report-{{ inventory_hostname }}.txt\"
           mode: \"0644\"

       - name: Show report
         ansible.builtin.command:
           cmd: \"cat /tmp/report-{{ inventory_hostname }}.txt\"
         register: report
         changed_when: false

       - name: Print report
         ansible.builtin.debug:
           var: report.stdout_lines
   EOF
   ansible-playbook lab031-facts.yml"
   ```

3. Deploy a JSON custom fact to all managed hosts and verify it is accessible via `ansible_local`:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab031-custom-facts.yml << 'EOF'
   ---
   - name: Deploy Custom Facts
     hosts: all
     become: true

     vars:
       server_role: webserver
       team: platform

     tasks:
       - name: Create facts directory
         ansible.builtin.file:
           path: /etc/ansible/facts.d
           state: directory
           mode: \"0755\"

       - name: Deploy custom fact
         ansible.builtin.copy:
           content: |
             {
               \"role\": \"{{ server_role }}\",
               \"team\": \"{{ team }}\",
               \"managed_by\": \"ansible\"
             }
           dest: /etc/ansible/facts.d/app.json
           mode: \"0644\"

       - name: Reload facts
         ansible.builtin.setup:
           filter: ansible_local

       - name: Show custom facts
         ansible.builtin.debug:
           var: ansible_local.app
   EOF
   ansible-playbook lab031-custom-facts.yml"
   ```

4. Create custom facts in `/etc/ansible/facts.d/` on all managed nodes and verify they appear under `ansible_local`:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab031-custom-facts.yml << 'EOF'
   ---
   - name: Deploy Custom Facts
     hosts: all
     become: true

     tasks:
       - name: Ensure facts directory exists
         ansible.builtin.file:
           path: /etc/ansible/facts.d
           state: directory
           mode: \"0755\"

       - name: Deploy application custom facts
         ansible.builtin.copy:
           content: |
             [app]
             name=lab031-app
             version=2.1.0
             environment=lab
             [owner]
             team=platform
             contact=ops@example.com
           dest: /etc/ansible/facts.d/app.fact
           mode: \"0644\"

       - name: Re-gather facts to pick up custom facts
         ansible.builtin.setup:
           filter: \"ansible_local\"
         register: local_facts

       - name: Show custom facts
         ansible.builtin.debug:
           msg:
             - \"App name: {{ ansible_local.app.app.name }}\"
             - \"Version: {{ ansible_local.app.app.version }}\"
             - \"Team: {{ ansible_local.app.owner.team }}\"
   EOF
   ansible-playbook lab031-custom-facts.yml"
   ```

5. Benchmark fact gathering speed using selective `gather_subset` vs full fact gathering:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab031-benchmark.yml << 'EOF'
   ---
   - name: Benchmark - Full Fact Gathering
     hosts: all
     gather_facts: true

     tasks:
       - name: Measure time with full facts
         ansible.builtin.debug:
           msg: \"Full facts gathered for {{ inventory_hostname }} (ansible_distribution: {{ ansible_distribution }})\"
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && time ansible-playbook lab031-benchmark.yml"

   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab031-fast-facts.yml << 'EOF'
   ---
   - name: Benchmark - Selective Fact Gathering
     hosts: all
     gather_facts: false

     tasks:
       - name: Gather only OS facts
         ansible.builtin.setup:
           gather_subset:
             - distribution
             - \"!all\"
             - \"!min\"

       - name: Measure with selective facts
         ansible.builtin.debug:
           msg: \"Selective facts for {{ inventory_hostname }} (os: {{ ansible_distribution }})\"
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && time ansible-playbook lab031-fast-facts.yml"
   ```

---

## 10. Summary

- **Facts** are gathered automatically before tasks run by the `setup` module
- Key namespaces: `ansible_distribution`, `ansible_default_ipv4`, `ansible_memtotal_mb`
- **Custom facts** go in `/etc/ansible/facts.d/` as `.fact` (INI) or `.json` files and are accessible via `ansible_local`
- Enable **fact caching** in `ansible.cfg` to speed up large inventories
- Use `gather_subset` to collect only the facts you need for faster playbook runs
