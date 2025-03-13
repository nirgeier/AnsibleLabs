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

______________________________________________________________________

![](./resources/ansible-labs.png)

______________________________________________________________________

### Pre-Requirements

Clone the repository and start playing with it

**Option 1:** 
  - Linux machine with docker

**Option 2:** 

  [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/nirgeier/AnsibleLabs)
  
  - Clicking on the `Open in Google Cloud Shell` button.
  - It will clone the repository into free Cloud instance
  - **<kbd>CTRL</kbd> + click to open in new window** 

**Option 3:** 
  - Open the scenario in [Killercoda](https://killercoda.com/creator/scenarios/codewizard)
  - **<kbd>CTRL</kbd> + click to open in new window** 

______________________________________________________________________

### Table of contents

- [Pre-Requirements](#pre-requirements)
- [Table of contents](#table-of-contents)
- [Preface](#preface)
  - [What is Ansible?](#what-is-ansible)
- [How Ansible Works](#how-ansible-works)
- [Here’s a brief overview of how `Ansible playbooks` work:](#heres-a-brief-overview-of-how-ansible-playbooks-work)
- [Playbooks](#playbooks)
- [Labs List](#labs-list)

______________________________________________________________________

### Preface

#### What is Ansible?

- Ansible is `Configuration Management` tool which manage the `state` of our servers, install the required packages and tools.
- Other optional use cases can be  `deployments`, `Provisioning new servers`
- The most powerful feature of Ansible is the ability to manage huge scale of servers regardless of their infrastructure (on prem, cloud, vm etc)

### How Ansible Works

![](resources/ansible-architecture-diagram.png)

- Ansible is an **agentless** tool.

- Ansible uses **ssh** for pulling modules and for managing the nodes

- Ansible is based upon **`YAML`**

- An `Ansible playbook` is a file that contains a set of instructions that Ansible can use to automate tasks on remote hosts. 
- Playbooks are written in YAML, a human-readable markup language. A playbook typically consists of one or more ‘plays’, a collection of tasks run in sequence.

### Here’s a brief overview of how `Ansible playbooks` work:

- **Playbook Structure**: 
  - A playbook is composed of one or more ‘plays’ in an ordered list. Each play executes part of the overall goal of the playbook, running one or more tasks. Each task calls an Ansible module.

- **Playbook Execution**: 
  - A playbook runs in order from top to bottom. Within each play, tasks also run in order from top to bottom. Playbooks with multiple ‘plays’ can orchestrate multi-machine deployments.

- **Task Execution**: 
  - Tasks are executed by modules, each of which performs a specific task in a playbook.
  - There are thousands of Ansible modules that perform all kinds of IT tasks.

- **Reusability**: 
  - Playbooks offer a repeatable, reusable, simple configuration management and multi-machine deployment system.
  - If you need to execute a task with Ansible more than once, write a playbook and put it under source control.

### Playbooks

  - Playbooks are **one of the core features of Ansible** and tell Ansible what to execute.

    - They are used in complex scenarios.
    - They serve as frameworks of pre-written code that developers can use ad-hoc or as a starting template.
    - They can be saved, shared, or reused indefinitely, making it easier for IT teams to codify operational knowledge and ensure that the same actions are performed consistently.

______________________________________________________________________


### Labs List

<!-- Labs List start -->
| Lab                                            | Build Status                                                                                                                                                                                            |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [000-setup](/Labs/000-setup)                   | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/000-setup.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/000-setup.yaml/badge.svg"> </a>                   |
| [001-verify-ansible](/Labs/001-verify-ansible) | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/001-verify-ansible.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/001-verify-ansible.yaml/badge.svg"> </a> |
| [002-no-inventory](/Labs/002-no-inventory)     | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/002-no-inventory.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/002-no-inventory.yaml/badge.svg"> </a>     |
| [003-modules](/Labs/003-modules)               | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/003-modules.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/003-modules.yaml/badge.svg"> </a>               |
| [004-playbooks](/Labs/004-playbooks)           | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/004-playbooks.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/004-playbooks.yaml/badge.svg"> </a>           |
| [005-facts](/Labs/005-facts)                   | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/005-facts.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/005-facts.yaml/badge.svg"> </a>                   |
| [006-git](/Labs/006-git)                       | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/006-git.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/006-git.yaml/badge.svg"> </a>                       |
| [007-create-user](/Labs/007-create-user)       | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/007-create-user.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/007-create-user.yaml/badge.svg"> </a>       |
| [009-roles](/Labs/009-roles)                   | <a href=https://github.com/nirgeier/AnsibleLabs/actions/workflows/009-roles.yaml> <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/009-roles.yaml/badge.svg"> </a>                   |
