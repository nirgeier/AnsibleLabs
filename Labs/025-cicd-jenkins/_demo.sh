#!/bin/bash

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# Load the common script
source $ROOT_FOLDER/_utils/common.sh

# Spin up the docker containers
source $ROOT_FOLDER/Labs/000-setup/01-init-servers.sh 2>&1 > /dev/null
source $ROOT_FOLDER/Labs/000-setup/02-init-ansible.sh 2>&1 > /dev/null

clear

echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 025 - CI/CD with Jenkins${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Note: Jenkins cannot run locally - we simulate the pipeline stages${COLOR_OFF}"

# Step 1: Create the site.yml playbook that Jenkins would deploy
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create site.yml (the playbook Jenkins would run)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/site.yml << 'EOF'
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
        force: true
EOF"

echo -e "${GREEN}$ cat site.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat site.yml"

# Step 2: Create the Jenkinsfile
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: Create Jenkinsfile showing the full pipeline definition${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/Jenkinsfile << 'EOF'
// Jenkinsfile - Ansible Deployment Pipeline
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
            defaultValue: '1.0.0',
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
                sh \"\"\"
                    ansible-playbook site.yml \\
                        --syntax-check \\
                        -i inventory/\${params.ENVIRONMENT}/
                \"\"\"
            }
        }

        stage('Deploy Staging') {
            when { expression { params.ENVIRONMENT == 'staging' } }
            steps {
                script {
                    def checkMode = params.DRY_RUN ? '--check' : ''
                    sh \"\"\"
                        ansible-playbook site.yml \\
                            -i inventory/staging/ \\
                            \${checkMode} \\
                            --vault-password-file \${ANSIBLE_VAULT_PASS} \\
                            -e \"app_version=\${params.APP_VERSION}\" \\
                            -e \"target_env=staging\"
                    \"\"\"
                }
            }
        }

        stage('Deploy Production') {
            when { expression { params.ENVIRONMENT == 'production' } }
            input { message "Deploy to production?" }
            steps {
                sh \"\"\"
                    ansible-playbook site.yml \\
                        -i inventory/production/ \\
                        --vault-password-file \${ANSIBLE_VAULT_PASS} \\
                        -e \"app_version=\${params.APP_VERSION}\" \\
                        -e \"target_env=production\"
                \"\"\"
            }
        }
    }

    post {
        success { echo "Deployment to \${params.ENVIRONMENT} succeeded!" }
        failure { echo "Deployment failed! Check the console output." }
        always  { archiveArtifacts artifacts: 'ansible.log', allowEmptyArchive: true }
    }
}
EOF"

# Step 3: Simulate Jenkins Lint stage
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Simulate Jenkins 'Lint' stage${COLOR_OFF}"
echo -e "${GREEN}$ ansible-lint site.yml || true${COLOR_OFF}"
docker exec ansible-controller sh -c "pip3 install ansible-lint --quiet && cd /labs-scripts && ansible-lint site.yml || true"

# Step 4: Simulate Jenkins Syntax Check stage
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Simulate Jenkins 'Syntax Check' stage${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook site.yml --syntax-check${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --syntax-check"

# Step 5: Simulate Jenkins Deploy stage (dry run / check mode)
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: Simulate Jenkins 'Deploy Staging' stage (DRY_RUN=true)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook site.yml --check -e 'app_version=2.0.0 target_env=staging'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check -e 'app_version=2.0.0 target_env=staging'"

# Step 6: Show the Jenkinsfile content
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 6: Show the Jenkinsfile pipeline definition${COLOR_OFF}"
echo -e "${GREEN}$ cat Jenkinsfile${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && cat Jenkinsfile"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 025 - Complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
