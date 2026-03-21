#!/bin/bash
# =============================================================================
# Ansible Labs - Container Entrypoint
#
# 1. Creates the 'ansible' user with sudo access
# 2. Generates an SSH key pair for the ansible user (shared via volume)
# 3. Copies lab content fresh into /home/ansible/labs/
# 4. Writes helper .bashrc / .bash_profile for the user shell
# 5. Writes ansible.cfg pointing to the lab inventory
# 6. Starts the Node.js web-terminal server
# =============================================================================
set -eu

BASE=/home/ansible/labs
CONTENT=/app/labs
SSH_SHARED=/ssh-shared

# ── 1. Create user ────────────────────────────────────────────────────────────
if ! id -u ansible >/dev/null 2>&1; then
  useradd -m -s /bin/bash ansible
fi
echo "ansible:ansible" | chpasswd

# Passwordless sudo (needed for ansible commands that require privilege)
echo "ansible ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/ansible
chmod 0440 /etc/sudoers.d/ansible

# ── 2. Generate SSH key pair ──────────────────────────────────────────────────
# The public key is written to /ssh-shared so target server containers can
# pick it up and add it to their authorized_keys.
mkdir -p "$SSH_SHARED"
mkdir -p /home/ansible/.ssh

if [ ! -f "$SSH_SHARED/id_rsa" ]; then
  ssh-keygen -t rsa -f "$SSH_SHARED/id_rsa" -N "" -C "ansible-labs"
fi

# Install keys for the ansible user
cp "$SSH_SHARED/id_rsa" /home/ansible/.ssh/id_rsa
cp "$SSH_SHARED/id_rsa.pub" /home/ansible/.ssh/id_rsa.pub
chmod 600 /home/ansible/.ssh/id_rsa
chmod 644 /home/ansible/.ssh/id_rsa.pub

# SSH client config: disable strict host key checking for lab use
cat >/home/ansible/.ssh/config <<'SSHCFG'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
SSHCFG
chmod 600 /home/ansible/.ssh/config

# ── 3. Copy fresh lab content ─────────────────────────────────────────────────
rm -rf "$BASE"
cp -rp "$CONTENT" "$BASE"
chmod -R a+rX "$BASE"

# ── 4. Write ansible.cfg ──────────────────────────────────────────────────────
mkdir -p /home/ansible
cat >/home/ansible/ansible.cfg <<'ACFG'
[defaults]
inventory          = /home/ansible/labs/000-setup/inventory.yml
remote_user        = root
host_key_checking  = False
private_key_file   = /home/ansible/.ssh/id_rsa

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR
ACFG

# ── 5. Write inventory file if it doesn't exist in lab content ────────────────
if [ ! -f /home/ansible/labs/000-setup/inventory.yml ]; then
  cat >/home/ansible/labs/000-setup/inventory.yml <<'INV'
all:
  children:
    servers:
      hosts:
        server-1:
          ansible_host: server-1
          ansible_user: root
        server-2:
          ansible_host: server-2
          ansible_user: root
        server-3:
          ansible_host: server-3
          ansible_user: root
INV
fi

# ── 6. Fix ownership ──────────────────────────────────────────────────────────
chown -R ansible:ansible /home/ansible

# ── 7. Write .bashrc ──────────────────────────────────────────────────────────
cat >/home/ansible/.bashrc <<'BASHRC'
# Custom prompt
export PS1='\[\033[01;33m\]ansible\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

export HOME=/home/ansible
export LABS=/home/ansible/labs
export ANSIBLE_CONFIG=/home/ansible/ansible.cfg

# Aliases
alias ll='ls -lah'
alias la='ls -laF'
alias l='ls -lAh'

# Show welcome message on first interactive login
if [ -z "${ANSIBLE_LABS_WELCOMED:-}" ]; then
  export ANSIBLE_LABS_WELCOMED=1
  cat /etc/motd
  echo "  Welcome to Ansible Labs!"
  echo "  ────────────────────────────────────────────"
  echo "  Labs directory : \$LABS - $LABS"
  echo "  Ansible config : \$ANSIBLE_CONFIG - $ANSIBLE_CONFIG"
  echo "  SSH key        : ~/.ssh/id_rsa"
  echo ""
  echo "  Start with lab 000-setup:"
  echo "    cd \$LABS/000-setup && cat README.md"
  echo ""
fi
BASHRC

# .bash_profile sources .bashrc so login shells (su -) work correctly
cat >/home/ansible/.bash_profile <<'PROFILE'
[ -f ~/.bashrc ] && source ~/.bashrc
cd /home/ansible/labs
PROFILE

chown ansible:ansible /home/ansible/.bashrc /home/ansible/.bash_profile /home/ansible/ansible.cfg

# ── 8. Start web server ───────────────────────────────────────────────────────
exec node /app/server.js
