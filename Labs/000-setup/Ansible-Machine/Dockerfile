#
# Ansible playground based upon python
# 
# FROM    alpine/ansible

# # Use root user
# USER    root

# RUN     apk add openssh && ssh-keygen -A    

# EXPOSE  22 
# COPY            sshd_config     /etc/ssh/sshd_config
# COPY            entrypoint.sh   /entrypoint.sh
# RUN             chmod +x /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]


#
# Ansible playground based upon python
# 
#
# Ansible playground based upon ubutnu
# 
FROM    python

# Use root user
USER    root

# Set time zone
ENV     TZ=Asia/Jerusalem
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN     pip install pip ansible --upgrade

RUN     apt-get update -y && \
            DEBIAN_FRONTEND=noninteractive \
            apt-get install -y --no-install-recommends \
            sshpass \
            openssh-server 

# Generate keys when container is created
COPY    entrypoint.sh   /entrypoint.sh
RUN     chmod +x        /entrypoint.sh

EXPOSE  22 

# Run the loading script
ENTRYPOINT      ["/entrypoint.sh"]