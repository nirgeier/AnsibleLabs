#!/bin/bash

set -euo pipefail

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Get the current directory of our lab
CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 >/dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 >/dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 008 - Challenges${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# -------------------------------------------------------
# Challenge 1 - Create user per hostname
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[CHALLENGE 1] Create a user named after each hostname${COLOR_OFF}"
echo -e "${GREEN}\$ ansible-playbook 01-solution-create-user.yaml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

cp "$CURRENT_DIR/01-solution-create-user.yaml" "$RUNTIME_FOLDER/labs-scripts/"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook 01-solution-create-user.yaml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[CHALLENGE 1] Verify users were created${COLOR_OFF}"
echo -e "${GREEN}\$ ansible all -m shell -a 'id {{ inventory_hostname }}'${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "ansible all -m shell -a 'getent passwd \$(hostname)'"

# -------------------------------------------------------
# Challenge 2 - Git repository management
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[CHALLENGE 2] Clone and commit to a git repository${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${Red}NOTE: This challenge requires a real GitHub/GitLab repo with push access.${COLOR_OFF}"
echo -e "${Red}      The demo shows the structure - edit the playbook with your repo URL.${COLOR_OFF}"

docker exec ansible-controller sh -c "cat > /labs-scripts/008-challenge2-demo.yml << 'EOF'
---
- name: Challenge 2 - Git demo (clone only, no push)
  hosts: server-2
  gather_facts: false
  tasks:
    - name: Ensure git is installed
      ansible.builtin.apt:
        name: git
        state: present
      become: true

    - name: Clone a public repository
      ansible.builtin.git:
        repo: https://github.com/nirgeier/AnsibleLabs.git
        dest: /tmp/ansible-git-demo
        clone: true
        update: true

    - name: List cloned files
      ansible.builtin.command: ls /tmp/ansible-git-demo
      register: cloned_files
      changed_when: false

    - name: Show cloned content
      ansible.builtin.debug:
        msg: \"{{ cloned_files.stdout_lines }}\"
EOF
cd /labs-scripts && ansible-playbook 008-challenge2-demo.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 008 complete!${COLOR_OFF}"
echo -e "  ${GREEN}Challenge 1${COLOR_OFF}: Users created per hostname using ansible.builtin.user"
echo -e "  ${GREEN}Challenge 2${COLOR_OFF}: Git repo cloned using ansible.builtin.git"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
