#!/bin/bash

# We will need to pre-install the missing plugin
# https://docs.ansible.com/ansible/latest/collections/community/general/git_config_module.html
# ansible-galaxy collection install community.general

cd /labs-scripts

# Install requiremens
ansible-galaxy collection install community.general

ansible-playbook ./004-install-git-playbook.yaml
