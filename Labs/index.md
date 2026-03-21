# Ansible Labs

## 📋 Lab Overview

- Welcome to the hands-on Ansible labs!
- This comprehensive series of 36 labs guides you from basic setup through advanced topics like custom modules, CI/CD integration, security hardening, and cloud provisioning.

---

{% include "./assets/partials/usage.md" %}

---

## 🗂️ Available Labs

### Beginner Track - Foundation

| Lab                                 | Topic          | Description                                                                         |
| ----------------------------------- | -------------- | ----------------------------------------------------------------------------------- |
| [000](000-setup/README.md)          | Setup          | Set up the lab environment with an Ansible controller and 3 Linux servers in Docker |
| [001](001-verify-ansible/README.md) | Verify Ansible | Create and test `ansible.cfg`, `inventory`, and `ssh.config` files                  |
| [002](002-no-inventory/README.md)   | No Inventory   | Understand inventory by showing what happens without it                             |
| [003](003-modules/README.md)        | Modules        | Learn about Ansible modules and ad-hoc commands                                     |
| [004](004-playbooks/README.md)      | Playbooks      | Introduction to Ansible playbooks, structure, and basic usage                       |

### Intermediate Track - Core Skills

| Lab                                          | Topic                     | Description                                              |
| -------------------------------------------- | ------------------------- | -------------------------------------------------------- |
| [005](005-facts/README.md)                   | Facts                     | Gather and use Ansible facts in playbooks                |
| [006](006-git/README.md)                     | Git                       | Create a playbook to install Git and clone repositories  |
| [007](007-create-user/README.md)             | Create User               | Create a playbook for creating users on remote systems   |
| [008](008-challenges/README.md)              | Challenges                | Challenge lab combining user creation and Git operations |
| [009](009-roles/README.md)                   | Roles                     | Ansible roles - structure, creation, and usage           |
| [010](010-loops-and-conditionals/README.md)  | Loops & Conditionals      | Loops and conditional statements in playbooks            |
| [011](011-jinja-templating/README.md)        | Jinja2 Templating         | Jinja2 for dynamic configuration files                   |
| [012](012-host-group-variables/README.md)    | Host & Group Variables    | `host_vars/`, `group_vars/`, and variable precedence     |
| [013](013-adhoc-commands/README.md)          | Ad-Hoc Commands           | Run one-off tasks without writing a playbook             |
| [014](014-playbook-variables/README.md)      | Playbook Variables        | Define, pass, register, and transform variables          |
| [015](015-handlers-blocks/README.md)         | Handlers & Blocks         | Event-driven task execution and error handling           |
| [016](016-file-modules/README.md)            | File Modules              | `copy`, `template`, `lineinfile`, `blockinfile`, `fetch` |
| [017](017-package-service-modules/README.md) | Package & Service Modules | `apt`, `yum`, `package`, `pip`, `service`, `systemd`     |
| [018](018-galaxy-collections/README.md)      | Galaxy & Collections      | Ansible Galaxy, Collections, and FQCNs                   |
| [019](019-ansible-vault/README.md)           | Ansible Vault             | Encrypt secrets with Ansible Vault                       |
| [020](020-tags/README.md)                    | Tags                      | Control task execution with tags                         |

### Advanced Track - Expert Topics

| Lab                                      | Topic                  | Description                                             |
| ---------------------------------------- | ---------------------- | ------------------------------------------------------- |
| [021](021-ansible-docker/README.md)      | Ansible with Docker    | Manage Docker containers, images, networks, and Compose |
| [022](022-debugging/README.md)           | Debugging              | `debug` module, verbosity, check mode, debugger keyword |
| [023](023-idempotency/README.md)         | Idempotency            | Write idempotent tasks and verify with check mode       |
| [024](024-ansible-lint/README.md)        | Ansible Lint           | Code quality with `ansible-lint` and Molecule           |
| [025](025-cicd-jenkins/README.md)        | CI/CD - Jenkins        | Integrate Ansible with Jenkins pipelines                |
| [026](026-cicd-github-actions/README.md) | CI/CD - GitHub Actions | Run Ansible via GitHub Actions workflows                |
| [027](027-cicd-gitlab/README.md)         | CI/CD - GitLab CI      | Integrate Ansible with GitLab CI/CD                     |
| [028](028-custom-modules/README.md)      | Custom Modules         | Write custom Ansible modules in Python                  |
| [029](029-advanced-execution/README.md)  | Advanced Execution     | Rolling updates, delegation, `serial`, `run_once`       |
| [030](030-awx-aap/README.md)             | AWX & AAP              | AWX and Ansible Automation Platform overview            |
| [031](031-facts-deep-dive/README.md)     | Facts Deep Dive        | Custom facts, fact caching, and selective gathering     |
| [032](032-plugins/README.md)             | Plugins                | Lookup, filter, and callback plugins                    |
| [033](033-best-practices/README.md)      | Best Practices         | Project structure, naming conventions, performance      |
| [034](034-security-hardening/README.md)  | Security Hardening     | SSH hardening, firewall, auditd, sysctl                 |
| [035](035-cloud-modules/README.md)       | Cloud Modules          | AWS EC2, S3, Azure, dynamic cloud inventory             |

---

## 🎯 Learning Paths

### 🟢 Beginner Path

Start here if you're new to Ansible:

1. [Lab 000: Setup](000-setup/README.md)
2. [Lab 001: Verify Ansible](001-verify-ansible/README.md)
3. [Lab 002: No Inventory](002-no-inventory/README.md)
4. [Lab 003: Modules](003-modules/README.md)
5. [Lab 004: Playbooks](004-playbooks/README.md)

### 🟡 Intermediate Path

For those comfortable with the basics:

1. [Lab 005: Facts](005-facts/README.md)
2. [Lab 009: Roles](009-roles/README.md)
3. [Lab 010: Loops & Conditionals](010-loops-and-conditionals/README.md)
4. [Lab 011: Jinja2 Templating](011-jinja-templating/README.md)
5. [Lab 014: Playbook Variables](014-playbook-variables/README.md)
6. [Lab 015: Handlers & Blocks](015-handlers-blocks/README.md)
7. [Lab 019: Ansible Vault](019-ansible-vault/README.md)
8. [Lab 020: Tags](020-tags/README.md)

### 🔴 Advanced Path

For experienced Ansible engineers:

1. [Lab 021: Ansible with Docker](021-ansible-docker/README.md)
2. [Lab 024: Ansible Lint](024-ansible-lint/README.md)
3. [Lab 025: CI/CD Jenkins](025-cicd-jenkins/README.md)
4. [Lab 026: CI/CD GitHub Actions](026-cicd-github-actions/README.md)
5. [Lab 028: Custom Modules](028-custom-modules/README.md)
6. [Lab 029: Advanced Execution](029-advanced-execution/README.md)
7. [Lab 033: Best Practices](033-best-practices/README.md)
8. [Lab 034: Security Hardening](034-security-hardening/README.md)
9. [Lab 035: Cloud Modules](035-cloud-modules/README.md)

---

## 💡 Tips for Success

- **Take your time**: Don't rush through the labs - understanding beats speed
- **Run playbooks twice**: Check for `changed=0` on the second run (idempotency)
- **Read the error**: Ansible errors are usually very descriptive - read them carefully
- **Use `-vvv`**: Add verbosity when stuck to see SSH details and module output
- **Experiment**: Modify examples, break things, fix them - that's how you learn
- **Commit your work**: Use Git to track your playbooks as they evolve

## 🚀 Get Started

Ready to begin? Start with [Lab 000: Setup](000-setup/README.md)!
