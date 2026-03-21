---

# CI/CD with GitLab CI

* In this lab we integrate Ansible with **GitLab CI/CD** to run playbooks automatically when code is pushed or merged.
* GitLab CI offers tight integration with GitLab repositories, including environment management and protected branches.

## What will we learn?

- Creating `.gitlab-ci.yml` pipelines for Ansible
- Storing secrets as GitLab CI/CD variables
- Multi-stage pipelines (lint → test → deploy)
- Using GitLab Environments for deployment tracking

---

## Prerequisites

- Complete [Lab 024](../024-ansible-lint/README.md#usage) in order to have working lint knowledge and a linted playbook.

---

## 01. Basic `.gitlab-ci.yml`

```yaml
# .gitlab-ci.yml
image: python:3.12-slim

variables:
  ANSIBLE_FORCE_COLOR: "1"
  ANSIBLE_HOST_KEY_CHECKING: "false"

before_script:
  - pip install ansible ansible-lint
  - ansible-galaxy collection install -r requirements.yml
  - ansible --version

stages:
  - lint
  - test
  - deploy

lint:
  stage: lint
  script:
    - ansible-lint site.yml
    - ansible-playbook site.yml --syntax-check -i "localhost,"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH

test:
  stage: test
  script:
    - ansible-playbook site.yml --check -i inventory/staging/
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy-staging:
  stage: deploy
  script:
    - echo "$VAULT_PASSWORD" > /tmp/vault_pass
    - chmod 600 /tmp/vault_pass
    - mkdir -p ~/.ssh
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ansible-playbook site.yml
      -i inventory/staging/
      --vault-password-file /tmp/vault_pass
  environment:
    name: staging
    url: https://staging.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"
  after_script:
    - rm -f /tmp/vault_pass ~/.ssh/id_rsa

deploy-production:
  stage: deploy
  script:
    - echo "$VAULT_PASSWORD_PROD" > /tmp/vault_pass
    - chmod 600 /tmp/vault_pass
    - mkdir -p ~/.ssh
    - echo "$SSH_PRIVATE_KEY_PROD" | tr -d '\r' > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - ansible-playbook site.yml
      -i inventory/production/
      --vault-password-file /tmp/vault_pass
  environment:
    name: production
    url: https://example.com
  when: manual # Require manual approval
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  after_script:
    - rm -f /tmp/vault_pass ~/.ssh/id_rsa
```

---

## 02. Using a Custom Docker Image

```dockerfile
# Dockerfile.ansible
FROM python:3.12-slim

RUN pip install ansible ansible-lint \
    && ansible-galaxy collection install community.general community.docker

WORKDIR /ansible
```

```yaml
# .gitlab-ci.yml with custom image
image: registry.gitlab.com/myorg/ansible-runner:latest

# Or build it in CI
build-runner:
  stage: .pre
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE/ansible-runner:$CI_COMMIT_SHA -f Dockerfile.ansible .
    - docker push $CI_REGISTRY_IMAGE/ansible-runner:$CI_COMMIT_SHA
  rules:
    - changes:
        - Dockerfile.ansible
        - requirements.yml
```

---

## 03. Multi-Stage Pipeline with Molecule

```yaml
# .gitlab-ci.yml with Molecule testing
stages:
  - lint
  - molecule-test
  - integration-test
  - deploy

variables:
  DOCKER_DRIVER: overlay2

lint:
  stage: lint
  image: python:3.12-slim
  script:
    - pip install ansible-lint
    - ansible-lint
  rules:
    - if: $CI_MERGE_REQUEST_ID

molecule-default:
  stage: molecule-test
  image: python:3.12-slim
  services:
    - docker:24-dind
  variables:
    DOCKER_HOST: tcp://docker:2375
  before_script:
    - pip install molecule[docker] ansible
  script:
    - cd roles/nginx
    - molecule test
  rules:
    - if: $CI_COMMIT_BRANCH
      changes:
        - roles/nginx/**/*

integration-test:
  stage: integration-test
  script:
    - ansible-playbook tests/integration.yml -i inventory/test/
  environment:
    name: test
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy:
  stage: deploy
  script:
    - ansible-playbook site.yml -i inventory/production/
  environment:
    name: production
  when: manual
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

---

## 04. GitLab CI/CD Variables

Set these in **Project → Settings → CI/CD → Variables**:

| Variable          | Type     | Description                      |
| ----------------- | -------- | -------------------------------- |
| `VAULT_PASSWORD`  | Variable | Ansible Vault password (masked)  |
| `SSH_PRIVATE_KEY` | Variable | SSH private key (masked, base64) |
| `STAGING_HOST`    | Variable | Staging server hostname/IP       |
| `PROD_HOST`       | Variable | Production server hostname/IP    |

```yaml
# Use in CI scripts
before_script:
  - echo "$VAULT_PASSWORD" > /tmp/.vault_pass
  - chmod 600 /tmp/.vault_pass
  - mkdir -p ~/.ssh
  - echo "$SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa
  - chmod 600 ~/.ssh/id_rsa
```

---

## 05. GitLab Environments

```yaml
# Track deployments in GitLab's Environments UI
deploy-staging:
  script:
    - ansible-playbook site.yml -i inventory/staging/
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop-staging # Reference the stop job

stop-staging:
  script:
    - ansible-playbook teardown.yml -i inventory/staging/
  environment:
    name: staging
    action: stop
  when: manual
```

---

## 06. `ansible-runner` for Better Integration

```yaml
# Using ansible-runner for better GitLab integration
deploy-with-runner:
  image: quay.io/ansible/ansible-runner:latest
  script:
    - ansible-runner run /runner --playbook site.yml
  artifacts:
    paths:
      - /runner/artifacts/
    reports:
      junit: /runner/artifacts/*/job_events/*-runner_on_ok.json
    expire_in: 1 week
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 07. Hands-on

1. Create a `.gitlab-ci.yml` with four stages: `lint`, `syntax-check`, `dry-run`, and `deploy`.

   ??? success "Solution"

   ```sh
   cat > .gitlab-ci.yml << 'EOF'
   image: python:3.12-slim

   variables:
     ANSIBLE_FORCE_COLOR: "1"
     ANSIBLE_HOST_KEY_CHECKING: "false"

   stages:
     - lint
     - syntax-check
     - dry-run
     - deploy

   before_script:
     - pip install ansible ansible-lint --quiet
     - ansible --version

   lint:
     stage: lint
     script:
       - ansible-lint site.yml

   syntax-check:
     stage: syntax-check
     script:
       - ansible-playbook site.yml --syntax-check -i "localhost,"

   dry-run:
     stage: dry-run
     script:
       - ansible-playbook site.yml --check -i inventory/
     rules:
       - if: $CI_COMMIT_BRANCH != "main"

   deploy:
     stage: deploy
     script:
       - ansible-playbook site.yml -i inventory/
     environment:
       name: production
     when: manual
     rules:
       - if: $CI_COMMIT_BRANCH == "main"
   EOF
   ```

2. Simulate each pipeline stage locally before pushing to GitLab.

   ??? success "Solution"

   ```sh
   # Install tools
   pip install ansible ansible-lint

   # Lint stage
   ansible-lint site.yml

   # Syntax-check stage
   ansible-playbook site.yml --syntax-check -i "localhost,"

   # Dry-run stage
   ansible-playbook site.yml --check -i inventory/
   ```

3. Commit and push the pipeline file to trigger it in GitLab.

   ??? success "Solution"

   ```sh
   git add .gitlab-ci.yml
   git commit -m "Add GitLab CI pipeline for Ansible"
   git push origin develop

   ### Output
   # Open GitLab → CI/CD → Pipelines to view the running pipeline
   ```

4. Add a GitLab CI job that runs `ansible-lint` and fails the pipeline if violations are found.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat >> .gitlab-ci.yml << 'EOF'

   lint:
     stage: test
     image: pipelinecomponents/ansible-lint:latest
     script:
       - ansible-lint --profile production *.yml
     rules:
       - if: '\$CI_PIPELINE_SOURCE == \"merge_request_event\"'
       - if: '\$CI_COMMIT_BRANCH == \$CI_DEFAULT_BRANCH'
   EOF"
   ```

   Expected: The lint job runs on MR and main branch, rejecting playbooks that violate best practices.

5. Create a multi-environment GitLab CI pipeline with `staging` → `production` gates using manual approval.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > .gitlab-ci-multi-env.yml << 'EOF'
   stages:
     - lint
     - deploy-staging
     - deploy-production

   variables:
     ANSIBLE_FORCE_COLOR: \"true\"

   lint:
     stage: lint
     image: cytopia/ansible:latest
     script:
       - ansible-playbook site.yml --syntax-check -i inventory/staging/

   deploy-staging:
     stage: deploy-staging
     image: cytopia/ansible:latest
     environment:
       name: staging
       url: https://staging.example.com
     before_script:
       - ansible-galaxy install -r requirements.yml || true
     script:
       - ansible-playbook site.yml -i inventory/staging/ --diff
     rules:
       - if: '\$CI_COMMIT_BRANCH == \$CI_DEFAULT_BRANCH'

   deploy-production:
     stage: deploy-production
     image: cytopia/ansible:latest
     environment:
       name: production
       url: https://example.com
     script:
       - ansible-playbook site.yml -i inventory/production/ --diff
     rules:
       - if: '\$CI_COMMIT_BRANCH == \$CI_DEFAULT_BRANCH'
         when: manual   # Requires manual approval
     allow_failure: false
   EOF"
   ```

---

## 08. Summary

- `.gitlab-ci.yml` defines stages: **lint → test → deploy** in a GitLab pipeline
- Store secrets in **GitLab CI/CD Variables** (masked and protected)
- Use `when: manual` for deployment stages to require human approval
- **GitLab Environments** track deployment history and provide rollback options
- Use a custom Docker image with Ansible pre-installed for faster pipelines
- `ansible-runner` provides better artifact management and reporting
