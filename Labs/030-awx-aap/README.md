---
# AWX and Ansible Automation Platform

* In this lab we explore **AWX** (open-source) and **Ansible Automation Platform (AAP)** - the enterprise web UI and REST API layer on top of Ansible.
* AWX/AAP adds RBAC, job scheduling, workflows, credential management, and a web UI to your Ansible automation.
* Everything you learn in AWX transfers directly to AAP.

## What will we learn?

- AWX vs Ansible Automation Platform (AAP) differences
- Deploying AWX with Docker Compose
- Key concepts: Organizations, Inventories, Projects, Job Templates, Workflows
- Triggering jobs via the REST API

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) and [Lab 009](../009-roles/README.md#usage) in order to have a working knowledge of Ansible playbooks and roles.

---

## 01. AWX vs Ansible Automation Platform

| Feature                    | AWX (Free)             | AAP 2.x (Commercial)           |
| -------------------------- | ---------------------- | ------------------------------ |
| Source                     | Open source (upstream) | Supported product (downstream) |
| License                    | Apache 2.0             | Red Hat subscription           |
| Support                    | Community              | Red Hat SLA                    |
| Stability                  | Bleeding edge          | Stable, enterprise-tested      |
| Execution Environments     | Yes                    | Yes                            |
| RBAC                       | Yes                    | Yes (more granular)            |
| Automation Hub integration | No                     | Yes                            |
| Ansible Lightspeed (AI)    | No                     | Yes                            |

> **NOTE:** AWX is the best way to learn AAP concepts without a Red Hat subscription. Everything you learn in AWX transfers directly to AAP.

---

## 02. Deploy AWX with Docker Compose

```sh
# Clone the AWX installer
git clone https://github.com/ansible/awx.git
cd awx/tools/docker-compose

# Generate the required configuration
make docker-compose-build

# Start AWX
docker-compose up -d

# Wait for AWX to initialize (2-5 minutes)
docker-compose logs -f awx_1

# Access at: http://localhost/#/login
# Default credentials: admin / password
```

---

## 03. AWX/AAP Core Concepts

### Organizations

```
Organizations
└── Teams (groups of users)
    └── Users
```

- **Organization**: Logical container for all automation resources
- **Team**: A group of users with shared permissions within an org
- **User**: Has roles assigned at org, project, inventory, or credential level

### Inventories

- Same concept as Ansible inventory files, but stored in the database
- Support smart inventories (dynamic queries)
- Can sync from SCM (Git), cloud (AWS EC2), or custom sources

### Projects

- A link to a **Git repository** containing playbooks
- AWX automatically pulls from Git when a job runs
- Supports branches, tags, and specific commits

### Credentials

- Securely store SSH keys, vault passwords, cloud credentials, API tokens
- Credentials are never exposed in plaintext after creation
- Types: Machine (SSH), Vault, Source Control, Cloud (AWS/Azure/GCP), etc.

### Job Templates

- Defines HOW to run a playbook:
  - Which **project** (Git repo)
  - Which **playbook** file
  - Which **inventory**
  - Which **credentials**
  - Extra variables, tags, verbosity

### Workflows

- Chain multiple Job Templates together
- Conditional execution (on success, on failure)
- Parallel and sequential steps
- Approval nodes for human gates

---

## 04. REST API

AWX/AAP has a full REST API at `/api/v2/`:

```sh
# Set up credentials
export AWX_URL="http://localhost"

# List all job templates
curl -u admin:password "$AWX_URL/api/v2/job_templates/" | python3 -m json.tool

# Launch a job template
curl -u admin:password -X POST \
  "$AWX_URL/api/v2/job_templates/1/launch/" \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": {"env": "staging", "version": "2.0.0"}}'

# Check job status
curl -u admin:password "$AWX_URL/api/v2/jobs/42/" | python3 -m json.tool

# List all inventories
curl -u admin:password "$AWX_URL/api/v2/inventories/"
```

---

## 05. Using `awxkit` - Python Client

```sh
# Install the client
pip install awxkit

# Configure
export TOWER_HOST=http://localhost
export TOWER_USERNAME=admin
export TOWER_PASSWORD=password

# List resources
awx job_templates list
awx inventories list
awx credentials list

# Launch a job
awx job_templates launch --id 1 \
  --extra_vars '{"env": "staging"}' \
  --monitor
```

---

## 06. Key AWX Setup Workflow

```
1. Create an Organization
         ↓
2. Add Credentials
   - Machine credential (SSH key)
   - Vault credential (vault password)
   - SCM credential (GitHub token)
         ↓
3. Create a Project
   - Point to your Git repository
   - Select SCM credential
         ↓
4. Create an Inventory
   - Add hosts manually or from a source
   - Set host/group variables
         ↓
5. Create a Job Template
   - Select Project, Playbook, Inventory, Credentials
   - Set extra vars, tags, verbosity
         ↓
6. Launch the Job Template
   - Watch real-time output
   - Review job history
         ↓
7. (Optional) Create Workflows
   - Chain multiple Job Templates
   - Add approval gates and conditional paths
```

---

## 07. Execution Environments (EEs)

```yaml
# execution-environment.yml
---
version: 3

dependencies:
  galaxy: requirements.yml
  python: requirements.txt
  system: bindep.txt

images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel9:latest
```

```sh
# Build an Execution Environment
pip install ansible-builder

# Build the EE
ansible-builder build \
  --tag myorg/my-ee:1.0.0 \
  --file execution-environment.yml

# Push to registry
docker push myorg/my-ee:1.0.0

# Use with ansible-navigator
ansible-navigator run site.yml \
  --execution-environment-image myorg/my-ee:1.0.0
```

---

## 08. `ansible-navigator` - Run Locally with EEs

```sh
# Install
pip install ansible-navigator

# Run a playbook in an EE (interactive TUI)
ansible-navigator run site.yml \
  --execution-environment-image quay.io/ansible/awx-ee:latest \
  --inventory inventory/ \
  --mode interactive

# Non-interactive (same as ansible-playbook)
ansible-navigator run site.yml --mode stdout

# Browse artifacts after the run
ansible-navigator replay artifacts/
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 09. Hands-on

1. Review the AWX API endpoints (if AWX is available locally):

   ??? success "Solution"

   ```sh
   curl -u admin:password http://localhost/api/v2/ | python3 -m json.tool
   curl -u admin:password http://localhost/api/v2/job_templates/ | python3 -m json.tool
   ```

2. Create and run a playbook that simulates an AWX Job Template deployment, passing `app_version` and `env` as extra variables:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > awx-simulation.yml << 'EOF'
   ---
   - name: AWX-style Deployment Job
     hosts: all
     gather_facts: true

     vars:
       app_version: \"{{ app_version | default('1.0.0') }}\"
       env: \"{{ env | default('development') }}\"

     tasks:
       - name: Pre-flight checks
         ansible.builtin.debug:
           msg:
             - \"Job Template: Deploy Application\"
             - \"Version: {{ app_version }}\"
             - \"Environment: {{ env }}\"
             - \"Host: {{ inventory_hostname }}\"

       - name: Deploy application
         ansible.builtin.copy:
           content: |
             version={{ app_version }}
             environment={{ env }}
             deployed_at={{ ansible_date_time.iso8601 }}
           dest: /tmp/awx-deployment.txt
           mode: \"0644\"

       - name: Verify deployment
         ansible.builtin.command:
           cmd: cat /tmp/awx-deployment.txt
         register: deploy_info
         changed_when: false

       - name: Report success
         ansible.builtin.debug:
           var: deploy_info.stdout_lines
   EOF
   ansible-playbook awx-simulation.yml -e 'app_version=2.0.0 env=staging'"
   ```

3. Install `ansible-navigator` and attempt to run the simulation playbook inside the AWX official Execution Environment:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && pip install ansible-navigator && ansible-navigator run awx-simulation.yml --execution-environment-image quay.io/ansible/awx-ee:latest --mode stdout -e 'app_version=2.0.0 env=staging' 2>/dev/null || echo 'EE requires Docker - demonstrating concept'"
   ```

---

## 10. Summary

- **AWX** is the open-source upstream UI for Ansible; **AAP** is the supported Red Hat enterprise version
- Core hierarchy: Organizations → Projects → Inventories → Credentials → Job Templates → Workflows
- AWX stores all credentials securely - no plaintext secrets in playbooks
- The **REST API** allows programmatic job execution from any external system
- **Execution Environments (EEs)** are containerized runtimes that eliminate "works on my machine" issues
- `ansible-navigator` runs playbooks inside EEs locally for consistent, reproducible results
