#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 021 - Ansible Docker Module${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Install community.docker collection${COLOR_OFF}"
echo -e "${GREEN}$ ansible-galaxy collection install community.docker${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "ansible-galaxy collection install community.docker"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: Install required Python docker SDK inside controller${COLOR_OFF}"
echo -e "${GREEN}$ pip install docker${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "pip install docker --quiet && echo 'docker SDK installed.'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Create the Docker management playbook${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab021-docker.yml << 'EOF'
---
- name: Lab 021 - Manage Docker with Ansible
  hosts: localhost
  connection: local
  gather_facts: false

  vars:
    network_name: ansible_demo_net
    container_name: ansible_nginx_demo
    nginx_port: 8099

  tasks:
    - name: Create a Docker network
      community.docker.docker_network:
        name: \"{{ network_name }}\"
        state: present

    - name: Pull the nginx image
      community.docker.docker_image:
        name: nginx
        tag: alpine
        source: pull

    - name: Start nginx container
      community.docker.docker_container:
        name: \"{{ container_name }}\"
        image: nginx:alpine
        state: started
        restart_policy: unless-stopped
        networks:
          - name: \"{{ network_name }}\"
        ports:
          - \"{{ nginx_port }}:80\"

    - name: Get container info
      community.docker.docker_container_info:
        name: \"{{ container_name }}\"
      register: container_info

    - name: Show container status
      ansible.builtin.debug:
        msg:
          - \"Container name : {{ container_info.container.Name }}\"
          - \"Container state: {{ container_info.container.State.Status }}\"
          - \"Container image: {{ container_info.container.Config.Image }}\"

    - name: Pull alpine image
      community.docker.docker_image:
        name: alpine
        tag: latest
        source: pull

    - name: Confirm alpine image is available
      community.docker.docker_image_info:
        name: alpine:latest
      register: alpine_info

    - name: Show alpine image info
      ansible.builtin.debug:
        msg: \"Alpine image ID: {{ alpine_info.images[0].Id[:20] }}\"

    - name: Stop and remove the nginx container
      community.docker.docker_container:
        name: \"{{ container_name }}\"
        state: absent

    - name: Remove the Docker network
      community.docker.docker_network:
        name: \"{{ network_name }}\"
        state: absent

    - name: Cleanup complete
      ansible.builtin.debug:
        msg: \"Container and network removed successfully.\"
EOF
echo 'lab021-docker.yml created.'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Run the Docker playbook against localhost${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab021-docker.yml -i localhost,${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab021-docker.yml -i localhost,"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 021 complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
