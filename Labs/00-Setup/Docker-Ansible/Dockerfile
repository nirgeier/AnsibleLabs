#
#     Build an Ansible container which will be used in our demo
#
FROM  debian:stretch

USER  root
RUN   apt-get update && \
      apt-get install -y gnupg

RUN   echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' >> /etc/apt/sources.list
RUN   apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 && \
      apt-get update && \
      apt-get install -y ansible 

COPY  entrypoint.sh /entrypoint.sh

RUN   chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]