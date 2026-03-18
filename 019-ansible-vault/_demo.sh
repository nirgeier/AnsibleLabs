#!/bin/bash

ROOT_FOLDER=$(git rev-parse --show-toplevel)
source $ROOT_FOLDER/_utils/common.sh
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 019 - Ansible Vault${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create vault password file${COLOR_OFF}"
echo -e "${GREEN}$ echo 'MyVaultPass123' > .vault_pass${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && echo 'MyVaultPass123' > .vault_pass && chmod 600 .vault_pass && echo 'Vault password file created.'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: Encrypt a vars file using ansible-vault${COLOR_OFF}"
echo -e "${GREEN}$ ansible-vault encrypt_string ... > vault_vars.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && \
  ENCRYPTED=\$(ansible-vault encrypt_string 'Hello from vault!' --name 'vault_secret_message' --vault-password-file .vault_pass) && \
  cat > vault_vars.yml << EOF
---
\${ENCRYPTED}
EOF
echo 'vault_vars.yml created (encrypted).'"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Show encrypted file content (it is unreadable)${COLOR_OFF}"
echo -e "${GREEN}$ cat vault_vars.yml${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat vault_vars.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Try to view vault without password (expect failure)${COLOR_OFF}"
echo -e "${Green}$ ansible-vault view vault_vars.yml  # (no password - will fail)${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-vault view vault_vars.yml" || true

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: View vault with password file${COLOR_OFF}"
echo -e "${GREEN}$ ansible-vault view vault_vars.yml --vault-password-file .vault_pass${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-vault view vault_vars.yml --vault-password-file .vault_pass"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 6: Create and run a playbook that uses the vault variable${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook lab019-vault.yml --vault-password-file .vault_pass${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab019-vault.yml << 'EOF'
---
- name: Lab 019 - Ansible Vault demo
  hosts: linux-server-1
  gather_facts: false
  vars_files:
    - vault_vars.yml

  tasks:
    - name: Show the secret message from vault
      ansible.builtin.debug:
        msg: \"The secret message is: {{ vault_secret_message }}\"

    - name: Write the secret to a file on the remote host
      ansible.builtin.copy:
        content: \"{{ vault_secret_message }}\n\"
        dest: /tmp/vault_demo.txt
        mode: '0600'

    - name: Read back the file to confirm
      ansible.builtin.command: cat /tmp/vault_demo.txt
      register: file_content
      changed_when: false

    - name: Display file content
      ansible.builtin.debug:
        msg: \"File contains: {{ file_content.stdout }}\"
EOF
ansible-playbook lab019-vault.yml --vault-password-file .vault_pass"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 7: Decrypt the variable in-place to show vault decrypt${COLOR_OFF}"
echo -e "${GREEN}$ ansible-vault decrypt vault_vars.yml --vault-password-file .vault_pass${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && \
  cp vault_vars.yml vault_vars_decrypted.yml && \
  ansible-vault decrypt vault_vars_decrypted.yml --vault-password-file .vault_pass && \
  echo '--- Decrypted content:' && \
  cat vault_vars_decrypted.yml && \
  rm vault_vars_decrypted.yml"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 019 complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
