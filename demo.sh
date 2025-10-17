#!/bin/bash

rm -rf  demos
mkdir   demos
cd      demos

# Create the required folder structure
mkdir -p {docker,config,keys}

# create SSH keys (overwrite if any exist):
echo -e 'y\n' | ssh-keygen -t rsa -b 2048 -N '' -f ./keys/demo_key

# # Set permissions
# chown -R root:root keys/

# Docker file for the ansible-controller
cat << EOF >> docker/Ansible-server
FROM alpine:latest
RUN apk add --update --no-cache openssh-client ansible
WORKDIR /etc/ansible/playbooks
EOF

# Docker file for the Ansible-host
cat << EOF >> docker/Ansible-host
FROM ubuntu:latest
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server python3 && \
  apt-get clean && \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
  rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd
CMD [ "/usr/sbin/sshd", "-D" ]
EOF

# Docker compose for triggering the demo containers
cat << EOF >> docker-compose.yaml
version: "3.9"
services:
  ansible:
    build:
      context: docker/
      dockerfile: Ansible-server
    container_name: "ansible"
    command: "sleep infinity"
    links:
      - "playground:playground"
    volumes:
      - \$PWD/config:/etc/ansible
      - \$PWD/keys/demo_key:/root/.ssh/id_rsa:ro   
  playground:
    build:
      context: docker/
      dockerfile: Ansible-host
    ports:
      - 80:80
    volumes:
      - \$PWD/keys/demo_key.pub:/root/.ssh/authorized_keys
EOF

cat << EOF > config/ansible.cfg 
[defaults]

#--- General settings
forks                   = 5                             ; Number of concurrent processes
log_path                = /var/log/ansible.log          ; Log file
module_name             = command                       ; Default  module
executable              = /bin/bash                     ; Default Shell interpreter
ansible_managed         = Ansible managed               ; Allows the use of strings, timestamps in your playbook/tasks.

#--- Debug settings
callbacks_enabled       = ansible.posix.profile_tasks   ; Show the execution time of each task

#--- Files/Directory settings
inventory               = /etc/ansible/hosts.yml        ; Ansible's default host file
library                 = /usr/share/my_modules         ; Directory containing the ansible modules.
remote_tmp              = ~/.ansible/tmp                ; Where the temporary files will be stored on the target hosts (inventory).
local_tmp               = ~/.ansible/tmp                ; Local temporary directory.
roles_path              = /etc/ansible/roles            ; Ansible's default roles directory

#--- Users settings
remote_user             = root                          ; Default User - if not specified
sudo_user               = root                          ; Default sudo user
ask_pass                = no                            ; Ask for the password by default when executing tasks
ask-sudo_pass           = no                            ; Similar to ask_pass

#--- SSH settings
remote_port             = 22                            ; Default remote connection port (SSH)
timeout                 = 10                            ; SSH timeout
host_key_checking       = False                         ; SSH key validation while connecting
ssh_executable          = /usr/bin/ssh                  ; SSH binary. The ansible_ssh_executable variable is used.
private_key_file        = ~/.ssh/id_rsa                 ; Default SSH private key

[privilege_scalation]

become                  = True                          ; Allows elevation of privilege
become_method           = sudo                          ; Default method
become_user             = root                          ; Default user
become_ask_pass         = False                         ; Ask for password

[ssh_connection]

scp_if_ssh              = smart                         ; Run sftp and if not try with scp (default)
transfer_method         = smart                         ; Execution order: sftp -> scp (default)
retries                 = 3                             ; Time to retry connection to a host
EOF


cat << EOF >> config/hosts.yml
all:
  vars:
    ansible_python_interpreter: /usr/bin/python3
  children:
    web:
      hosts:
        demos-playground-1:
EOF

mkdir -p config/roles/nginx/{tasks,templates}
mkdir -p config/playbooks

cat << EOF >> config/roles/nginx/tasks/main.yml
---
- name: Install NGINX
  package:
    name: nginx
    state: present
  register: nginx

- name: Get unnecessary files list
  find:
    path: /var/www/html/
    hidden: yes
    recurse: yes
    file_type: any
  register: files_list
  when: nginx is changed

- name:  Remove collected files
  file:
    path: "{{ item.path }}"
    state: absent
  with_items:
    - "{{ files_list.files }}"
  when: nginx is changed

- name: Copy server template
  template:
    src: server
    dest: /etc/nginx/sites-available/default

- name: Create NGINX Symlink
  file:
    src: /etc/nginx/sites-available/default
    dest: /etc/nginx/sites-enabled/default
    state: link

- name: Copy web template
  template:
    src: web
    dest: /var/www/html/index.html
  register: site_content

- name: Reload NGINX
  service:
    name: nginx
    state: reload
  when: site_content is changed
EOF

cat << EOF >> config/roles/nginx/templates/server
server {
  root /var/www/html;
}
EOF

cat << EOF >> config/roles/nginx/templates/web
<html>
<body>
  <title>Ansible Playground</title>
  <h1 align="center">Welcome to {{ inventory_hostname_short }}</h1>.   </br>
  <p align="center">A simple Ansible stack example using Docker Compose.</p>  
  <p align="center">Last updated on {{ ansible_date_time.date }}.</p>
</body>
</html>
EOF

cat << EOF >> config/playbooks/web.yml
---
- hosts: web
  roles:
    - nginx
EOF

docker-compose down
docker-compose up -d --build