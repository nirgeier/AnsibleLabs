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
echo -e "${CYAN}Ad-Hoc Command Syntax:${COLOR_OFF}"
echo -e "  ansible <host-pattern> -m <module> -a \"<arguments>\" [options]"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

# -------------------------------------------------------
# 1. ping - Test connectivity
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}[1/7] ping - Test connectivity to all hosts${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m ping${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m ping"

# -------------------------------------------------------
# 2. shell -a 'hostname'
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}[2/7] shell - Get hostname of all servers${COLOR_OFF}"
echo -e "${Green}* The shell module supports pipes, redirects, and env variables${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m shell -a 'hostname'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m shell -a 'hostname'"

# -------------------------------------------------------
# 3. command -a 'uname -r'
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}[3/7] command - Get kernel version (no shell features needed)${COLOR_OFF}"
echo -e "${Green}* The command module is safer than shell - use it when you don't need pipes or redirects${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m command -a 'uname -r'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'uname -r'"

# -------------------------------------------------------
# 4. setup - Gather facts (filtered)
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}[4/7] setup - Gather OS distribution facts (filtered)${COLOR_OFF}"
echo -e "${Green}* The setup module collects hundreds of facts; use filter= to narrow results${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m setup -a 'filter=ansible_distribution*'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m setup -a 'filter=ansible_distribution*'"

# -------------------------------------------------------
# 5. copy - Create a file with inline content
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}[5/7] copy - Create a file with inline content on linux-server-1${COLOR_OFF}"
echo -e "${GREEN}$ ansible linux-server-1 -m copy -a 'content=\"hello world\n\" dest=/tmp/adhoc-test.txt'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m copy -a 'content=\"hello world\n\" dest=/tmp/adhoc-test.txt'"

# -------------------------------------------------------
# 6. shell - Read back the file
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}[6/7] shell - Read back the file we just created${COLOR_OFF}"
echo -e "${GREEN}$ ansible linux-server-1 -m shell -a 'cat /tmp/adhoc-test.txt'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible linux-server-1 -m shell -a 'cat /tmp/adhoc-test.txt'"

# -------------------------------------------------------
# 7. shell --become - Check memory usage
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}[7/7] shell + --become - Check memory on all servers with privilege escalation${COLOR_OFF}"
echo -e "${Green}* Use --become (-b) for tasks that require elevated privileges${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m shell -a 'free -m' --become${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m shell -a 'free -m' --become"

# -------------------------------------------------------
# Bonus: hands-on exercises from README
# -------------------------------------------------------
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}[BONUS] Hands-on exercises${COLOR_OFF}"

echo -e ""
echo -e "${CYAN}Create /tmp/ansible-test.txt on ALL hosts, verify it, then remove it${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m copy -a \"content='Created by Ansible ad-hoc' dest=/tmp/ansible-test.txt\"${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m copy -a \"content='Created by Ansible ad-hoc' dest=/tmp/ansible-test.txt\""

echo -e ""
echo -e "${GREEN}$ ansible all -m command -a 'cat /tmp/ansible-test.txt'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'cat /tmp/ansible-test.txt'"

echo -e ""
echo -e "${GREEN}$ ansible all -m file -a 'path=/tmp/ansible-test.txt state=absent'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m file -a 'path=/tmp/ansible-test.txt state=absent'"

echo -e ""
echo -e "${CYAN}Use shell with pipe to find python processes${COLOR_OFF}"
echo -e "${GREEN}$ ansible all -m shell -a 'ps aux | grep python'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m shell -a 'ps aux | grep python'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Summary:${COLOR_OFF}"
echo -e "  ${Green}ansible <hosts> -m <module> -a \"<args>\"${COLOR_OFF}  → ad-hoc syntax"
echo -e "  ${Green}command${COLOR_OFF}  → safe, no shell features (no pipes/redirects)"
echo -e "  ${Green}shell  ${COLOR_OFF}  → full shell, supports pipes and env vars"
echo -e "  ${Green}setup  ${COLOR_OFF}  → gather facts; use filter= to narrow results"
echo -e "  ${Green}--become${COLOR_OFF} → elevate to root (sudo)"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
