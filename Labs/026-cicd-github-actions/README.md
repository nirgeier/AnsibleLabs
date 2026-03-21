---
# CI/CD with GitHub Actions

* In this lab we use **GitHub Actions** to automate Ansible playbook execution as part of a CI/CD pipeline.
* GitHub Actions provides a simple, cloud-hosted way to run Ansible workflows triggered by git events.

## What will we learn?

- Creating GitHub Actions workflows that run Ansible
- Storing vault passwords and SSH keys as GitHub Secrets
- Matrix builds for multiple environments
- Using community Ansible actions

---

## Prerequisites

- Complete [Lab 024](../024-ansible-lint/README.md#usage) in order to have working lint knowledge and a linted playbook.

---

## 01. Basic Ansible Workflow

```yaml
# .github/workflows/ansible.yml
name: Ansible Deployment

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch: # Allow manual triggers
    inputs:
      environment:
        description: "Target environment"
        required: true
        default: "staging"
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install Ansible
        run: |
          pip install ansible ansible-lint

      - name: Install collections
        run: |
          ansible-galaxy collection install -r requirements.yml

      - name: Run ansible-lint
        run: ansible-lint site.yml

      - name: Create vault password file
        run: echo "${{ secrets.ANSIBLE_VAULT_PASS }}" > /tmp/vault_pass

      - name: Set up SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.ANSIBLE_SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.TARGET_HOST }} >> ~/.ssh/known_hosts

      - name: Run playbook
        run: |
          ansible-playbook site.yml \
            -i inventory/${{ github.event.inputs.environment || 'staging' }}/ \
            --vault-password-file /tmp/vault_pass \
            -e "target_env=${{ github.event.inputs.environment || 'staging' }}"

      - name: Clean up secrets
        if: always()
        run: rm -f /tmp/vault_pass ~/.ssh/id_rsa
```

---

## 02. Lint-Only Workflow (for PRs)

```yaml
# .github/workflows/lint.yml
name: Ansible Lint

on:
  pull_request:
    branches: [main]
    paths:
      - "**.yml"
      - "**.yaml"

jobs:
  lint:
    runs-on: ubuntu-latest
    name: Lint Ansible code

    steps:
      - name: Checkout
        uses: actions/checkout@v5
        with:
          fetch-depth: 0

      - name: Run ansible-lint
        uses: ansible/ansible-lint@v24
        with:
          args: "--profile moderate"
```

---

## 03. Matrix Builds - Multiple Environments

```yaml
# .github/workflows/matrix-deploy.yml
name: Deploy to Multiple Environments

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        environment: [dev, staging]
        include:
          - environment: dev
            host_group: dev_servers
          - environment: staging
            host_group: staging_servers
      fail-fast: false # Continue other matrix jobs if one fails

    environment: ${{ matrix.environment }} # GitHub environment with protection rules

    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Install Ansible
        run: pip install ansible

      - name: Deploy to ${{ matrix.environment }}
        run: |
          ansible-playbook site.yml \
            -i inventory/${{ matrix.environment }}/ \
            -e "target_env=${{ matrix.environment }}"
        env:
          ANSIBLE_HOST_KEY_CHECKING: "false"
```

---

## 04. Self-Hosted Runner Setup

For accessing private networks:

```yaml
# .github/workflows/private-deploy.yml
name: Deploy to Private Network

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: self-hosted # Use your own runner
    labels: [ansible, linux] # Runner with ansible installed

    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Run playbook (private network access)
        run: |
          ansible-playbook site.yml \
            -i inventory/production/ \
            --vault-password-file ~/.vault_pass
```

---

## 05. GitHub Secrets Setup

Required secrets for the workflows above:

| Secret Name               | Description                        |
| ------------------------- | ---------------------------------- |
| `ANSIBLE_VAULT_PASS`      | The Ansible Vault password         |
| `ANSIBLE_SSH_PRIVATE_KEY` | SSH private key for managed hosts  |
| `TARGET_HOST`             | Hostname for SSH known_hosts setup |

```sh
# Set secrets via GitHub CLI
gh secret set ANSIBLE_VAULT_PASS --body "my-vault-password"
gh secret set ANSIBLE_SSH_PRIVATE_KEY < ~/.ssh/ansible_key

# Or via GitHub UI:
# Repository → Settings → Secrets and variables → Actions → New repository secret
```

---

## 06. Using the Official Ansible Action

```yaml
- name: Run Ansible Playbook
  uses: dawidd6/action-ansible-playbook@v2
  with:
    playbook: site.yml
    directory: ./
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    inventory: |
      [webservers]
      ${{ secrets.DEPLOY_HOST }}

    options: |
      --vault-password-file /tmp/vault_pass
      --extra-vars "env=production version=${{ github.sha }}"
```

---

## 07. Workflow with Notifications

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Deploy
        id: deploy
        run: ansible-playbook site.yml -i inventory/

      - name: Notify Slack on success
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment to production succeeded!\nCommit: ${{ github.sha }}\nRun: ${{ github.run_url }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

      - name: Notify Slack on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment FAILED!\nCommit: ${{ github.sha }}\nRun: ${{ github.run_url }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

<img src="../assets/images/practice.png" alt="Practice" width="800"/>

## 08. Hands-on

1. Create the `.github/workflows/` directory structure and a lint workflow file.

   ??? success "Solution"

   ```sh
   mkdir -p .github/workflows

   cat > .github/workflows/ansible-lint.yml << 'EOF'
   name: Ansible Lint and Syntax Check

   on:
     push:
     pull_request:

   jobs:
     lint:
       runs-on: ubuntu-latest
       steps:
         - name: Checkout
           uses: actions/checkout@v5

         - name: Install Ansible and lint
           run: |
             pip install ansible ansible-lint

         - name: Run ansible-lint
           run: ansible-lint site.yml || true

         - name: Syntax check
           run: ansible-playbook site.yml --syntax-check -i "localhost,"
   EOF
   ```

2. Create a manual deployment workflow with environment selection (`staging` or `production`).

   ??? success "Solution"

   ```sh
   cat > .github/workflows/deploy.yml << 'EOF'
   name: Deploy

   on:
     workflow_dispatch:
       inputs:
         environment:
           description: 'Environment to deploy'
           required: true
           default: 'staging'
           type: choice
           options:
             - staging
             - production

   jobs:
     deploy:
       runs-on: ubuntu-latest
       environment: ${{ inputs.environment }}

       steps:
         - name: Checkout
           uses: actions/checkout@v5

         - name: Install Ansible
           run: pip install ansible

         - name: Show deployment info
           run: |
             echo "Deploying to: ${{ inputs.environment }}"
             echo "Triggered by: ${{ github.actor }}"
             echo "Commit SHA: ${{ github.sha }}"
             ansible --version
   EOF
   ```

3. Test the lint and syntax check steps locally before pushing.

   ??? success "Solution"

   ```sh
   # Install tools
   pip install ansible ansible-lint

   # Run lint
   ansible-lint site.yml

   # Run syntax check
   ansible-playbook site.yml --syntax-check -i "localhost,"
   ```

4. Add a workflow that runs `ansible-lint` on all playbooks before deployment.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && mkdir -p .github/workflows && cat > .github/workflows/lint.yml << 'EOF'
   name: Ansible Lint

   on:
     pull_request:
       paths:
         - '**.yml'
         - '**.yaml'

   jobs:
     lint:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v5

         - name: Set up Python
           uses: actions/setup-python@v5
           with:
             python-version: '3.11'

         - name: Install ansible-lint
           run: pip install ansible-lint

         - name: Run ansible-lint
           run: ansible-lint --profile production *.yml
           continue-on-error: false
   EOF"
   ```

   Expected: This workflow triggers on PRs that touch YAML files, ensuring all playbooks pass lint checks before merging.

5. Create a workflow that uses matrix strategy to test a playbook against multiple Ansible versions.

   ??? success "Solution"

   ```sh
   docker exec ansible-controller sh -c "cd /labs-scripts && cat > .github/workflows/matrix-test.yml << 'EOF'
   name: Test Multiple Ansible Versions

   on:
     push:
       branches: [main]

   jobs:
     test:
       runs-on: ubuntu-latest
       strategy:
         matrix:
           ansible-version: ['2.15.*', '2.16.*', '2.17.*']
         fail-fast: false

       steps:
         - uses: actions/checkout@v5

         - name: Set up Python
           uses: actions/setup-python@v5
           with:
             python-version: '3.11'

         - name: Install Ansible \${{ matrix.ansible-version }}
           run: pip install \"ansible==\${{ matrix.ansible-version }}\"

         - name: Show Ansible version
           run: ansible --version

         - name: Syntax check playbooks
           run: |
             for playbook in *.yml; do
               echo \"Checking: \$playbook\"
               ansible-playbook \"\$playbook\" --syntax-check -i localhost, || true
             done
   EOF"
   ```

   Expected: Tests run in parallel across all three Ansible versions, ensuring forward compatibility.

---

## 09. Summary

- GitHub Actions workflows (`.github/workflows/*.yml`) define CI/CD pipelines triggered by git events
- Store sensitive data (vault pass, SSH keys) as **GitHub Secrets** - never in code
- **Matrix builds** test multiple environments in parallel
- The `ansible/ansible-lint` community action makes linting straightforward
- Add `workflow_dispatch` for **manual deployments** with parameter selection
- Use **GitHub Environments** for deployment protection rules (approvals, wait timers)
