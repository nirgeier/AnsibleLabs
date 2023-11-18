#
#     Build an Ansible container which will be used in our demo
#
FROM    python:3-alpine

# Use root user
USER    root

RUN     apk add --update --no-cache ansible bash openssh openrc

COPY    entrypoint.sh /entrypoint.sh
RUN     chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]