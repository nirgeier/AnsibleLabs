#
# Ansible playground based upon ubutnu
# 
FROM    ubuntu

# Use root user
USER    root

# update to local repo
RUN     sed -i 's#http://archive.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 
RUN     sed -i 's#http://security.ubuntu.com/#http://il.archive.ubuntu.com/#' /etc/apt/sources.list; 

# Set time zone
ENV     DEBIAN_FRONTEND=noninteractive
ENV     TZ=Asia/Jerusalem
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN     apt update && \
        apt install -y openssh-server 

# Make sure we have the required ssh folder (not always created in some scenarios)
RUN     mkdir /var/run/sshd

# Enable root login over ssh
RUN     sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Suppress ssh public key auth
RUN     sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

EXPOSE  22 

COPY    sshd_config /etc/ssh/sshd_config

# Generate keys when container is created
COPY    entrypoint.sh   /entrypoint.sh
RUN     chmod +x /entrypoint.sh

# Run the loading script
ENTRYPOINT      ["/entrypoint.sh"]