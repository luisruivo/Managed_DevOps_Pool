# Azure Pipelines Structure

This project contains three pipelines: `bootstrap-pipeline.yaml` `build.yaml` and `deployment.yaml`.

**Bootstrap** pipeline should only be used for the initial deployment of bootstrap and infra layer.

**Build** pipeline runs on every push and PR targeting the `main` branch. This pipeline focus on lint, validate, terragrunt plan and publish an artifact if the plan is successful.

**Deployment** pipeline runs after PR is merged to provision the infrastructure. Downloads the artifact from and shows the previous successful build (using the buildID), waits for a manual approval and deploys the infrastructure.

## Pipeline Workflow

```markdown
1. Push code to repo → Build Pipeline runs
                     ↓
2. PR created → Build Pipeline runs → Publish Artifact
                     ↓
3. PR approved → Deployment Pipeline runs → Download Artifact → Manual Approval → Deploy Dev
                     ↓
4. If Dev succeeds → Deploy to Test → Create RC Tag
                     ↓
4. If RC Tag is created → Deploy to Prod → Promote RC to Stable Tag
```

## Pipeline Security

This project follows a secure and organized strategy for managing pipeline secrets in Azure DevOps. It stores secrets in Azure Key Vault via variable groups. This way it keeps sensitive data encrypted, auditable, and not hardcoded in YAML or code.

## 🔒 Security Scanning with Checkov

