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
echo -e "${CYAN}Lab 027 - CI/CD with GitLab CI${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Note: GitLab CI cannot run locally - we create the pipeline file${COLOR_OFF}"
echo -e "${CYAN}      and simulate each pipeline stage inside the controller${COLOR_OFF}"

# Step 1: Create the .gitlab-ci.yml pipeline file
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 1: Create .gitlab-ci.yml pipeline configuration${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/.gitlab-ci.yml << 'EOF'
# .gitlab-ci.yml - Ansible Deployment Pipeline
image: python:3.12-slim

variables:
  ANSIBLE_FORCE_COLOR: \"1\"
  ANSIBLE_HOST_KEY_CHECKING: \"false\"

before_script:
  - pip install ansible ansible-lint --quiet
  - ansible --version

stages:
  - lint
  - syntax-check
  - dry-run
  - deploy

lint:
  stage: lint
  script:
    - ansible-lint site.yml
  rules:
    - if: \$CI_PIPELINE_SOURCE == \"merge_request_event\"
    - if: \$CI_COMMIT_BRANCH

syntax-check:
  stage: syntax-check
  script:
    - ansible-playbook site.yml --syntax-check

dry-run:
  stage: dry-run
  script:
    - ansible-playbook site.yml --check -e \"target_env=staging\"
  rules:
    - if: \$CI_COMMIT_BRANCH != \"main\"

deploy-staging:
  stage: deploy
  script:
    - ansible-playbook site.yml -e \"target_env=staging\"
  environment:
    name: staging
    url: https://staging.example.com
  rules:
    - if: \$CI_COMMIT_BRANCH == \"develop\"

deploy-production:
  stage: deploy
  script:
    - ansible-playbook site.yml -e \"target_env=production\"
  environment:
    name: production
    url: https://example.com
  when: manual
  rules:
    - if: \$CI_COMMIT_BRANCH == \"main\"
EOF"

echo -e "${GREEN}$ cat .gitlab-ci.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/.gitlab-ci.yml"

# Step 2: Create multi-environment pipeline configuration
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 2: Create .gitlab-ci-multi-env.yml (multi-environment pipeline)${COLOR_OFF}"
docker exec ansible-controller sh -c "cat > /labs-scripts/.gitlab-ci-multi-env.yml << 'EOF'
# .gitlab-ci-multi-env.yml - Multi-Environment Ansible Pipeline
stages:
  - lint
  - deploy-staging
  - deploy-production

variables:
  ANSIBLE_FORCE_COLOR: \"1\"

lint:
  stage: lint
  image: python:3.12-slim
  before_script:
    - pip install ansible ansible-lint --quiet
  script:
    - ansible-lint site.yml || true
    - ansible-playbook site.yml --syntax-check

deploy-staging:
  stage: deploy-staging
  image: python:3.12-slim
  before_script:
    - pip install ansible --quiet
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - ansible-playbook site.yml -e \"target_env=staging\" --diff
  rules:
    - if: \$CI_COMMIT_BRANCH == \$CI_DEFAULT_BRANCH

deploy-production:
  stage: deploy-production
  image: python:3.12-slim
  before_script:
    - pip install ansible --quiet
  environment:
    name: production
    url: https://example.com
  script:
    - ansible-playbook site.yml -e \"target_env=production\" --diff
  rules:
    - if: \$CI_COMMIT_BRANCH == \$CI_DEFAULT_BRANCH
      when: manual
  allow_failure: false
EOF"

echo -e "${GREEN}$ cat .gitlab-ci-multi-env.yml${COLOR_OFF}"
docker exec ansible-controller sh -c "cat /labs-scripts/.gitlab-ci-multi-env.yml"

# Ensure site.yml exists
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Ensuring site.yml exists for pipeline simulation...${COLOR_OFF}"
docker exec ansible-controller sh -c "[ -f /labs-scripts/site.yml ] || cat > /labs-scripts/site.yml << 'EOF'
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
EOF"

# Step 3: Simulate GitLab CI - lint stage
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 3: Simulate GitLab CI 'lint' stage${COLOR_OFF}"
echo -e "${GREEN}$ ansible-lint site.yml || true${COLOR_OFF}"
docker exec ansible-controller sh -c "pip3 install ansible-lint --quiet && cd /labs-scripts && ansible-lint site.yml || true"

# Step 4: Simulate GitLab CI - syntax-check stage
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 4: Simulate GitLab CI 'syntax-check' stage${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook site.yml --syntax-check${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --syntax-check"

# Step 5: Simulate GitLab CI - dry-run stage
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Step 5: Simulate GitLab CI 'dry-run' stage (--check mode)${COLOR_OFF}"
echo -e "${GREEN}$ ansible-playbook site.yml --check -e 'target_env=staging'${COLOR_OFF}"
docker exec ansible-controller sh -c "cd /labs-scripts && ansible-playbook site.yml --check -e 'target_env=staging'"

# Step 6: Show pipeline stages summary
echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}GitLab CI pipeline stages summary:${COLOR_OFF}"
echo -e "${GREEN}  Stage 1: lint          - ansible-lint validates playbook quality${COLOR_OFF}"
echo -e "${GREEN}  Stage 2: syntax-check  - ansible-playbook --syntax-check validates YAML${COLOR_OFF}"
echo -e "${GREEN}  Stage 3: dry-run       - ansible-playbook --check runs without changes${COLOR_OFF}"
echo -e "${GREEN}  Stage 4: deploy        - actual deployment (manual gate for production)${COLOR_OFF}"

echo -e ""
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
echo -e "${CYAN}Lab 027 - Complete!${COLOR_OFF}"
echo -e "${YELLOW}-----------------------------------${COLOR_OFF}"
