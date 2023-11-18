###
### Base images for Ansible Controller
### @Author: Nir Geier
### 
FROM  ubuntu 

# Update packages, install OpenSSH
RUN                                   \
  apt update  -o Acquire::http::Timeout=5 -y &&                  \
  apt upgrade -o Acquire::http::Timeout=5 -y &&                  \
  apt install -y ansible openssh-server vim

# This directory is required by the SSH daemon to store its temporary runtime data.  
RUN   mkdir -p /var/run/sshd

# We will need to use ssh
EXPOSE  22 

# Add healthcheck
HEALTHCHECK           \
  --interval=10s      \
  --timeout=10s       \
  --start-period=10s  \
  --retries=3         \
  CMD                                 \
  ssh                                 \
  -o StrictHostKeyChecking=accept-new \
  root@localhost                      \
  exit

# Copy the entrypoint script
# Generate keys when container is created
COPY    entrypoint.sh   /entrypoint.sh
RUN     chmod +x        /entrypoint.sh

USER    root
# Run the loading script
ENTRYPOINT      ["/entrypoint.sh"]

