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
echo -e "${CYAN}Lab 024 - Ansible Lint${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# Step 1: Install ansible-lint
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${GREEN}$ pip3 install ansible-lint${COLOR_OFF}"
docker exec ansible-controller sh -c "pip3 install ansible-lint --quiet"

echo -e ""
echo -e "${GREEN}$ ansible-lint --version${COLOR_OFF}"
docker exec ansible-controller sh -c "ansible-lint --version"

# Step 2: Create a BAD playbook with violations
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Creating a BAD playbook (bad-playbook.yml) with lint violations...${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/bad-playbook.yml << 'EOF'
---
- name: bad playbook example
  hosts: all
  become: yes

  tasks:
    - apt:
        name: curl
        state: present

    - shell: echo \"hello\" >> /tmp/test.txt

    - copy:
        src: /tmp/test.txt
        dest: /tmp/test2.txt
EOF"

echo -e ""
echo -e "${GREEN}$ cat bad-playbook.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat bad-playbook.yml"

# Step 3: Run ansible-lint on the bad playbook (expect violations)
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Running ansible-lint on the BAD playbook (violations expected):${COLOR_OFF}"
echo -e "${GREEN}$ ansible-lint bad-playbook.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint bad-playbook.yml || true"

# Step 4: Create a GOOD playbook following best practices
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Creating a GOOD playbook (good-playbook.yml) following best practices...${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/good-playbook.yml << 'EOF'
---
- name: Good playbook example
  hosts: all
  become: true

  tasks:
    - name: Install curl
      ansible.builtin.apt:
        name: curl
        state: present

    - name: Write to test file
      ansible.builtin.shell:
        cmd: \"echo 'hello' >> /tmp/test.txt\"
      changed_when: true

    - name: Copy test file
      ansible.builtin.copy:
        src: /tmp/test.txt
        dest: /tmp/test2.txt
        mode: \"0644\"
        remote_src: true
EOF"

echo -e ""
echo -e "${GREEN}$ cat good-playbook.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat good-playbook.yml"

# Step 5: Run ansible-lint on the good playbook (should pass)
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Running ansible-lint on the GOOD playbook:${COLOR_OFF}"
echo -e "${GREEN}$ ansible-lint good-playbook.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint good-playbook.yml || true"

# Step 6: Syntax check the good playbook
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Running syntax check on the GOOD playbook:${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook good-playbook.yml --syntax-check${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook good-playbook.yml --syntax-check"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 024 - Complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
