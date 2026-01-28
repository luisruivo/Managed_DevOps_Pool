# Introduction

This project automates the deployment of files from an Azure DevOps repository to Azure Blob Storage using privately-hosted, self-managed DevOps agent pools. All infrastructure is provisioned via Terraform/Terragrunt, with state management, secrets handling, and networking configured to meet enterprise security and compliance standards.

## 🎯 Objective

Design and implement a fully automated, secure, and modular Terraform-based deployment pipeline using Azure DevOps. The solution should be suitable for deploying files from a repository to Azure Blob Storage via a secure, privately-hosted Azure DevOps agent pool.

## 🧱 Functional Requirements

- Deploy files from a specific Azure DevOps Repo directory to Blob Storage using internal networking
- Infrastructure must support dev, test, and prod environments
- Infrastructure is implemented using reusable Terraform modules
- Terraform state is stored in Azure Storage safely and locked
- All secrets and configurations are managed via Azure Key Vault
- DevOps Pools (self-hosted agents) are deployed into a private Azure VNet
- Authentication should use federated credentials and managed identities
- All environments use Principle of Least Privilege (PoLP) RBAC
- CI/CD pipelines must split plan and apply phases, with gated approvals
- Plan files must be passed as artifacts to ensure review integrity
- TF pipelines just validate/apply changes; skip apply where no diff is found
- CI must perform validation, linting, and compliance checks
- Terraform providers should have pinned versions

## 🚦Governance & Security

- Pipeline design must conform to DevOps governance model:
  - Plan vs Apply separation
  - Apply linked to ADO environment w/ Approvals
  - Manual approvals for higher environments
- Use of federated identity for Terraform execution avoids client secrets
- RBAC follows the principle of least privilege (PoLP)
- Secrets are never stored in YAML or environment variables

## 📑 Tooling & Testing

- `terraform fmt -check` and `terraform validate`
- `tfsec`, `checkov`, or similar compliance scanners integrated into CI
- Optional: Terratest for module-level testing

## 📈 CI/CD & Automation

- Branch strategy: GitFlow or Trunk-Based
- PRs trigger Terraform plan with output artifact
- Apply phase only runs after approval and uses signed plan artifact
- Automatic promotion between environments with environment-specific tfvars
- Pipeline includes failure fallback and rollback comments/logs for observability

## 📚 Documentation

- Wiki or README setup guide
- Architecture diagrams (Visio / .drawio / Mermaid)
- Developer onboarding checklist
- Troubleshooting guide and FAQ

## ✅ Deliverables

- Terraform modules in structured repository
- CI/CD pipeline YAMLs for build and release
- Approval/fluent CI/CD process demonstrating plan/apply separation
- Documentation and diagrams for onboarding and operations

## Onboarding Process: Setting Up Your Local Development and Infrastructure Environment

1. Install WSL (Ubuntu)
2. Install Azure CLI - `az login` ; `az account show` ; `az account list --output table`
3. Install Terraform and Terragrunt
4. Use Terraform Version Manager to install Terraform versions - `tfenv`:

```bash
1. Install tfenv:
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

2. Install specific version:
tfenv install 1.8.2
tfenv use 1.8.2

3. Verify:
terraform version
```

5. Install Azure DevOps extension for the Azure CLI:

```bash
1. Install Azure DevOps extension
az extension add --name azure-devops

2. Verify installation
az extension list
az extension list --output table
```

6. Install `jq`:

```bash
1. Install jq
sudo apt update
sudo apt install -y jq

2. Verify
jq --version
```

7. Install `direnv`:

```bash
1. Install direnv
sudo apt update
sudo apt install direnv

2. Verify
direnv --version
```

8. Configure shell integration for `direnv` (e.g., `~/.bashrc` for bash, `~/.zshrc` for zsh):

```bash
eval "$(direnv hook bash)"
```

9. Load the shell:

```bash
source ~/.bashrc
```

10. Create script (e.g. `update-env.sh`) to fetch secrets and generate the `.env` file:

```bash
#!/bin/bash

ENVIRONMENT=${1:-dev}

case "$ENVIRONMENT" in
  dev)
    KV_NAME="kv-dev-luis"
    ;;
  test)
    KV_NAME="kv-test-luis"
    ;;
  prod)
    KV_NAME="kv-prod-luis"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

echo "TF_VAR_pat_value=$(az keyvault secret show --vault-name $KV_NAME --name azure-devops-pat-$ENVIRONMENT --query value -o tsv)" > .env
echo "TF_VAR_admin_ssh_public_key=\"$(az keyvault secret show --vault-name $KV_NAME --name admin-ssh-public-key-$ENVIRONMENT --query value -o tsv)\"" >> .env
```

11. Make the script executable:

```markdown
chmod +x update-env.sh
```

12. Create a `.envrc` file at the root of the project:

```bash
echo "dotenv" > .envrc
```

**What this does**: The `.envrc` file tells `direnv` to automatically load environment variables from the `.env` file (which contains your Azure Key Vault secrets) whenever you enter the project directory.

**Security note**: Both `.env` and `.envrc` should be in your `.gitignore` to prevent accidental commit of secrets.

13. Run the script to generate the `.env` file for your environment (run for appropriate environment):

```bash
./update-env.sh dev
# and
./update-env.sh test
# and
./update-env.sh prod
```

14. Authorize `direnv` to load the project's environment variables:

```bash
direnv allow
```

**What this does**: This grants `direnv` permission to automatically load `.envrc` (and subsequently `.env`) when you enter the project directory. This is a security feature - `direnv` requires explicit approval before executing any environment configuration.

**Note**: You'll need to run `direnv allow` again if you modify `.envrc` in the future.

15. Create PAT on ADO and clone repo.
16. Create feature branch - please follow branching naming on under [/docs](/docs/branching/branching-strategy.md)
