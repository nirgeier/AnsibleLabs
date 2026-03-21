---
# Cloud Modules

* In this lab we use Ansible's cloud modules to provision and manage infrastructure on AWS, Azure, and GCP.
* Ansible can replace Terraform for simpler provisioning tasks, or complement it as the configuration layer after infrastructure is created.
* Dynamic inventory plugins allow Ansible to auto-discover cloud resources by tags.

## What will we learn?

- Provisioning EC2 instances with `amazon.aws`
- Managing Azure resources with `azure.azcollection`
- Using cloud inventories for dynamic host discovery
- Idempotent cloud resource management

---

## Prerequisites

- Complete [Lab 018](../018-galaxy-collections/README.md#usage) and [Lab 019](../019-ansible-vault/README.md#usage) in order to have a working knowledge of Galaxy collections and Ansible Vault.

---

## 01. Install Cloud Collections

```sh
# Install cloud collections individually
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection install amazon.aws"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection install azure.azcollection"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection install google.cloud"

# Or via requirements.yml
docker exec ansible-controller sh -c "cd /labs-scripts && cat > requirements.yml << 'EOF'
collections:
  - name: amazon.aws
    version: \">=6.0.0\"
  - name: azure.azcollection
    version: \">=1.19.0\"
  - name: community.aws
    version: \">=7.0.0\"
EOF
ansible-galaxy collection install -r requirements.yml"
```

---

## 02. AWS Credentials Setup

```sh
# Method 1: Environment variables
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"

# Method 2: AWS credentials file
mkdir -p ~/.aws
cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EOF

# Method 3: Ansible Vault (recommended for CI/CD)
# Store credentials in a vault-encrypted variable file
```

> **NOTE:** For production use, prefer IAM roles or managed identities over long-lived access keys.

---

## 03. AWS EC2 Instances

```yaml
---
- name: Provision AWS Infrastructure
  hosts: localhost
  gather_facts: false
  collections:
    - amazon.aws

  vars:
    aws_region: us-east-1
    instance_type: t3.micro
    ami_id: ami-0c55b159cbfafe1f0 # Ubuntu 22.04 us-east-1
    key_name: my-ansible-key

  tasks:
    # Create a VPC
    - name: Create VPC
      amazon.aws.ec2_vpc_net:
        name: ansible-vpc
        cidr_block: "10.0.0.0/16"
        region: "{{ aws_region }}"
        tags:
          Environment: lab
          ManagedBy: ansible
      register: vpc

    # Create a subnet
    - name: Create public subnet
      amazon.aws.ec2_vpc_subnet:
        vpc_id: "{{ vpc.vpc.id }}"
        cidr: "10.0.1.0/24"
        az: "{{ aws_region }}a"
        region: "{{ aws_region }}"
        map_public: true
        tags:
          Name: ansible-public-subnet
      register: subnet

    # Create security group
    - name: Create security group
      amazon.aws.ec2_security_group:
        name: ansible-sg
        description: Security group for Ansible lab
        vpc_id: "{{ vpc.vpc.id }}"
        region: "{{ aws_region }}"
        rules:
          - proto: tcp
            ports: [22]
            cidr_ip: 0.0.0.0/0
            rule_desc: SSH access
          - proto: tcp
            ports: [80, 443]
            cidr_ip: 0.0.0.0/0
            rule_desc: HTTP/HTTPS access
        tags:
          ManagedBy: ansible
      register: sg

    # Launch EC2 instances
    - name: Launch EC2 instances
      amazon.aws.ec2_instance:
        name: "web-server-{{ item }}"
        key_name: "{{ key_name }}"
        instance_type: "{{ instance_type }}"
        image_id: "{{ ami_id }}"
        region: "{{ aws_region }}"
        vpc_subnet_id: "{{ subnet.subnet.id }}"
        security_group: "{{ sg.group_id }}"
        network:
          assign_public_ip: true
        state: running
        wait: true
        tags:
          Name: "web-server-{{ item }}"
          Environment: lab
          Role: webserver
          ManagedBy: ansible
      loop:
        - "01"
        - "02"
      register: ec2_instances

    - name: Show instance IPs
      ansible.builtin.debug:
        msg: "Instance {{ item.item }}: {{ item.instances[0].public_ip_address }}"
      loop: "{{ ec2_instances.results }}"
```

---

## 04. AWS S3 Buckets

```yaml
tasks:
  - name: Create S3 bucket
    amazon.aws.s3_bucket:
      name: "my-ansible-bucket-{{ ansible_date_time.epoch }}"
      region: "{{ aws_region }}"
      versioning: true
      encryption: AES256
      tags:
        ManagedBy: ansible
      state: present

  - name: Upload file to S3
    amazon.aws.aws_s3:
      bucket: my-ansible-bucket
      object: /configs/app.conf
      src: /local/app.conf
      mode: put
      region: "{{ aws_region }}"

  - name: Download file from S3
    amazon.aws.aws_s3:
      bucket: my-ansible-bucket
      object: /configs/app.conf
      dest: /etc/app/app.conf
      mode: get
      region: "{{ aws_region }}"
```

---

## 05. AWS EC2 Dynamic Inventory

```yaml
# aws_ec2.yml - Dynamic inventory for AWS
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1

filters:
  instance-state-name: running
  tag:ManagedBy: ansible

keyed_groups:
  - key: tags.Environment
    prefix: env
  - key: tags.Role
    prefix: role

compose:
  ansible_host: public_ip_address
  ansible_user: "'ubuntu'"
```

```sh
# Use the dynamic inventory
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-inventory -i aws_ec2.yml --graph"

# Run against all web servers tagged in AWS
docker exec ansible-controller sh -c "cd /labs-scripts && ansible -i aws_ec2.yml role_webserver -m ping"
```

---

## 06. Azure Resources

```yaml
---
- name: Provision Azure Infrastructure
  hosts: localhost
  gather_facts: false

  vars:
    resource_group: ansible-lab-rg
    location: eastus
    vnet_name: ansible-vnet

  tasks:
    - name: Create resource group
      azure.azcollection.azure_rm_resourcegroup:
        name: "{{ resource_group }}"
        location: "{{ location }}"
        tags:
          ManagedBy: ansible
          Environment: lab

    - name: Create virtual network
      azure.azcollection.azure_rm_virtualnetwork:
        resource_group: "{{ resource_group }}"
        name: "{{ vnet_name }}"
        address_prefixes: "10.0.0.0/16"

    - name: Create subnet
      azure.azcollection.azure_rm_subnet:
        resource_group: "{{ resource_group }}"
        virtual_network: "{{ vnet_name }}"
        name: default
        address_prefix: "10.0.1.0/24"

    - name: Create VM
      azure.azcollection.azure_rm_virtualmachine:
        resource_group: "{{ resource_group }}"
        name: ansible-vm-01
        vm_size: Standard_B1s
        admin_username: azureuser
        ssh_password_enabled: false
        ssh_public_keys:
          - path: /home/azureuser/.ssh/authorized_keys
            key_data: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        image:
          offer: UbuntuServer
          publisher: Canonical
          sku: "22.04-LTS"
          version: latest
        tags:
          ManagedBy: ansible
```

---

## 07. Terminate and Clean Up Resources

```yaml
tasks:
  # Terminate EC2 instances by tag
  - name: Terminate lab instances
    amazon.aws.ec2_instance:
      state: terminated
      region: "{{ aws_region }}"
      filters:
        tag:Environment: lab
        tag:ManagedBy: ansible

  # Delete security group
  - name: Delete security group
    amazon.aws.ec2_security_group:
      name: ansible-sg
      region: "{{ aws_region }}"
      state: absent

  # Delete S3 bucket (with all objects)
  - name: Delete S3 bucket
    amazon.aws.s3_bucket:
      name: my-ansible-bucket
      state: absent
      force: true # Delete non-empty bucket
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 08. Hands-on

1. Simulate a cloud provisioning workflow locally - create a playbook that loops over a list of instances and generates a simulated inventory file:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab035-cloud-sim.yml << 'EOF'
   ---
   - name: Cloud Infrastructure Simulation
     hosts: localhost
     gather_facts: false

     vars:
       instances:
         - { name: web-01, role: webserver, zone: us-east-1a }
         - { name: web-02, role: webserver, zone: us-east-1b }
         - { name: db-01,  role: database,  zone: us-east-1a }

     tasks:
       - name: Simulate instance creation
         ansible.builtin.debug:
           msg: \"Creating instance {{ item.name }} ({{ item.role }}) in {{ item.zone }}\"
         loop: \"{{ instances }}\"

       - name: Create simulated inventory
         ansible.builtin.copy:
           content: |
             [webservers]
             {% for i in instances | selectattr('role', 'eq', 'webserver') %}
             {{ i.name }}.example.com
             {% endfor %}

             [databases]
             {% for i in instances | selectattr('role', 'eq', 'database') %}
             {{ i.name }}.example.com
             {% endfor %}

             [all:vars]
             ansible_user=ec2-user
             ansible_connection=local
           dest: /tmp/cloud-inventory
           mode: \"0644\"

       - name: Show inventory structure
         ansible.builtin.command:
           cmd: cat /tmp/cloud-inventory
         register: inv_content
         changed_when: false

       - name: Print inventory
         ansible.builtin.debug:
           var: inv_content.stdout_lines
   EOF
   ansible-playbook lab035-cloud-sim.yml"
   ```

2. Install the `amazon.aws` collection and view the documentation for the `ec2_instance` and `s3_bucket` modules:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection install amazon.aws --upgrade"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-doc amazon.aws.ec2_instance | head -40"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-doc amazon.aws.s3_bucket | head -30"
   ```

3. Create a playbook that generates a simulated AWS inventory report - loops over instances and prints a formatted table with name, role, zone, and simulated IP:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab035-inventory-report.yml << 'EOF'
   ---
   - name: Cloud Inventory Report
     hosts: localhost
     gather_facts: false

     vars:
       cloud_instances:
         - { name: web-01, role: webserver, zone: us-east-1a, ip: \"10.0.1.10\", state: running }
         - { name: web-02, role: webserver, zone: us-east-1b, ip: \"10.0.1.11\", state: running }
         - { name: api-01, role: api,       zone: us-east-1a, ip: \"10.0.2.10\", state: running }
         - { name: db-01,  role: database,  zone: us-east-1a, ip: \"10.0.3.10\", state: running }
         - { name: db-02,  role: database,  zone: us-east-1b, ip: \"10.0.3.11\", state: stopped }

     tasks:
       - name: Print inventory header
         ansible.builtin.debug:
           msg: \"{{ '%-12s %-12s %-14s %-15s %s' | format('NAME', 'ROLE', 'ZONE', 'IP', 'STATE') }}\"

       - name: Print each instance
         ansible.builtin.debug:
           msg: \"{{ '%-12s %-12s %-14s %-15s %s' | format(item.name, item.role, item.zone, item.ip, item.state) }}\"
         loop: \"{{ cloud_instances }}\"

       - name: Count by role
         ansible.builtin.set_fact:
           role_counts: \"{{ cloud_instances | groupby('role') | map('list') | map(attribute=1) | map('length') | list }}\"

       - name: Summary stats
         ansible.builtin.debug:
           msg:
             - \"Total instances: {{ cloud_instances | length }}\"
             - \"Running: {{ cloud_instances | selectattr('state', 'eq', 'running') | list | length }}\"
             - \"Stopped: {{ cloud_instances | selectattr('state', 'eq', 'stopped') | list | length }}\"
             - \"Webservers: {{ cloud_instances | selectattr('role', 'eq', 'webserver') | list | length }}\"
             - \"Databases: {{ cloud_instances | selectattr('role', 'eq', 'database') | list | length }}\"
   EOF
   ansible-playbook lab035-inventory-report.yml"
   ```

4. Write a playbook that generates Terraform-like destroy plan output - lists all resources that would be deleted before actually deleting them:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab035-destroy-plan.yml << 'EOF'
   ---
   - name: Cloud Resource Destroy Plan
     hosts: localhost
     gather_facts: false

     vars:
       environment: lab
       resources_to_destroy:
         - { type: ec2_instance, name: web-01, id: i-0abc123, env: lab }
         - { type: ec2_instance, name: web-02, id: i-0abc124, env: lab }
         - { type: security_group, name: ansible-sg, id: sg-0abc125, env: lab }
         - { type: s3_bucket, name: my-ansible-bucket, id: my-ansible-bucket, env: lab }

     tasks:
       - name: Show destroy plan header
         ansible.builtin.debug:
           msg:
             - \"=== DESTROY PLAN (environment={{ environment }}) ===\"
             - \"The following resources will be PERMANENTLY DELETED:\"

       - name: List resources to be destroyed
         ansible.builtin.debug:
           msg: \"  [-] {{ item.type }}: {{ item.name }} ({{ item.id }})\"
         loop: \"{{ resources_to_destroy | selectattr('env', 'eq', environment) | list }}\"

       - name: Confirm destruction count
         ansible.builtin.debug:
           msg: \"Total resources to destroy: {{ resources_to_destroy | length }}\"

       - name: Simulate destroy (dry-run)
         ansible.builtin.debug:
           msg: \"Would terminate: {{ item.type }} {{ item.name }} with state: absent\"
         loop: \"{{ resources_to_destroy }}\"
         when: not ansible_check_mode

       - name: Reminder to use check mode first
         ansible.builtin.debug:
           msg: \"TIP: Always run with --check first: ansible-playbook destroy.yml -e 'env=lab' --check\"
   EOF
   ansible-playbook lab035-destroy-plan.yml"
   ```

5. Demonstrate dynamic inventory by creating a static YAML inventory file in AWS dynamic inventory format, then use `ansible-inventory` to query it:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab035-dynamic-inv.yml << 'EOF'
   ---
   # Simulated AWS EC2 dynamic inventory (YAML format)
   all:
     children:
       env_lab:
         children:
           role_webserver:
             hosts:
               web-01:
                 ansible_host: 10.0.1.10
                 ansible_user: ec2-user
                 ec2_instance_type: t3.micro
                 ec2_region: us-east-1
                 tags:
                   Environment: lab
                   Role: webserver
                   ManagedBy: ansible
               web-02:
                 ansible_host: 10.0.1.11
                 ansible_user: ec2-user
                 ec2_instance_type: t3.micro
                 ec2_region: us-east-1
                 tags:
                   Environment: lab
                   Role: webserver
                   ManagedBy: ansible
           role_database:
             hosts:
               db-01:
                 ansible_host: 10.0.3.10
                 ansible_user: ec2-user
                 ec2_instance_type: t3.small
                 ec2_region: us-east-1
                 tags:
                   Environment: lab
                   Role: database
                   ManagedBy: ansible
   EOF"

   # Query the dynamic inventory
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-inventory -i lab035-dynamic-inv.yml --graph"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-inventory -i lab035-dynamic-inv.yml --list | python3 -m json.tool | head -40"
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-inventory -i lab035-dynamic-inv.yml --host web-01"
   ```

---

## 09. Summary

- `amazon.aws`, `azure.azcollection`, and `google.cloud` provide comprehensive cloud module coverage
- Cloud resources should be tagged with `ManagedBy: ansible` and `Environment` for easy targeting and cleanup
- **Dynamic inventory plugins** (`aws_ec2.yml`) auto-discover instances and group them by tags
- Always clean up cloud resources using `state: absent` or `state: terminated` to avoid costs
- Store cloud credentials in **Ansible Vault** or use IAM roles/managed identities instead of long-lived keys
- Use `register` to capture created resource IDs (VPC, subnet, SG) for use in subsequent tasks
