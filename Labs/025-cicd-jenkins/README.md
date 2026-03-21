---
# CI/CD Integration with Jenkins

* In this lab we integrate Ansible with Jenkins to automate deployments through a CI/CD pipeline.
* Jenkins triggers Ansible playbooks as part of a build/deploy pipeline, enabling fully automated infrastructure changes.

## What will we learn?

- Installing the Ansible plugin for Jenkins
- Creating Jenkins pipelines that run Ansible playbooks
- Parameterized builds for environment selection
- Storing credentials and vault passwords in Jenkins

---

## Prerequisites

- Complete [Lab 004](../004-playbooks/README.md#usage) in order to have working Ansible playbooks.

---

## 01. Jenkins Ansible Plugin

```groovy
// Install via Jenkins Plugin Manager:
// Manage Jenkins → Plugins → Available → "Ansible"

// The Ansible plugin provides:
// - ansiblePlaybook() step for Pipelines
// - Freestyle job "Invoke Ansible Playbook" build step
// - Credential management for vault passwords
```

---

## 02. Freestyle Job - Basic Configuration

In Jenkins, create a **Freestyle Project** and configure:

1. **Source Code Management**: Point to your Git repo with Ansible code
2. **Build Environment**: Check "Use secret text(s) or file(s)" for vault password
3. **Build Step**: Select "Invoke Ansible Playbook"
   - Playbook path: `site.yml`
   - Inventory: `inventory/`
   - Sudo: Check if needed
   - Vault credentials: Select the stored vault password

---

## 03. Declarative Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        ANSIBLE_VAULT_PASS = credentials('ansible-vault-password')
        ANSIBLE_FORCE_COLOR = '1'
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['staging', 'production'],
            description: 'Target environment'
        )
        string(
            name: 'APP_VERSION',
            defaultValue: 'latest',
            description: 'Application version to deploy'
        )
        booleanParam(
            name: 'DRY_RUN',
            defaultValue: true,
            description: 'Run in check mode (no changes)'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/myorg/ansible-playbooks.git',
                    credentialsId: 'github-credentials'
            }
        }

        stage('Lint') {
            steps {
                sh 'ansible-lint site.yml'
            }
        }

        stage('Syntax Check') {
            steps {
                sh """
                    ansible-playbook site.yml \
                        --syntax-check \
                        -i inventory/${params.ENVIRONMENT}/
                """
            }
        }

        stage('Deploy') {
            steps {
                script {
                    def checkMode = params.DRY_RUN ? '--check' : ''
                    sh """
                        ansible-playbook site.yml \
                            -i inventory/${params.ENVIRONMENT}/ \
                            ${checkMode} \
                            --vault-password-file ${ANSIBLE_VAULT_PASS} \
                            -e "app_version=${params.APP_VERSION}" \
                            -e "target_env=${params.ENVIRONMENT}"
                    """
                }
            }
        }

        stage('Verify') {
            when {
                not { expression { params.DRY_RUN } }
            }
            steps {
                sh """
                    ansible-playbook verify.yml \
                        -i inventory/${params.ENVIRONMENT}/
                """
            }
        }
    }

    post {
        success {
            echo "Deployment to ${params.ENVIRONMENT} succeeded!"
        }
        failure {
            echo "Deployment failed! Check the console output."
        }
        always {
            archiveArtifacts artifacts: 'ansible.log', allowEmptyArchive: true
            cleanWs()
        }
    }
}
```

---

## 04. Using `ansiblePlaybook()` Step

```groovy
// Using the Ansible plugin's ansiblePlaybook() step
stage('Deploy with Ansible Plugin') {
    steps {
        ansiblePlaybook(
            playbook: 'site.yml',
            inventory: "inventory/${params.ENVIRONMENT}/",
            vaultCredentialsId: 'ansible-vault-password',
            credentialsId: 'ssh-credentials',
            extras: "-e app_version=${params.APP_VERSION}",
            colorized: true,
            disableHostKeyChecking: true
        )
    }
}
```

---

## 05. Storing Credentials in Jenkins

### SSH Private Key

1. Go to: **Manage Jenkins** → **Credentials** → **Global**
2. Add: **SSH Username with private key**
3. Set ID: `ansible-ssh-key`
4. Paste the private key

### Ansible Vault Password

1. Add: **Secret file** or **Secret text**
2. Set ID: `ansible-vault-password`
3. Paste the vault password or upload the vault password file

### Use in Pipeline

```groovy
environment {
    // Secret text
    VAULT_PASS = credentials('ansible-vault-password')

    // SSH key
    ANSIBLE_SSH_KEY = credentials('ansible-ssh-key')
}

