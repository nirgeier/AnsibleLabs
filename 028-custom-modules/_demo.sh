#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 028 - Custom Ansible Modules${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# Step 1: Create the library/ directory
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create the library/ directory${COLOR_OFF}"
echo -e "${GREEN}$ mkdir -p library${COLOR_OFF}"
docker exec ansible-controller sh -c "mkdir -p /labs-scripts/library"

# Step 2: Create the custom Python module
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: Create custom module library/system_info.py${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/library/system_info.py << 'PYEOF'
#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
module: system_info
short_description: Gather system information
description:
  - Returns hostname, uptime, and disk usage from the target host.
  - This module always returns changed=false (read-only).
version_added: "1.0.0"
author:
  - Lab 028 Demo
options: {}
'''

EXAMPLES = '''
- name: Get system info
  system_info:
  register: info

- name: Show system info
  ansible.builtin.debug:
    var: info
'''

RETURN = '''
hostname:
  description: The hostname of the managed node
  type: str
  returned: always
uptime:
  description: Human-readable uptime string
  type: str
  returned: always
disk_total:
  description: Total disk size of the root filesystem
  type: str
  returned: always
disk_used:
  description: Used disk space on the root filesystem
  type: str
  returned: always
disk_avail:
  description: Available disk space on the root filesystem
  type: str
  returned: always
'''

from ansible.module_utils.basic import AnsibleModule
import subprocess
import socket


def main():
    module = AnsibleModule(argument_spec={}, supports_check_mode=True)
    try:
        hostname = socket.gethostname()
        try:
            uptime = subprocess.check_output(['uptime', '-p'], text=True).strip()
        except Exception:
            uptime = subprocess.check_output(['uptime'], text=True).strip()
        df = subprocess.check_output(['df', '-h', '/'], text=True).split('\n')[1].split()
        module.exit_json(
            changed=False,
            hostname=hostname,
            uptime=uptime,
            disk_total=df[1],
            disk_used=df[2],
            disk_avail=df[3]
        )
    except Exception as e:
        module.fail_json(msg=str(e))


if __name__ == '__main__':
    main()
PYEOF"

echo -e "${GREEN}$ cat library/system_info.py${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/library/system_info.py"

# Step 3: Create the playbook that uses the custom module
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Create playbook lab028-custom.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/lab028-custom.yml << 'EOF'
---
- name: Custom Module Demo - System Info
  hosts: all
  gather_facts: false

  tasks:
    - name: Gather system info using custom module
      system_info:
      register: sys_info

    - name: Show system hostname
      ansible.builtin.debug:
        msg: \"Hostname: {{ sys_info.hostname }}\"

    - name: Show system uptime
      ansible.builtin.debug:
        msg: \"Uptime: {{ sys_info.uptime }}\"

    - name: Show disk usage
      ansible.builtin.debug:
        msg: \"Disk - Total: {{ sys_info.disk_total }}, Used: {{ sys_info.disk_used }}, Available: {{ sys_info.disk_avail }}\"
EOF"

echo -e "${GREEN}$ cat lab028-custom.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/lab028-custom.yml"

# Step 4: Run the playbook
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Run the playbook with the custom module${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab028-custom.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab028-custom.yml"

# Step 5: Show module documentation
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: Show module documentation${COLOR_OFF}"
echo -e "${GREEN}$ ansible-doc system_info${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-doc system_info || true"

# Step 6: Show the library directory structure
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 6: Show the library directory structure${COLOR_OFF}"
echo -e "${GREEN}$ ls -la library/${COLOR_OFF}"
docker exec ansible-controller sh -c "ls -la /labs-scripts/library/"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 028 - Complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
