# Infrastructure Structure

This project uses [Terraform](https://developer.hashicorp.com/terraform/intro) and [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/overview/) to provision the infrastructure.

`Terraform` is a declarative IaC tool that allow us to automatically create, update or delete resources to match the desired state of our infrastructure (resources, configurations etc). Terraform tracks resource state in files or remote backends to enable safe updates and drift detection. Uses modules to encapsulate best practices and reuse code across environments. Integrates with Azure Pipelines to enable automated and consistent deployments.

`Terragrunt` is a wrapper for Terraform that helps us to manage complex infrastructure deployments. It adds features for configuration reuse, environment management and automation, making it easier to work with Terraform in large, multi-environment projects. In this project Terragrunt is used to keep configuration DRY (share common settings across environments using inheritance and includes) and to manage dependencies (reference outputs between layers to orchestrate deployments). Terragrunt adds capabilities that are difficult to achieve with plain Terraform - especially in a multi-environment, multi-layer setup like ours. With Terragrunt we can reference outputs from one layer directly in another using the `dependency` block - with plain Terraform we would need to manually copy outputs, use remote state data sources and manage state file paths which is more error-prone and less maintainable. Terragrunt also supports the `include` blocks to inherit common settings from parent files like `root.hcl` - with plain Terraform we would have to duplicate variable definitions and backend configs in every environment folder or use complex scripting/templates.

## Folder Structure

All the code related to the infrastructure is located at `/infrastructure`.

In the `/infrastructure` directory we have two directories: `/layers` and `/modules`.

- `/layers` contains the code for the `bootstrap` and `infra`.

- `/modules` contains the code for the resources used in the `bootstrap` and `infra` layers.

`bootstrap` layer deploys the following resources:

- Resource Group
- Storage Account <-- where the Terraform state file and repo files will be stored

The bootstrap infrastructure solves the classic "chicken and egg" problem with Terraform remote state backends. Before we can use Terraform with remote state storage in Azure, we need:

- A Resource Group to contain the storage account.
- A Storage Account to store the Terraform state files.
- A Blob Container within the storage account.

However, Terraform cannot create these resources if it needs them to exist first for storing its own state. The bootstrap module creates these foundational resources using **local state** initially, enabling all subsequent infrastructure deployments to use **remote state**.

`infra` layer deploys the following resources:

- Networking
- DNS
- Managed DevOps Pool Identity
- VMSS Classic Pool Identity
- Key Vault
- Managed DevOps Pool
- VMSS Agent Pool
- VMSS Classic Pool
- OIDC Role
- Service Connection
- RBAC for DevOps Infrastructure, OIDC, Service Connection Key Vault, Service Connection Storage Account, VMSS, Managed DevOps Pool, Bastion Jump

On both `/bootstrap` and `/layer` directories we have the same structure:

- At the root level we have all the `.tf` files.
- In the `/environments` directory we have all the `.hcl` files → `root.hcl` contains the configurations that will be applied to all environments and `terragrunt.hcl` contains environment-specific configurations (`dev`, `test` and `prod`).

On the `/modules` directory we have the following modules:

- Azure DevOps Pools → this contains the 3 solutions that can be used (`managed_devops_pool`, `vmss-agent-pool` and `vmss-classic-pool`). Please note that we have two self-hosted agent solution that use VMSS: `vmss-agent-pool` solution uses [Scale Set Agents](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops#create-the-scale-set-agent-pool) that allows Azure DevOps to manage the agent installation and `vmss-classic-pool` solution uses a custom script to manually register an agent in Azure DevOps.
- Bastion Jump → used to ssh into VMSS in the private subnet.
- DNS
- Identity → this contains `managed-identity`, `oidc-role`, and `rbac`
- Key Vault
- Networking
- Resource Group
- Service Connection
- Storage Account

## Infrastructure Deployment Steps

The provisioning of the infrastructure was tested locally but should be deployed via pipeline.
In order to deploy the infrastructure we must follow a certain order.

1. Run `terragrunt apply` for bootstrap layer with local backend - this is because we first need to create a storage account and container to then put the state file on it (chicken-and-egg problem). Please note that in order to do this, we need to comment out the remote state code from: `backend.tf` and `root.hcl`

2. Once bootstrap layer is created (`resource_group` and `storage_account`) please, uncomment the code from `backend.tf` and `root.hcl` correspondent to the remote backend and run `terragrunt init` - this will move the local state to the storage account (remote state).

3. Then deploy infra layer via pipeline. It's recommended to deploy one module at a time in the order (from top to bottom).

4. Once infra layer is deployed please have a look at the following files:

- `terragrunt.hcl` file located at `/infrastructure/layers/bootstrap/environments/dev` → this file contains code that needs to be comment out and uncommented. In the `inputs` block we have five variables that must be uncomment and comment out. We also need to uncomment the `dependency` block so the bootstrap layer can use the outputs from the infra layer.

- `terragrunt.hcl` file located at `/infrastructure/layers/infra/environments/dev` → In the `inputs` block we have four variables that must be comment out. We also need to comment out the `dependency` block so the bootstrap layer can use the outputs from the infra layer.

## Terraform commands

- `terraform version` - Shows current Terraform version.
- `terraform fmt -check` -  Checks if files are formatted properly.
- `terraform fmt` — Formats Terraform code for consistency.
- `terraform fmt -check -recursive` - Checks if any Terraform files in current directory or subdirectory are formatted properly.
- `terraform fmt -recursive` — Formats Terraform code files in current directory and in subdirectories.
- `terraform fmt -check -diff` - Checks formatting without changing anything.
- `terraform fmt -check -diff -recursive` - Checks formatting without changing anything in current directory and in subdirectories.
- `terraform init` — Initializes the working directory and downloads required providers/modules.
- `terraform validate` — Validates configuration files.
- `terraform providers` - Lists all required and installed providers.
- `terraform plan` — Previews the changes Terraform will make.
- `terraform apply` — Applies the changes to Azure.
- `terraform destroy` — Destroy all infrastructure.
- `terraform state list` - Lists all resources tracked in the current state file.
- `terraform state show <resource>` - Shows attributes of a specific resource in the state file.
- `terraform console` - Opens an interactive REPL for Terraform. It let us inspect and evaluate Terraform expressions, variables, outputs and resource attributes using the current state file.
- `terraform force-unlock <id>` - To manually unlock a Terraform state file that has become locked.

## Terragrunt commands

- `terragrunt --version` - Shows current Terragrunt version.
- `terragrunt hcl format` — Formats Terragrunt HCL files for consistency.
- `terragrunt hcl format --check` — Checks if Terragrunt HCL files are formatted properly.
- `terragrunt init` — Initializes Terragrunt configuration and downloads required providers/modules.
- `terragrunt validate` — Validates Terraform configuration using Terragrunt.
- `terragrunt validate-all` — Validates all modules and environments recursively.
- `terragrunt plan` — Previews the changes Terragrunt will make (runs Terraform plan).
- `terragrunt plan-all` — Runs plan for all modules/environments recursively.
- `terragrunt apply` — Applies the changes using Terragrunt (runs Terraform apply).
- `terragrunt apply-all` — Applies changes for all modules/environments recursively.
- `terragrunt destroy` — Destroys infrastructure for the current module/environment.
- `terragrunt destroy-all` — Destroys infrastructure for all modules/environments recursively.
- `terragrunt output` — Shows Terraform outputs for the current module/environment.
- `terragrunt run-all <command>` — Runs any Terraform command (e.g., `plan`, `apply`, `destroy`) for all modules/environments.
- `terragrunt force-unlock <id>` - To manually unlock a Terraform state file that has become locked.

## Azure built-in roles documentation

[RBAC documentation](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)

## Azure Pipeline agent solutions

1. Managed DevOps Pools:
   - Uses the Azure Dev Center service to provision and manage agent pools.
   - Abstracts away VMSS management - Azure handles scaling, patching, and infra.

2. VMSS-based self-hosted agents:
   - Uses Azure VMSS agents - [Scale Set Agents](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops#create-the-scale-set-agent-pool).
   - We create a scale set and register it as an agent pool. Azure DevOps itself then manages the lifecycle of the instances.
   - Scales out when jobs are queued.
   - Tears down VMs when idle (after a job finishes).
   - Native integration, officially supported by Microsoft.
   - Works well with private networking (private endpoints, VNet, etc.).
   - Requires us to configure the VMSS with an image that has the agent pre-installed (or use a custom script extension to install on boot).

3. Classic VMSS-based self-hosted agents:
   - Uses a script on the VMSS to automatically configure each VM as self-hosted Azure DevOps agent.
   - The script transforms a Ubuntu VM into a fully functional Azure DevOps build agent within the private VNet.
   - Full control over OS, installed software, and networking.
   - Uses managed identity for secure access to Azure resources.

### Why Self-Hosted Agents on VMSS?

- Customization & Control: Self-hosted agents allow us to install custom software, configure specific tools, and control the environment, which is not possible with Microsoft-hosted agents.
- Performance & Scalability: We can choose VM sizes, scale agents as needed, and potentially achieve faster builds by tuning hardware and caching dependencies.
- Network Access: Self-hosted agents can access private resources (e.g., on-premises systems, private Azure networks, Key Vaults) that Microsoft-hosted agents cannot reach.
- Cost Optimization: For high-volume pipelines, self-hosted agents may reduce costs compared to paying for additional Microsoft-hosted agent minutes.
- Compliance & Security: We control patching, security policies, and compliance requirements, which is critical for regulated industries.

### Managed DevOps Pools

In order to create a Managed Azure DevOps Pool there are the following choices:

- `azuredevops_agent_pool` (from terraform-provider-azuredevops)
- `azapi_resource` (from terraform-provider-azapi)
- `module "managed_devops_pool"`

For this project we have decided to choose: `azapi_resource`.

Please note that `Microsoft.DevOps/managedDevOpsPools` does not exist in Azure Resource Manager, and thus we cannot provision Managed DevOps Pools via ARM or the Terraform azapi_resource using that resource type. Instead, the correct ARM resource provider for Managed DevOps Pools is: `Microsoft.DevOpsInfrastructure/pools` - [link1](https://learn.microsoft.com/en-us/azure/templates/microsoft.devopsinfrastructure/2025-01-21/pools?pivots=deployment-language-terraform) and [link2](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)

For a Managed DevOps Pool, we need to have a **Dev Center** and a **Dev Center Project** already in place. This means that our Managed DevOps Pool must be linked to an existing Dev Center project. `No Dev Center → no project → pool creation will fail`.

Managed DevOps Pools run inside the Azure Dev Center service — that’s where the infrastructure (VMSS, networking, scaling) is managed.
The pool is basically a specialized Dev Center project resource that’s linked to your Azure DevOps organization.

So, we will need to:

1. Register resource providers:
   - `Microsoft.DevCenter`
   - `Microsoft.DevOpsInfrastructure`
2. Create a Dev Center resource.
3. Create a Dev Center Project resource in that Dev Center.
4. Create the Managed DevOps Pool with `azapi_resource`.

The resource hierarchy in Azure should look like:

```text
Resource Group
 └─ DevCenter (Microsoft.DevCenter/devcenters)
      └─ DevCenter Project (Microsoft.DevCenter/projects)
           └─ Managed DevOps Pool (Microsoft.DevOpsInfrastructure/pools)
```

For this solution we have created a dedicated subnet called `managed-devops-pool-subnet-dev` rather than using the private subnet used for the VMSS, as  Terraform’s `azurerm_subnet` resource only allows delegations that the provider knows about, and currently `Microsoft.DevOpsInfrastructure/pools` is not a supported delegation in the `azurerm` provider.
