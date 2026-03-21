---

# Ansible with Docker

* In this lab we use Ansible to install Docker, manage containers, images, networks, and volumes, and orchestrate multi-container applications.
* Ansible's Docker modules bridge configuration management and container orchestration.

## What will we learn?

- Installing Docker with Ansible
- Managing containers with `docker_container`
- Managing images with `docker_image`
- Managing networks and volumes
- Deploying Docker Compose stacks

---

## Prerequisites

- Complete [Lab 017](../017-package-service-modules/README.md#usage) in order to have a working understanding of package and service modules.

---

## 01. Install Docker with Ansible

```yaml
---
- name: Install Docker
  hosts: all
  become: true
  gather_facts: true

  tasks:
    - name: Install prerequisites
      ansible.builtin.apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
        state: present
        update_cache: true
      when: ansible_os_family == "Debian"

    - name: Add Docker GPG key
      ansible.builtin.apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present
      when: ansible_distribution == "Ubuntu"

    - name: Add Docker repository
      ansible.builtin.apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present
      when: ansible_distribution == "Ubuntu"

    - name: Install Docker Engine
      ansible.builtin.apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: present
        update_cache: true
      when: ansible_os_family == "Debian"

    - name: Start and enable Docker
      ansible.builtin.service:
        name: docker
        state: started
        enabled: true

    - name: Add users to docker group
      ansible.builtin.user:
        name: "{{ item }}"
        groups: docker
        append: true
      loop:
        - "{{ ansible_user }}"
      ignore_errors: true
```

---

## 02. Install `community.docker` Collection

```sh
# Install the community.docker collection
ansible-galaxy collection install community.docker
```

---

## 03. Manage Docker Containers

```yaml
tasks:
  # Run a container
  - name: Run nginx container
    community.docker.docker_container:
      name: my-nginx
      image: nginx:latest
      state: started
      restart_policy: unless-stopped
      ports:
        - "8080:80"
      volumes:
        - /opt/website:/usr/share/nginx/html:ro
      env:
        NGINX_HOST: "{{ inventory_hostname }}"
        NGINX_PORT: "80"

  # Stop a container
  - name: Stop old container
    community.docker.docker_container:
      name: old-nginx
      state: stopped

  # Remove a container
  - name: Remove old container
    community.docker.docker_container:
      name: old-nginx
      state: absent

  # Run container with resource limits
  - name: Run app with limits
    community.docker.docker_container:
      name: myapp
      image: myapp:v2.1
      state: started
      memory: "512m"
      cpus: "0.5"
      restart_policy: on-failure
      restart_retries: 3
      labels:
        app: myapp
        version: v2.1
        managed-by: ansible
```

---

## 04. Manage Docker Images

```yaml
tasks:
  # Pull an image
  - name: Pull nginx image
    community.docker.docker_image:
      name: nginx
      tag: latest
      source: pull

  # Pull a specific version
  - name: Pull specific version
    community.docker.docker_image:
      name: nginx
      tag: "1.24"
      source: pull

  # Build an image from Dockerfile
  - name: Build application image
    community.docker.docker_image:
      name: myapp
      tag: "{{ app_version }}"
      source: build
      build:
        path: /opt/myapp/src
        dockerfile: Dockerfile
        pull: true
        args:
          BUILD_DATE: "{{ ansible_date_time.date }}"
          VERSION: "{{ app_version }}"

  # Remove an image
  - name: Remove old image
    community.docker.docker_image:
      name: myapp
      tag: v1.0
      state: absent
```

---

## 05. Manage Networks and Volumes

```yaml
tasks:
  # Create a network
  - name: Create app network
    community.docker.docker_network:
      name: app-network
      driver: bridge
      ipam_config:
        - subnet: "172.20.0.0/16"
          gateway: "172.20.0.1"

  # Create a named volume
  - name: Create data volume
    community.docker.docker_volume:
      name: app-data
      driver: local

  # Remove a network
  - name: Remove old network
    community.docker.docker_network:
      name: old-network
      state: absent
```

---

## 06. Docker Compose with Ansible

```yaml
tasks:
  # Deploy a compose stack
  - name: Deploy application stack
    community.docker.docker_compose_v2:
      project_name: myapp
      project_src: /opt/myapp
      state: present
      pull: always

  # Stop a compose stack
  - name: Stop application stack
    community.docker.docker_compose_v2:
      project_name: myapp
      project_src: /opt/myapp
      state: stopped

  # Remove a compose stack (including volumes)
  - name: Remove application stack
    community.docker.docker_compose_v2:
      project_name: myapp
      project_src: /opt/myapp
      state: absent
      remove_volumes: true
```

---

## 07. Inspect Container State

```yaml
tasks:
  - name: Get container info
    community.docker.docker_container_info:
      name: my-nginx
    register: container_info

  - name: Show container status
    ansible.builtin.debug:
      msg: "Container status: {{ container_info.container.State.Status }}"
    when: container_info.exists

  - name: Get all container facts
    community.docker.docker_host_info:
      containers: true
      images: true
      networks: true
      volumes: true
    register: docker_facts

  - name: Show running containers
    ansible.builtin.debug:
      msg: "{{ docker_facts.containers | map(attribute='Names') | list }}"
```

---

## 08. Hands-on

1. Create a Docker Compose file for a web + redis stack, then create an HTML index page for it.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p docker-app/html && cat > docker-app/docker-compose.yml << 'EOF'
   version: \"3.8\"

   services:
     web:
       image: nginx:latest
       ports:
         - \"8080:80\"
       volumes:
         - ./html:/usr/share/nginx/html
       networks:
         - frontend

     redis:
       image: redis:7-alpine
       networks:
         - backend

   networks:
     frontend:
       driver: bridge
     backend:
       driver: bridge
   EOF"

   docker exec ansible-controller sh -c "echo '<h1>Deployed by Ansible!</h1>' > /labs-scripts/docker-app/html/index.html"
   ```

2. Create a playbook `lab021-docker.yml` that creates a network, starts an nginx container on port 8099, checks its status, then cleans up both the container and network.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab021-docker.yml << 'EOF'
   ---
   - name: Docker Container Management
     hosts: localhost
     gather_facts: false

     tasks:
       - name: Ensure community.docker collection is available
         ansible.builtin.debug:
           msg: \"Using community.docker collection\"

       - name: Create a test network
         community.docker.docker_network:
           name: lab021-network
           driver: bridge
           state: present

       - name: Run nginx container
         community.docker.docker_container:
           name: lab021-nginx
           image: nginx:latest
           state: started
           restart_policy: unless-stopped
           ports:
             - \"8099:80\"
           networks:
             - name: lab021-network

       - name: Check container is running
         community.docker.docker_container_info:
           name: lab021-nginx
         register: nginx_info

       - name: Show container status
         ansible.builtin.debug:
           msg: \"nginx container: {{ nginx_info.container.State.Status }}\"

       - name: Clean up
         community.docker.docker_container:
           name: lab021-nginx
           state: absent

       - name: Remove test network
         community.docker.docker_network:
           name: lab021-network
           state: absent
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab021-docker.yml"
   ```

3. Install the `community.docker` collection and pull the `alpine:latest` Docker image using an Ansible playbook:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-galaxy collection install community.docker --upgrade"
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab021-pull.yml << 'EOF'
   ---
   - name: Pull Docker Image
     hosts: localhost
     gather_facts: false

     tasks:
       - name: Pull alpine image
         community.docker.docker_image:
           name: alpine
           tag: latest
           source: pull
         register: pull_result

       - name: Show image digest
         ansible.builtin.debug:
           msg: \"Pulled: {{ pull_result.image.RepoDigests | default(['alpine:latest']) }}\"
   EOF
   ansible-playbook lab021-pull.yml"
   ```

4. Create a named Docker volume, start a container that mounts it, write a file into the volume, then verify the file survives container removal and recreation:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab021-volume.yml << 'EOF'
   ---
   - name: Docker Volume Persistence
     hosts: localhost
     gather_facts: false

     tasks:
       - name: Create named volume
         community.docker.docker_volume:
           name: lab021-data
           state: present

       - name: Run container and write to volume
         community.docker.docker_container:
           name: lab021-writer
           image: alpine:latest
           state: started
           command: sh -c \"echo 'persistent data' > /data/test.txt && sleep 5\"
           volumes:
             - lab021-data:/data
           detach: true

       - name: Wait for write to complete
         ansible.builtin.pause:
           seconds: 6

       - name: Remove writer container
         community.docker.docker_container:
           name: lab021-writer
           state: absent

       - name: Read from volume in new container
         community.docker.docker_container:
           name: lab021-reader
           image: alpine:latest
           state: started
           command: cat /data/test.txt
           volumes:
             - lab021-data:/data
           detach: false
           auto_remove: false
         register: read_result

       - name: Show persisted data
         ansible.builtin.debug:
           msg: \"Volume data survived: {{ read_result.container.Output | default('see container logs') }}\"

       - name: Cleanup
         community.docker.docker_container:
           name: \"{{ item }}\"
           state: absent
         loop:
           - lab021-reader

       - name: Remove volume
         community.docker.docker_volume:
           name: lab021-data
           state: absent
   EOF
   ansible-playbook lab021-volume.yml"
   ```

5. Write a playbook that loops over a list of images, pulls each one, and prints a summary of pulled images:

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab021-multi-image.yml << 'EOF'
   ---
   - name: Pull Multiple Docker Images
     hosts: localhost
     gather_facts: false

     vars:
       images_to_pull:
         - { name: nginx,  tag: alpine }
         - { name: redis,  tag: 7-alpine }
         - { name: alpine, tag: \"3.18\" }

     tasks:
       - name: Pull all images
         community.docker.docker_image:
           name: \"{{ item.name }}\"
           tag: \"{{ item.tag }}\"
           source: pull
         loop: \"{{ images_to_pull }}\"
         register: pull_results

       - name: Summarize pulled images
         ansible.builtin.debug:
           msg: \"Pulled {{ item.item.name }}:{{ item.item.tag }}\"
         loop: \"{{ pull_results.results }}\"
   EOF
   ansible-playbook lab021-multi-image.yml"
   ```

---

## 09. Summary

- Use `community.docker.docker_container` to manage the **full container lifecycle**
- `docker_image` pulls, builds, and removes images declaratively
- `docker_network` and `docker_volume` manage Docker networking and storage
- `docker_compose_v2` deploys entire application stacks from compose files
- `docker_container_info` and `docker_host_info` inspect running infrastructure
- Install the `community.docker` collection with `ansible-galaxy collection install community.docker`
