<a href="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-000.yaml" target="_blank">
  <img src="https://github.com/nirgeier/AnsibleLabs/actions/workflows/Lab-000.yaml/badge.svg" alt="Build Status">
</a>

---

# Lab 000 - Setup

- In this lab we will define and build docker containers which will be used in the next labs.
- The lab structure consists of an Ansible controller & 3 Linux servers, all set inside docker containers.

---

## 01. Usage

{% include "./usage.md" %}



## 03. Core concepts

- Create `Ansible Controller` container, which will be used to manage the other containers
- `SSH Keys` - The SSH keys will be generated and mounted into the containers
- Initialize servers: Set up runtime directories, start demo containers via `Docker Compose`, verify `Ansible` installation, extract `SSH keys` from servers, configure known hosts, check SSH services, and test SSH connections to each Linux server

---

## 04. Verify containers

```bash
$ docker ps -a


# Expected output

IMAGE                       PORTS                                                                  NAMES
---------------------------------------------------------------------------------------------------------------------
nirgeier/ansible-controller 22/tcp                                                                 ansible-controller
nirgeier/linux-server       0.0.0.0:3001->22/tcp, 0.0.0.0:5001->5000/tcp, 0.0.0.0:8081->8080/tcp   linux-server-1
nirgeier/linux-server       0.0.0.0:3002->22/tcp, 0.0.0.0:5002->5000/tcp, 0.0.0.0:8082->8080/tcp   linux-server-2
nirgeier/linux-server       0.0.0.0:3003->22/tcp, 0.0.0.0:5003->5000/tcp, 0.0.0.0:8083->8080/tcp   linux-server-3
```

---
## 05. Next steps

- Proceed to [Lab 001 - Verify Ansible configuration](../001-verify-ansible/README.md) to start using Ansible with the configured environment.
- Don't forget to check the logs for any errors or issues during the setup process.
- If you encounter any problems, refer to the troubleshooting section or open an issue on the GitHub repository.
- Enjoy learning Ansible!
  