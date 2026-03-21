---
# Ansible Vault

* In this lab we learn to use **Ansible Vault** to encrypt sensitive data such as passwords, API keys, and private keys.
* Vault allows you to safely commit secrets to version control without exposing them.

## What will we learn?

- How to create, edit, view, and decrypt Vault-encrypted files
- How to encrypt individual variables vs entire files
- How to pass the vault password at runtime
- Multi-vault ID support for different environments

---

## Prerequisites

- Complete [Lab 014](../014-playbook-variables/README.md#usage) in order to have a working understanding of playbook variables.

---

## 01. Why Vault?

> **NOTE:** Never commit plaintext secrets to Git! Passwords, API keys, private keys, and certificates must be encrypted before committing.

Ansible Vault encrypts files or variables using AES-256-CBC symmetric encryption. The encrypted content can be committed to Git safely.

---

## 02. Vault Commands

```sh
# Create a new encrypted file
ansible-vault create secrets.yml

# Edit an encrypted file (decrypts, opens editor, re-encrypts on save)
ansible-vault edit secrets.yml

# View an encrypted file
ansible-vault view secrets.yml

# Encrypt an existing plaintext file
ansible-vault encrypt secrets.yml

# Decrypt a file (writes plaintext - be careful!)
ansible-vault decrypt secrets.yml

# Change the vault password
ansible-vault rekey secrets.yml

# Encrypt a single string (for use in playbooks)
ansible-vault encrypt_string 'mysecretpassword' --name 'db_password'
```

---

## 03. Encrypted Variables File

```sh
# Create an encrypted variables file
ansible-vault create group_vars/all/vault.yml

# Content of vault.yml (encrypted):
# ---
# vault_db_password: "SuperSecretPassword123"
# vault_api_key: "sk-abc123def456"
# vault_ssl_key: |
#   -----BEGIN PRIVATE KEY-----
#   ...
#   -----END PRIVATE KEY-----
```

After creation, the file looks like this on disk:

```
$ANSIBLE_VAULT;1.1;AES256
66363633613631333439363636653463303963393834653661306664313534666132636564326238
...
```

---

## 04. Using Encrypted Variables in Playbooks

```yaml
# group_vars/all/vars.yml (plaintext - references vault vars)
---
db_password: "{{ vault_db_password }}"
api_key: "{{ vault_api_key }}"


# group_vars/all/vault.yml (encrypted)
---
vault_db_password: "SuperSecretPassword123"
vault_api_key: "sk-abc123def456"
```

```yaml
# site.yml
---
- name: Deploy application
  hosts: all
  vars_files:
    - group_vars/all/vars.yml
    - group_vars/all/vault.yml # Can also load directly

  tasks:
    - name: Configure database
      ansible.builtin.template:
        src: db.conf.j2
        dest: /etc/app/db.conf
```

---

## 05. Running Playbooks with Vault

```sh
# Prompt for vault password interactively
ansible-playbook site.yml --ask-vault-pass

# Use a password file
echo "myVaultPassword" > ~/.vault_pass
chmod 600 ~/.vault_pass
ansible-playbook site.yml --vault-password-file ~/.vault_pass

# Set in ansible.cfg
# [defaults]
# vault_password_file = ~/.vault_pass

# Use environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
ansible-playbook site.yml
```

---

## 06. `encrypt_string` - Encrypt Individual Values

```sh
# Encrypt a single string
ansible-vault encrypt_string 'MySecretPassword' --name 'db_password'

### Output
# db_password: !vault |
#   $ANSIBLE_VAULT;1.1;AES256
#   33313337653932626264383336666434366235326432323362636631333938343938376362326435
#   ...

# Use with a vault ID
ansible-vault encrypt_string 'MySecretPassword' --name 'db_password' --vault-id prod@~/.vault_pass_prod
```

```yaml
# Use inline in variables
---
db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  33313337653932626264383336666434366235326432323362636631333938343938376362326435
  ...

api_key: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...
```

---

## 07. Multiple Vault IDs

For different environments (dev/prod) with different passwords:

```sh
# Create vault files with specific IDs
ansible-vault create --vault-id dev@~/.vault_pass_dev group_vars/dev/vault.yml
ansible-vault create --vault-id prod@~/.vault_pass_prod group_vars/prod/vault.yml

# Run with multiple vault passwords
ansible-playbook site.yml \
  --vault-id dev@~/.vault_pass_dev \
  --vault-id prod@~/.vault_pass_prod
```

---

## 08. Vault Best Practices

- Never commit vault password files to Git
- Add `*.vault_pass` and `.vault_pass` to `.gitignore`
- Use separate vault passwords per environment
- Prefix vault variables with `vault_` (e.g., `vault_db_password`)
- Use a plaintext var (`db_password: "{{ vault_db_password }}"`) for readability
- Consider HashiCorp Vault or AWS Secrets Manager for production secrets
- Rotate vault passwords regularly with `ansible-vault rekey`

---

## 09. Hands-on

1. Create a vault password file inside the controller.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "echo 'my-lab-vault-password' > ~/.vault_pass && chmod 600 ~/.vault_pass"
   ```

2. Create an encrypted variables file at `secrets/vault.yml` with `vault_db_password` and `vault_api_key` values.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p secrets && ansible-vault create secrets/vault.yml --vault-password-file ~/.vault_pass"
   # Add in the editor:
   # ---
   # vault_db_password: "LabPassword123!"
   # vault_api_key: "lab-api-key-abc123"
   ```

3. Create a plaintext `secrets/vars.yml` that references the vault variables.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > secrets/vars.yml << 'EOF'
   ---
   db_password: \"{{ vault_db_password }}\"
   api_key: \"{{ vault_api_key }}\"
   EOF"
   ```

4. Create a playbook `lab019-vault.yml` that loads both files and prints the DB password length, then run it with the vault password file.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > lab019-vault.yml << 'EOF'
   ---
   - name: Vault Practice
     hosts: localhost
     gather_facts: false
     vars_files:
       - secrets/vars.yml
       - secrets/vault.yml

     tasks:
       - name: Show that we can access the secret
         ansible.builtin.debug:
           msg: \"DB Password length: {{ db_password | length }} characters\"

       - name: Use the secret safely
         ansible.builtin.copy:
           content: \"db_password={{ db_password }}\n\"
           dest: /tmp/db.conf
           mode: '0600'

       - name: Verify the file was created
         ansible.builtin.command:
           cmd: ls -la /tmp/db.conf
         register: ls_out

       - name: Show file details
         ansible.builtin.debug:
           var: ls_out.stdout
   EOF"

   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook lab019-vault.yml --vault-password-file ~/.vault_pass"
   ```

5. Encrypt a single inline string using `encrypt_string`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "ansible-vault encrypt_string 'MyNewApiKey' --name 'api_key' --vault-password-file ~/.vault_pass"

   ### Output
   # api_key: !vault |
   #   $ANSIBLE_VAULT;1.1;AES256
   #   ...
   ```

---

## 10. Summary

- **Ansible Vault** uses AES-256 encryption to protect secrets in YAML files
- `ansible-vault create/edit/view/encrypt/decrypt/rekey` are the core commands
- Run playbooks with `--ask-vault-pass` or `--vault-password-file`
- `encrypt_string` embeds encrypted values directly into YAML
- Use the `vault_` naming convention to distinguish encrypted from plain variables
- **Multiple vault IDs** support different passwords per environment
- Never commit vault password files to Git - add them to `.gitignore`
