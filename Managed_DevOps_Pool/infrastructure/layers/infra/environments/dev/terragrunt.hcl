# ====================================================================
# Load and inherit root Terragrunt configuration (remote_state, locals etc)
# ====================================================================
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# ====================================================================
# Dependency on bootstrap layer to reference its outputs - this must be comment out when infra layer is created as we need to pass the infra dependency to bootstrap layer
# ====================================================================
dependency "bootstrap" {
  config_path = "../../../bootstrap/environments/dev"
}

# ====================================================================
# Environment-specific input variables
# ====================================================================
inputs = merge(
  include.root.inputs, # This brings in ALL the common inputs from root.hcl
  {
    environment = "dev"

    # Referencing outputs from bootstrap layer to provide required inputs to infra layer - these must be comment out when infra layer is created and we need to pass the infra dependency to bootstrap layer
    resource_group_name  = dependency.bootstrap.outputs.resource_group_name
    resource_group_id    = dependency.bootstrap.outputs.resource_group_id
    storage_account_name = dependency.bootstrap.outputs.storage_account_name
    storage_account_id   = dependency.bootstrap.outputs.storage_account_id

    # Environment-specific networking settings
    managed_devops_pool_subnet_address_prefixes  = ["10.0.3.0/24"]
    managed_devops_pool_subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

    # Environment-specific NAT Gateway settings
    idle_timeout_in_minutes = 10
    zones                   = ["1"]

    #VNet configuration with dev-environment-specific values
    vnet_configs = merge(
      include.root.locals.default_vnets,
      {
        core = merge(
          include.root.locals.default_vnets.core,
          {
            address_space = ["10.0.0.0/16"]
            subnets = merge(
              include.root.locals.default_vnets.core.subnets,
              {
                public = merge(
                  include.root.locals.default_vnets.core.subnets.public,
                  { address_prefixes = ["10.0.1.0/24"] }
                ),
                private = merge(
                  include.root.locals.default_vnets.core.subnets.private,
                  { address_prefixes = ["10.0.2.0/24"] }
                )
              }
            )
          }
        )
      }
    )

    # More configurations:

  }
)