This project uses **[Checkov](https://www.checkov.io/)** to automatically scan infrastructure-as-code (IaC) for security vulnerabilities, compliance issues, and misconfigurations **before** deployment.

### How Checkov Works in This Project

Checkov runs as part of the **Build Pipeline** (`build.yaml`) during the **Lint & Validate** stage, **before** any infrastructure is deployed.

#### Scan Scope

| File Type | What Checkov Scans | Status |
|-----------|-------------------|--------|
| **`.tf` files** | Terraform configuration files | ✅ **Scanned** |
| **`.hcl` files** | Terragrunt configuration files (not supported by Checkov) | ❌ **Not scanned** |

**Example:**

```bash
# ✅ Checkov SCANS this:
infrastructure/modules/storage-account/main.tf
infrastructure/modules/networking/main.tf
infrastructure/modules/key-vault/main.tf

# ❌ Checkov DOES NOT scan this:
infrastructure/layers/infra/environments/dev/terragrunt.hcl
infrastructure/layers/bootstrap/environments/root.hcl
```

#### Pipeline Integration

Checkov is integrated into the build pipeline at **`azure-pipelines/templates/security-scan.yaml`** and runs automatically on:

1. **Every push** to any branch
2. **Every pull request** targeting `main`
3. **Before** `terragrunt plan` executes

**Pipeline Flow:**

```markdown
Build Pipeline (build.yaml)
  ↓
Lint & Validate Stage
  ↓
security-scan.yaml ← Checkov runs here
  ↓
✅ If passed → Continue to Terragrunt Plan
❌ If failed → Pipeline warns (does not fail by default)
```

### What Checkov Detects

Checkov scans Terraform files for common Azure security issues:

#### Example Checks Performed

| Check ID | Security Issue | Severity | Resource Type |
|----------|---------------|----------|---------------|
| `CKV2_AZURE_18` | Network Security Groups should have rules attached | MEDIUM | `azurerm_network_security_group` |
| `CKV2_AZURE_40` | Storage accounts should not use Shared Key authorization | MEDIUM | `azurerm_storage_account` |
| `CKV_AZURE_49` | Virtual machines should use SSH keys instead of passwords | MEDIUM | `azurerm_linux_virtual_machine_scale_set` |
| `CKV_AZURE_97` | Virtual machine scale sets should have encryption at host enabled | MEDIUM | `azurerm_linux_virtual_machine_scale_set` |
| `CKV_AZURE_109` | Key Vault should have firewall rules configured | MEDIUM | `azurerm_key_vault` |
| `CKV_AZURE_189` | Key Vault should disable public network access | HIGH | `azurerm_key_vault` |
| `CKV_AZURE_190` | Storage blobs should restrict public access | HIGH | `azurerm_storage_container` |

[Checkov Check ID list](https://www.checkov.io/5.Policy%20Index/arm.html)

### Scan Output

When Checkov runs, you'll see detailed output in the pipeline logs:

```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Checkov Security Scan Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Scan Summary:

  ✅ Passed checks:  28
  ❌ Failed checks:  21
  ⏭️  Skipped checks: 0
  📦 Resources scanned: 52

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Files Analyzed by Checkov:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📊 File Analysis Summary:
    ┌─────────────────────────────────────────────┐
    │                    .tf files                │
    ├─────────────────────────────────────────────┤
    │  Total in workspace:        51              │
    │  With security checks:      6               │
    │  No checks (variables/etc): 45              │
    └─────────────────────────────────────────────┘

  ✅ .tf files with security checks:
     • /modules/azure_devops_pools/vmss-agent-pool/main.tf
     • /modules/azure_devops_pools/vmss-classic-pool/main.tf
     • /modules/bastion-jump/main.tf
     • /modules/identity/oidc-role/main.tf
     • /modules/key-vault/main.tf
     • /modules/storage-account/main.tf

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 All Security Issues Grouped by File:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 File #1: /modules/azure_devops_pools/vmss-agent-pool/main.tf
   Issues found: 5

  ❌ CKV_AZURE_97: Ensure that Virtual machine scale sets have encryption at host enabled
     Line: 52
     Resource: module.vmss_agent_pool.azurerm_linux_virtual_machine_scale_set.vmss_agent_pool

  ❌ CKV_AZURE_49: Ensure Azure linux scale set does not use basic authentication
     Line: 52
     Resource: module.vmss_agent_pool.azurerm_linux_virtual_machine_scale_set.vmss_agent_pool

  ... (3 more issues)
```

### Viewing Security Reports

Checkov generates multiple report formats for different use cases:

#### 1. **Pipeline Logs** (Console Output)

- View in Azure DevOps pipeline run logs
- Shows all security issues grouped by file
- Includes file paths, line numbers, and resource names

#### 2. **Tests Tab** (Azure DevOps)

- Navigate to: `Pipeline Run → Tests Tab`
- All 21 failed checks displayed individually
- Click on any test to see:
  - File path and line number
  - Check ID and description
  - Resource name
  - Remediation guidance

#### 3. **Artifacts** (Downloadable Reports)

Three report formats are published as pipeline artifacts:

| Artifact Name | File | Format | Use Case |
|---------------|------|--------|----------|
| `checkov-security-reports-{env}` | `results_json.json` | JSON | Programmatic analysis, metrics, CI/CD integration |
| `checkov-security-reports-{env}` | `results_junitxml.xml` | JUnit XML | Test result visualization in Azure DevOps |
| `checkov-security-reports-{env}` | `checkov-output.txt` | Plain text | Full verbose Checkov output |

**To download artifacts:**

1. Go to your pipeline run in Azure DevOps
2. Click **Artifacts**
3. Download `checkov-security-reports-dev` (or `test`/`prod`)
4. Extract and review the reports

### Security Scan Configuration

The security scan behavior is controlled by parameters in `build.yaml`:

```yaml
# build.yaml
- template: templates/lint-and-validate.yaml
  parameters:
    failOnSecurityFindings: false  # ← Controls if pipeline fails on security issues
```

**Current Configuration:**

- ✅ **Soft-fail mode enabled** (`failOnSecurityFindings: false`)
- ⚠️ Security issues are **reported** but do **not block** the pipeline
- Developers can review and fix issues incrementally

**To enable hard-fail mode**:

```yaml
failOnSecurityFindings: true  # Pipeline will fail if security issues are found
```

### Limitations & Known Gaps

#### ❌ Terragrunt `.hcl` Files Are NOT Scanned by Checkov

Checkov **cannot** scan Terragrunt configuration files `.hcl` because they contain **variable assignments**, not **resource definitions**.

**Example:**

```hcl
# ❌ Checkov CANNOT detect this security issue:
# infrastructure/layers/infra/environments/root.hcl

nsg_configs = {
  public = {
    rules = [{
      source_address_prefix = "Internet"  # ← Allows unrestricted Internet access!
    }]
  }
}
```

**Why this matters:**

- `root.hcl` files may contain **insecure values** (e.g., `"Internet"` as NSG source)
- These values are **passed to modules** at runtime
- Checkov only sees the **module's variable reference** (`var.source_address_prefix`), not the actual value

**✅ Mitigation: Custom HCL Security Validation**

To address this gap, this project includes a **custom HCL security validation script** that scans Terragrunt `.hcl` files for common security anti-patterns.

**Custom HCL Validator:**
- **Template:** [`azure-pipelines/templates/hcl-security-scan.yaml`](azure-pipelines/templates/hcl-security-scan.yaml)
- **Runs:** Automatically as part of the Build Pipeline
- **Scans:** All `root.hcl` and `terragrunt.hcl` files in `infrastructure/layers/`

**Security Rules Enforced:**

| Rule ID | Security Check | Severity | Example |
|---------|----------------|----------|---------|
| `HCL-001` | No unrestricted Internet access in NSG rules | HIGH | `source_address_prefix = "Internet"` |
| `HCL-002` | Disable public network access (environment-aware) | CRITICAL (prod) / HIGH (dev/test) | `public_network_access_enabled = true` |
| `HCL-003` | Enable encryption at host | MEDIUM | `encryption_at_host_enabled = false` |
| `HCL-004` | Disable password authentication (use SSH keys) | HIGH | `disable_password_authentication = false` |
| `HCL-005` | Storage Account network should deny by default | HIGH | `default_action = "Allow"` |
| `HCL-006` | Enforce TLS 1.2 or higher | MEDIUM | `min_tls_version = "TLS1_0"` |
| `HCL-007` | Enforce HTTPS-only access | HIGH | `https_only = false` |
| `HCL-008` | Require secure transfer for Storage Accounts | HIGH | `enable_https_traffic_only = false` |
| `HCL-009` | No secrets in environment variables (without TF_VAR_ prefix) | HIGH | `get_env("ADMIN_PASSWORD", "")` |
| `HCL-010` | Enable RBAC authorization for Key Vault | HIGH | `enable_rbac_authorization = false` |
| `HCL-011` | Enable purge protection (environment-aware) | CRITICAL (prod) / MEDIUM (dev/test) | `purge_protection_enabled = false` |
| `HCL-012` | Restrict DevOps pool access (environment-aware) | HIGH (prod) / MEDIUM (dev/test) | `open_access = true` |
| `HCL-013` | Avoid always-on instances in non-production | LOW | `vmss_instance_count = 2` (in dev/test) |
| `HCL-014` | Production-specific hardening checks | CRITICAL | Multiple production-only validations |

**Example HCL Scan Output:**

```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Security Scan Terragrunt HCL - DEV
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Environment: dev

🔍 Scanning Terragrunt HCL files for security issues...

📁 Found 8 HCL files to scan

📋 Rule HCL-001: Checking NSG rules for unrestricted Internet access...
📋 Rule HCL-002: Checking for public network access...
📋 Rule HCL-003: Checking for disabled encryption at host...
📋 Rule HCL-004: Checking for password authentication...
📋 Rule HCL-005: Checking Storage Account network configuration...
📋 Rule HCL-006: Checking TLS version configuration...
📋 Rule HCL-007: Checking HTTPS enforcement...
📋 Rule HCL-008: Checking secure transfer requirement...
📋 Rule HCL-009: Checking for secrets in environment variables...
📋 Rule HCL-010: Checking RBAC authorization...
📋 Rule HCL-011: Checking purge protection...
📋 Rule HCL-012: Checking DevOps pool access controls...
📋 Rule HCL-013: Checking for always-on instances...
📋 Rule HCL-014: Enforcing production security hardening...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ Found 3 security issue(s) in HCL files:

📊 Issues by Severity:
  🔴 CRITICAL: 0
  🟠 HIGH:     2
  🟡 MEDIUM:   1

📄 Detailed Issues:
[HIGH] HCL-001: NSG rule allows unrestricted Internet ingress
  File: infrastructure/layers/infra/environments/root.hcl:77

[HIGH] HCL-004: Password authentication is enabled (use SSH keys instead)
  File: infrastructure/layers/infra/environments/root.hcl:164

[MEDIUM] HCL-003: Encryption at host is disabled
  File: infrastructure/layers/infra/environments/root.hcl:203

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  HCL security issues found (not failing pipeline)
ℹ️  Review and fix these issues in future commits
```

**HCL Security Reports:**

Just like Checkov, the HCL validator generates reports published as pipeline artifacts:

| Artifact Name | File | Format | Use Case |
|---------------|------|--------|----------|
| `hcl-security-reports-{env}` | `hcl-security-issues.txt` | Plain text | Human-readable issue list |
| `hcl-security-reports-{env}` | `hcl-security-summary.json` | JSON | Programmatic analysis, metrics |

**Configuration:**

The HCL security scan behavior is controlled in `build.yaml`:

```yaml
# build.yaml
- template: templates/hcl-security-scan.yaml
  parameters:
    environment: dev
    failOnFindings: false  # ← Controls if pipeline fails on HCL security issues
```

**Current Configuration:**
- ✅ **Soft-fail mode enabled** (`failOnFindings: false`)
- ⚠️ HCL security issues are **reported** but do **not block** the pipeline
- Developers can review and fix issues incrementally

**To enable hard-fail mode:**
```yaml
failOnFindings: true  # Pipeline will fail if HCL security issues are found
```

**Integration with Build Pipeline:**

```markdown
Build Pipeline (build.yaml)
  ↓
Lint & Validate Stage
  ↓
┌─────────────────────────────────────┐
│ 1. Checkov (scans .tf files)        │ ← Scans Terraform modules
├─────────────────────────────────────┤
│ 2. HCL Validator (scans .hcl files) │ ← Scans Terragrunt configs
└─────────────────────────────────────┘
  ↓
✅ Both passed → Continue to Terragrunt Plan
❌ Either failed → Pipeline warns (does not fail by default)
```

**Complete Security Coverage:**

```
📦 Your Infrastructure Security Scanning Strategy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Layer 1: Checkov (Terraform Config)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Scans: infrastructure/modules/**/*.tf
✅ Detects: Hardcoded security issues in module definitions
✅ Coverage: 6 modules, 52 resources
✅ Checks: 1,000+ built-in Azure security policies
❌ Gap: Cannot see values from root.hcl

Layer 2: Custom HCL Validator (Terragrunt Config)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Scans: infrastructure/layers/**/root.hcl, terragrunt.hcl
✅ Detects: Insecure configuration values
✅ Coverage: 8 HCL files across 3 environments
✅ Checks: 8 custom security rules (Azure-specific)
❌ Gap: Less sophisticated than Checkov (pattern matching)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Result: Comprehensive security coverage across BOTH layers
        Module design (Checkov) + Configuration values (HCL validator)
```

**Best Practices for HCL Security:**

1. **Review HCL scan results regularly:**
   - Check pipeline logs after each run
   - Download `hcl-security-reports-{env}` artifacts
   - Review JSON summaries for trends

2. **Fix HIGH/CRITICAL issues immediately:**
   - `HCL-001`: Never use `"Internet"` as NSG source
   - `HCL-002`: Disable public network access in production
   - `HCL-004`: Always use SSH keys, never passwords

3. **Environment-specific severity:**
   - `HCL-002` is **CRITICAL** in prod, **HIGH** in dev/test
   - The validator adjusts severity based on environment context

4. **Document intentional exceptions:**
   - Add comments in `root.hcl` explaining why a rule is bypassed
   - Example:

     ```hcl
     # HCL-002: Public access required for initial bootstrap
     # Will be disabled after networking is provisioned
     public_network_access_enabled = true
     ```

5. **Keep validator rules updated:**
   - Add new rules as new security patterns emerge
   - Review and update severity levels based on compliance requirements

#### 📋 Files Not Scanned by Either Tool

The following file types are **parsed** but have **no security checks** from either Checkov or the HCL validator:

| File Type | Contains | Why No Checks |
|-----------|----------|---------------|
| `variables.tf` | Variable definitions | No resources or values to check |
| `outputs.tf` | Output definitions | No security-relevant configuration |
| `versions.tf` | Terraform/provider versions | Minimal security implications |
| `data.tf` | Data sources | Few applicable security checks |

**Why this is acceptable:**

- `variables.tf` files only **declare** variables, they don't set values
- `outputs.tf` files only **expose** values, they don't create resources
- Security checks focus on **where decisions are made** (modules and configs)

---

### Useful Links

- **Checkov Documentation:** [https://www.checkov.io/](https://www.checkov.io/)
- **Checkov Stable Version:** [https://github.com/bridgecrewio/checkov/releases](https://github.com/bridgecrewio/checkov/releases)
- **Checkov Scan Template:** [`azure-pipelines/templates/security-scan.yaml`](azure-pipelines/templates/security-scan.yaml)
- **HCL Security Scan Template:** [`azure-pipelines/templates/hcl-security-scan.yaml`](azure-pipelines/templates/hcl-security-scan.yaml)
- **Build Pipeline:** [`azure-pipelines/build.yaml`](azure-pipelines/build.yaml)

## Key Features

### 🔐 Approval Gates

- **Dev:** Manual approval required
- **Test:** Manual approval required
- **Prod:** Manual approval required

### 🏷️ Automated Tagging

- **RC Tags:** Created automatically after successful Test deployment
  - Format: `v{version}-rc.{timestamp}`
  - Example: `v1-rc.2025-09-12_14-30`

- **Stable Tags:** Created automatically after successful Prod deployment
  - Format: `v{version}`
  - Example: `v1`

### 📦 Artifact Management

- Terraform plans are published as artifacts between environments
- Artifacts are used to ensure consistency across environments
- **Two types of artifacts are published:**
  - **Binary Plan Artifacts** (`tfplan-{env}-{layer}`): Contains the binary Terraform plan file (`tfplan`) used for applying infrastructure changes
  - **Text Plan Artifacts** (`tfplan-text-{env}-{layer}`): Contains human-readable plan summary (`plan-summary.txt`) for easy review and approval

**Note:** The binary `tfplan` file cannot be opened directly on Windows. To view plans on your local machine:

- **Option 1 (Recommended):** Download the text artifact (`tfplan-text-{env}-{layer}`) and open `plan-summary.txt`
- **Option 2:** View the plan directly in the Azure DevOps pipeline logs
- **Option 3:** If you download the binary plan, convert it using:

  ```bash
  terraform show -no-color tfplan > plan-readable.txt
  ```

## Azure Pipeline Deployment Steps

### Pre-step

After running `terragrunt apply` locally for the creation of Resource Group and Storage Account we can then run `terragrunt apply` via the pipelines. Please see full instructions under the `README.md` file located at `/infrastructure` to deploy bootstrap layer locally first. Also note that in order to run `terragrunt apply` and deploy bootstrap layer, our user must have the following permissions:

- `Owner`
- `Key Vault Administrator`
- `Storage Blob Data Contributor`

### Post-steps

First thing to do is to create the pipelines in ADO.
This step must be done now as we will need the `deployment` pipeline to provision the `service_connection` module.

`Step 1`: Create `build` pipeline in ADO:

- Go to Pipelines > Pipelines in Azure DevOps
- Click New Pipeline
- Choose your repository - `Azure Repos Git`
- Select a repository - `Managed-DevOps-Pools`
- Select Existing Azure Pipelines YAML file
- Select branch (`main`) and path (`/azure-pipelines/build.yaml`)
- Save and run the pipeline (`bluid.yaml`)
- Rename the pipeline to: `build`

`Step 2`: Create `deployment` pipeline in ADO:

- Go to Pipelines > Pipelines in Azure DevOps
- Click New Pipeline
- Choose your repository - `Azure Repos Git`
- Select a repository - `Managed-DevOps-Pools`
- Select Existing Azure Pipelines YAML file
- Select branch (`main`) and path (`/azure-pipelines/deployment.yaml`)
- Save and run the pipeline (`deployment.yaml`)
- Rename the pipeline to: `deployment`

`Step 3`: Create `bootstrap` pipeline in ADO:

- Go to Pipelines > Pipelines in Azure DevOps.
- Click New Pipeline.
- Choose your repository - `Azure Repos Git`
- Select a repository - `Managed-DevOps-Pools`
- Select Existing Azure Pipelines YAML file.
- Select branch (`main`) and path (`/azure-pipelines/bootstrap-pipeline.yaml`)
- Save and run the pipeline (`bootstrap-pipeline.yaml`).
- Rename the pipeline to: `bootstrap`

**Note:** At this point we have deployed the Resource Group and Service Connection (bootstrap layer). Now because we want to deploy the rest of the infrastructure via pipeline we are going to use the `bootstrap-pipeline.yaml` pipeline to deploy the infra layer. We are going to use this pipeline because at this point we don't have a Federated Identity (OIDC) with the appropriate permissions (RBAC roles) to run on the pipeline - which is all included in the infra layer. Please also note that this pipeline (`bootstrap-pipeline.yaml` )is going to use a SP rather than a Federated Identity (OIDC) used in the `build` and `deployment` pipelines. Once we deploy the infra layer using the `bootstrap-pipeline.yaml` pipeline we will then use the `deployment` pipeline moving forward to deploy any resources. Please remember that we are going to use the `bootstrap-pipeline.yaml` pipeline to deploy the layers for the three environments (`dev`, `test` and `prod`) once, after that `deployment` pipeline must be used to provision any resource.

Please note that the `bootstrap-pipeline.yaml` pipeline must run manually via ADO.

---

### Types of Authentication Methods

- **Service Principal (SP):**
  - Uses **client secrets** (passwords) or certificates stored in Azure DevOps as service connections.
  - Requires managing and rotating credentials periodically.
  - Credentials are long-lived unless manually rotated.
  - Higher risk if secrets are exposed or leaked.
  - Secrets need secure storage in Azure DevOps variable groups/service connections
  - Requires credential rotation policies

- **OIDC (OpenID Connect):**
  - Uses **federated identity credentials** with short-lived tokens.
  - **No secrets to manage** - tokens are automatically generated per pipeline run.
  - More secure as tokens are scoped to specific pipelines and expire quickly.
  - **More secure** - no stored secrets
  - Tokens are issued just-in-time with limited scope
  - Built-in protection against credential theft
  - Follows Azure's **recommended security best practice**

---

`Step 4`: Set up branch policy for `main` branch:

This is necessary so it runs the build pipeline to validate a PR.

- Go to ADO > Project  (`Managed-DevOps-Pools`)
- Repos > Repositories
- Select repo: `Managed-DevOps-Pools`
- Under Policies > Branch Policies
- Select `main` branch
- Under Build Validation add build policy
  - Build pipeline: `build`
  - Trigger: `Automatic (whenever the source branch is updated)`
  - Policy requirement: `Required`
  - Build expiration: `After 12 hours if main has been updated`
  - Save

`Step 5`: In order to use the `bootstrap-pipeline.yaml` pipeline we first need to create a few resources so we can have a Service Connection and a Service Principal to run the pipelines. In order to do that we are going to use `create-bootstrap-sp.sh` script located at the root of the project. This script creates the necessary resources for the `bootstrap-pipeline.yaml` pipeline.

```bash
bash create-bootstrap-sp.sh
```

---

### Explanation of what `create-bootstrap-sp.sh` does

- `1`: We configure the default values for the Azure DevOps CLI to avoid having to pass `--organization` and `--project` flags repeatedly in subsequent `az devops` commands. Without this configuration, every subsequent Azure DevOps CLI command in the script would need to explicitly specify the parameters.

- `2`: This retrieves the Azure DevOps project ID for the project and validates it. The project ID is required by the Azure DevOps REST API when creating service connections.

- `3`: This section detects or creates an Azure DevOps Service Connection SP via REST API that allows Azure Pipelines to authenticate with Azure to deploy resources.

- `4`: This checks if an Azure Resource Group exists and creates it only if it doesn't already exist. The resource group is needed as a logical container to create Azure resources later.

- `5`: This creates the main bootstrap Service Principal. This bootstrap Service Principal is the core identity for your entire infrastructure automation. Please note that DevOps Service Connection SP is sed only for Azure DevOps to authenticate with Azure and Bootstrap SP is used by Terraform to deploy all infrastructure.

- `6`: This section assigns permissions to the bootstrap Service Principal, enabling it to manage all aspects of the Azure infrastructure and Azure AD resources through Terraform automation. This step assigns 6 different roles:
  - **Azure RBAC Roles (Azure Resources)**:
    - `Owner` - Full control over subscription resources
    - `Storage Blob Data Contributor` - Manage Terraform state files
    - `Key Vault Secrets Officer` - Manage secrets in Key Vault
  - **Microsoft Entra ID Directory Roles (Azure AD)**:
    - `Privileged Role Administrator` - Manage role assignments
    - `Directory Readers` - Read directory information
    - `Application Administrator` - Manage applications and service principals

- `7`: This checks if an Azure Key Vault exists and creates it only if it doesn't already exist. This is essential to store all sensitive credentials in the infrastructure. This includes:
  - **Bootstrap-level secrets**:
    - `ARM_CLIENT_ID` - Bootstrap SP application ID
    - `ARM_CLIENT_SECRET` - Bootstrap SP password
    - `ARM_TENANT_ID` - Azure AD tenant ID
    - `ARM_SUBSCRIPTION_ID` - Azure subscription ID
  - **Azure DevOps PATs**:
    - `azure-devops-pat-bootstrap` - PAT for initial setup
    - `azure-devops-pat-dev` - PAT for dev environment
    - `azure-devops-pat-test` - PAT for test environment
    - `azure-devops-pat-prod` - PAT for prod environment

- `8`: This stores bootstrap SP and Azure DevOps Pat secrets in Key Vault.

- `9`: This step ensures that `.ssh` directory exists and generates SSH key pair for VMSS.

- `10`: Stores public key in Key Vault.

- `11`: Add public key to `.env` file for Terraform. This is needed so Terraform can use it when deploying infrastructure locally.

- `12`: This grant DevOps Service Connection SP access to the Key Vault.

- `13`: This stores environment-specific secrets in the bootstrap Key Vault for each environment (dev, test, prod), enabling per-environment configuration while maintaining a centralized secret store. We do this to ensure that each environment should use a separate Azure DevOps PAT with different permissions. If a dev environment is compromised, the prod PAT remains secure.

- `14`: This is necessary before we deploy the `managed_devops_pool` module as we need to add the managed identity (the `bootstrap-sp` service principal) to the Azure DevOps as a user, grant Administrator permissions on Agent Pools and grant project-level permissions. We must do this because when Terraform tries to create the self-hosted agent pools via pipeline, Azure DevOps rejects it because the SP isn't authorized.

---

`Step 6`: Create a variable group in ADO for the bootstrap pipeline - `bootstrap-sp-secrets`

- Go to **Pipelines > Library** in Azure DevOps.
- Create a variable group named `bootstrap-sp-secrets`.
- Link secrets from an Azure key vault as variables.
- Azure subscription: `ado-bootstrap-sp-connection`
- Key vault name: `bootstrap-sp-kv-luis`
- Add variables
- Add Pipeline permissions to `bootstrap`
- Save

`Step 7`: Create a variable group in ADO for the build and deployment pipeline - `pipeline-secrets-dev`

- Go to **Pipelines > Library** in Azure DevOps.
- Create a variable group named `pipeline-secrets-dev`.
- Link secrets from an Azure key vault as variables.
- Azure subscription: `azure-oidc-dev`
- Key vault name: `kv-dev-luiscore`
- Add variables (`admin-ssh-public-key-dev`, `azure-devops-pat-dev`)
- Add Pipeline permissions to `build` and `deployment`
- Save

`Step 8`: Grant Service Connection permission to `bootstrap` pipeline.

- Go to ADO > Project  (`Managed-DevOps-Pools`)
- Project settings
- Pipelines > Service connections
- Select `ado-bootstrap-sp-connection`
- Under **Security**, either:
  - Enable **"Grant access permission to all pipelines"**, or
  - Go to **Pipeline permissions** and add your specific pipeline

`Step 9`: Grant OIDC Service Connection permission to `build` and `deployment` pipelines.

- Go to ADO > Project  (`Managed-DevOps-Pools`)
- Project settings
- Pipelines > Service connections
- Select `azure-oidc-dev`
- Under **Security**, either:
  - Enable **"Grant access permission to all pipelines"**, or
  - Go to **Pipeline permissions** and add your specific pipeline

`Step 10`: Grant VMSS SP Service Connection permission to `deployment` pipelines.

- Go to ADO > Project  (`Managed-DevOps-Pools`)
- Project settings
- Pipelines > Service connections
- Select `azure-sp-vmss-terraform-dev`
- Under **Security**, either:
  - Enable **"Grant access permission to all pipelines"**, or
  - Go to **Pipeline permissions** and add your specific pipeline

`Step 11`: Even though we have deployed the bootstrap layer locally we are going to need to run `terragrunt apply` again via the `bootstrap-pipeline.yaml` pipeline so the outputs can be generated and passed to the infra layer. In order to do that please change the `terragruntBasePath` variable in the `bootstrap-pipeline.yaml` pipeline, then run the pipeline manually in ADO.

```bootstrap-pipeline.yaml
  - name: terragruntBasePath
    value: 'infrastructure/layers/bootstrap/environments'
```

`Step 12`: Then change the `terragruntBasePath` variable in the `bootstrap-pipeline.yaml` pipeline back to deploy the infra layer.

```bootstrap-pipeline.yaml
  - name: terragruntBasePath
    value: 'infrastructure/layers/infra/environments'
```

`Step 13`: Then in order to deploy the infra layer please uncomment module by module in the `main.tf` file located at `/infrastructure/layers/infra` so the infra layer can be deployed. Starting with `module "networking"`.

`Step 14`: Repeat step 9 for the other modules.

- 14.1 - Once the `networking` and `dns` modules are deployed please pass their outputs to the bootstrap layer. This is located at `/infrastructure/layers/infra/outputs.tf`.
- 14.2 - Once the `service_connection` module is deployed we need to go back to the `oidc_role` module and comment out and uncomment the below code:

```main.tf
# Comment out code below:
service_connection_id      = null
service_connection_issuer  = null
service_connection_subject = null

# Uncomment code below:
service_connection_id = module.service_connection["oidc"].service_connection_id
service_connection_issuer =
module.service_connection["oidc"].service_connection_issuer
service_connection_subject =
module.service_connection["oidc"].service_connection_subject
```

`Step 15`: Once all the modules in the infra layer are deployed, we then need to comment out the `dependency "bootstrap"` block and the bootstrap outputs located at `/infrastructure/layers/infra/environments/dev/terragrunt.hcl` - this is necessary so we can use the infra layer outputs in the bootstrap layer:

```terragrunt.hcl
dependency "bootstrap" {
  config_path = "../../../bootstrap/environments/dev"
}

resource_group_name  = dependency.bootstrap.outputs.resource_group_name
    resource_group_id    = dependency.bootstrap.outputs.resource_group_id
    storage_account_name = dependency.bootstrap.outputs.storage_account_name
    storage_account_id   = dependency.bootstrap.outputs.storage_account_id
```

`Step 16`: Then we need to uncomment the `dependency "infra"` block and the infra layer outputs located at `/infrastructure/layers/bootstrap/environments/dev/terragrunt.hcl` - this is necessary so we can use the infra layer outputs in the bootstrap layer:

```terragrunt.hcl
private_subnet_id        = dependency.infra.outputs.private_subnet_id
private_dns_zone_blob_id = dependency.infra.outputs.private_dns_zone_blob_id

dependency "infra" {
  config_path = "../../../infra/environments/dev"
}
```

`Step 17`: We also need to set the variable `enable_private_endpoint = true` located at  `/infrastructure/layers/bootstrap/environments/dev/terragrunt.hcl`. This is necessary to create the **Private Endpoint** for the **Storage Account** - please note that in order to create this, three conditions must be met (1. `var.enable_private_endpoint` is `true`; 2. `var.private_subnet_id` is not empty; 3. 1. `var.private_dns_zone_blob_id` is not empty) -  this condition can be found at `/infrastructure/modules/storage-account/main.tf`. This follows the chicken-and-egg pattern where bootstrap creates the storage account first (without private endpoint), then infra creates networking, then bootstrap is updated to add the private endpoint.

```terragrunt.hcl
enable_private_endpoint = true
```

**IMPORTANT:** Steps 11, 12 and 13 should be performed via `deployment` pipeline (please run deployment pipeline manually). And moving forward only use the `deployment` pipeline to provision resources.

`Step 18`: Once the Storage Account Private Endpoints are deployed, we then need to keep the access to the resources private. This means that we need to modify the following variables that are located at `/infrastructure/layers/bootstrap/environments/dev/terragrunt.hcl`. However, please note that this is only possible when using one of the **self-hosted agent pools** (`devops-agent-pool-dev-core` or `vmss-devops-agents-dev-core` or `classic-vmss-devops-agents-dev-core`), as Microsoft agents cannot access private resources.

```terragrunt.hcl
public_network_access_enabled = false
network_rules_default_action  = "Deny"
```

`Step 19`: Next comment out the `dependency "infra"` block and infra layer outputs located at `/infrastructure/layers/bootstrap/environments/dev/terragrunt.hcl`. And uncomment the `dependency "bootstrap"` and bootstrap outputs located at `/infrastructure/layers/infra/environments/dev/terragrunt.hcl`.
Please note that this step is crucial in case we need to create/deploy new resources for this project.

`Step 20`: Also on the `build` and `deployment` pipelines please activate (uncomment) the infra layer and deactivate (comment out) the bootstrap layer:

```markdown
paths:
 - ${{ variables.basePathTerragruntBootstrap }} # To run bootstrap layer
 - ${{ variables.basePathTerragruntInfra }}     # To run infra layer
```

`Step 21`: Run `deployment.yaml` pipeline manually to deploy these changes.

`Step 22`: In order to make future deployments in the infra layer we need to deactivate/comment out the `dependency "bootstrap"` block and infra outputs located at `/infrastructure/layers/bootstrap/environments/dev/terragrunt.hcl` and activate/uncomment the `dependency "bootstrap"` block and bootstrap outputs located at `/infrastructure/layers/infra/environments/dev/terragrunt.hcl`.

```terragrunt.hcl
dependency "infra" {
  config_path = "../../../infra/environments/dev"
}

private_subnet_id        = dependency.infra.outputs.private_subnet_id
private_dns_zone_blob_id = dependency.infra.outputs.private_dns_zone_blob_id
```

```terragrunt.hcl
dependency "bootstrap" {
  config_path = "../../../bootstrap/environments/dev"
}

resource_group_name  = dependency.bootstrap.outputs.resource_group_name
resource_group_id    = dependency.bootstrap.outputs.resource_group_id
storage_account_name = dependency.bootstrap.outputs.storage_account_name
storage_account_id   = dependency.bootstrap.outputs.storage_account_id
```

`Step 23`: We also need to keep the access to the Key Vault private. This means that we need to modify the following variables that are located at `/infrastructure/layers/infra/environments/dev/terragrunt.hcl`. However, please note that this is only possible when using one of the **self-hosted agent pools** (`devops-agent-pool-dev-core` or `vmss-devops-agents-dev-core` or `classic-vmss-devops-agents-dev-core`), as Microsoft agents cannot access private resources.

```terragrunt.hcl
public_network_access_enabled = false
network_rules_default_action  = "Deny"
```

`Step 24`: Run `deployment.yaml` pipeline manually to deploy these changes.

`Step 25`: Create a PR - this will run `build` pipeline and `deployment` pipeline automatically.

`Step 26`: Once initial deployment is done for all environments, please use `remove-bootstrap-sp.sh` script to destroy the temporary SP and its permissions.

**Note:** Please repeat this process for each environment (`test` and `prod`).

**Note:** This project is deploying resources in three environments that belong to the same subscription. Ideally this should be changed to use a different subscription for each environment.