steps {
    sh """
        ansible-playbook site.yml \
            --vault-password-file ${VAULT_PASS} \
            --private-key ${ANSIBLE_SSH_KEY}
    """
}
```

---

## 06. Multi-Environment Pipeline

```groovy
pipeline {
    agent any

    stages {
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                ansiblePlaybook(
                    playbook: 'site.yml',
                    inventory: 'inventory/staging/',
                    vaultCredentialsId: 'vault-staging'
                )
            }
        }

        stage('Integration Tests') {
            when {
                branch 'develop'
            }
            steps {
                sh 'ansible-playbook tests/integration.yml -i inventory/staging/'
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            input {
                message "Deploy to production?"
                ok "Deploy"
            }
            steps {
                ansiblePlaybook(
                    playbook: 'site.yml',
                    inventory: 'inventory/production/',
                    vaultCredentialsId: 'vault-production'
                )
            }
        }
    }
}
```

---

## 07. `ansible.cfg` for CI/CD

```ini
# ansible.cfg for Jenkins environments
[defaults]
inventory           = inventory/
host_key_checking   = false
retry_files_enabled = false
log_path            = ansible.log
forks               = 10
timeout             = 30

# Output format for CI logs
stdout_callback     = yaml
callback_whitelist  = profile_tasks, timer

[ssh_connection]
pipelining          = true
ssh_args            = -o ControlMaster=auto -o ControlPersist=60s
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 08. Hands-on

1. Create a deployment playbook called `site.yml` that accepts `app_version` and `target_env` variables.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > site.yml << 'EOF'
   ---
   - name: Application Deployment
     hosts: all
     become: true
     gather_facts: true

     vars:
       app_version: \"{{ app_version | default('1.0.0') }}\"
       target_env: \"{{ target_env | default('development') }}\"

     tasks:
       - name: Show deployment info
         ansible.builtin.debug:
           msg:
             - \"Deploying version {{ app_version }} to {{ target_env }}\"
             - \"Target host: {{ inventory_hostname }}\"

       - name: Create deployment directory
         ansible.builtin.file:
           path: \"/opt/deployments/{{ app_version }}\"
           state: directory
           mode: \"0755\"

       - name: Create version file
         ansible.builtin.copy:
           content: |
             version={{ app_version }}
             environment={{ target_env }}
             deployed_by=ansible
           dest: \"/opt/deployments/{{ app_version }}/version.txt\"
           mode: \"0644\"

       - name: Symlink current version
         ansible.builtin.file:
           src: \"/opt/deployments/{{ app_version }}\"
           dest: /opt/deployments/current
           state: link
   EOF"
   ```

2. Simulate the Lint pipeline stage by running `ansible-lint` against `site.yml`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-lint site.yml || echo 'Lint warnings found'"
   ```

3. Simulate the Syntax Check pipeline stage.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --syntax-check"
   ```

4. Simulate the Dry Run (check mode) pipeline stage with `app_version=2.0.0` and `target_env=staging`.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check -e 'app_version=2.0.0 target_env=staging'"
   ```

5. Run the full deployment and then verify the deployed version file.

   ??? success "Solution"

   ```sh
   # Deploy
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml -e 'app_version=2.0.0 target_env=staging'"

   # Verify
   docker exec ansible-controller sh -c "cd /labs-scripts && ansible all -m command -a 'cat /opt/deployments/current/version.txt'"
   ```

---

## 09. Summary

- Jenkins' **Ansible plugin** provides `ansiblePlaybook()` for clean pipeline integration
- Store vault passwords and SSH keys as **Jenkins credentials** for security
- Use **parameterized builds** for environment and version selection
- Add **lint and syntax-check stages** before deployment as quality gates
- Enable `log_path` in `ansible.cfg` and archive the log as a build artifact
