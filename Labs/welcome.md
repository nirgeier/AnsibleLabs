
<!-- header start -->
<div markdown class="center">
# Ansible Labs

<img src="../assets/images/ansible-labs.png" >
</div>

---

<img src="../assets/images/tldr.png" style="width:100px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);">

!!! success "Getting Started Tip"
    Choose the preferred way to run the labs. If you encounter any issues, please contact your instructor.

<div class="grid cards" markdown style="text-align: center;border-radius: 20px;">

- ![](assets/images/docker.png)
  ```bash
  cd 000-setup && docker-compose up -d
  ```

- ![](assets/images/killercoda.png){: .height-64px}<br/><br/>
  <a target="_blank" href="https://killercoda.com/codewizard/scenario/Ansible">Launch on KillerCoda</a>

</div>

## Intro

- This tutorial is for teaching Ansible through hands-on labs designed as practical exercises.
- Each lab is packaged in its own folder and includes the files, playbooks, and assets required to complete the lab.
- Every lab folder includes a `README` that describes the lab's objectives, tasks, and how to verify the solution.
- The Ansible Labs are a series of Ansible automation exercises designed to teach players Ansible skills & features.
- The inspiration for this project is to provide practical learning experiences for Ansible.

## Pre-Requirements

- This tutorial will test your `Ansible` and `Linux` skills.
- You should be familiar with the following topics:
    - Basic Linux commands
    - Linux File system navigation
    - Basic knowledge of `Docker` (if you choose to run it with Docker)
    - Basic knowledge of YAML
- For advanced Labs: 
    - `Ansible` basics (`inventory`, `playbooks`, `modules`)
  
## Usage

{% include "../Labs/000-setup/usage.md" %}

---

!!! warning ""
    - Ensure you have the necessary permissions to run Docker commands or Ansible playbooks on your system.
    - Enjoy, and don't forget to star the project on GitHub!

## Preface

### What is Ansible?

- `Ansible` is an open-source automation tool for IT tasks such as configuration management, application deployment, and task automation. 
- `Ansible` is `Configuration Management` tool which manage the `state` of our servers, install the required packages and tools.
- Other optional use cases can be  `deployments`, `Provisioning new servers`
- The most powerful feature of `Ansible` is the ability to manage huge scale of servers regardless of their infrastructure (on prem, cloud, vm etc)
- `Ansible` uses SSH to connect to servers and execute tasks defined in YAML playbooks, making it agentless and easy to use. 
- `Ansible` is widely used for managing infrastructure, ensuring consistency, and automating repetitive processes across various environments (on-premises, cloud, VMs, etc.).

### How Ansible Works

<img src="../assets/images/ansible-architecture-diagram.png" class="border-radius-20" alt="Ansible Architecture Diagram"/>

- Ansible is an `agentless tool`.
- Ansible uses `ssh` for `pulling modules` and for managing the nodes
- Ansible is based upon `YAML` 
- An `Ansible playbook` is a file that contains a set of instructions that Ansible can use to automate tasks on remote hosts.
- `Playbooks` are written in `YAML`, a human-readable markup language. A playbook typically consists of one or more `plays`, a collection of tasks run in sequence.

---

### How Ansible Playbooks Work  

- Here’s a brief overview of how `Ansible playbooks` work:

<div class="grid cards" markdown>

- #### Playbook Structure
    * A `playbook` is composed of one or more `plays` in an ordered list. 
    
    * Each `play` executes part of the overall goal of the `playbook`, running one or more tasks. 
    * Each task calls an `Ansible` module.

- #### Playbook Execution

    * A `playbook` runs in order from top to bottom.

    * Within each `play`, tasks also run in order from top to bottom.

    * Playbooks with multiple `plays` can orchestrate multi-machine deployments.

- #### Task Execution

    * `Tasks` are executed by `modules`, each of which performs a specific task in a playbook.

    * There are thousands of `Ansible modules` that perform all kinds of IT tasks.

- #### Reusability
  
    * `Playbooks` offer a repeatable, reusable, simple configuration management and multi-machine deployment system.

    * If you need to execute a `task` with `Ansible` more than once, write a `playbook` and put it under source control.

</div>
  
- Playbooks are **one of the core features of Ansible** and tell Ansible what to execute.
  - They are used in complex scenarios.
  - They serve as frameworks of pre-written code that developers can use ad-hoc or as a starting template.
  - They can be saved, shared, or reused indefinitely, making it easier for IT teams to codify operational knowledge and ensure that the same actions are performed consistently.
  