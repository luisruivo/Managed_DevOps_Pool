# ====================================================================
# Load and inherit root Terragrunt configuration (remote_state, locals etc)
# ====================================================================
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# ====================================================================
# Environment-specific input variables
# ====================================================================
inputs = merge(
  include.root.inputs, # This brings in ALL the common inputs from root.hcl
  {
    environment              = "dev"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    min_tls_version          = "TLS1_2"
    network_rules_bypass     = ["AzureServices"]
    blob_versioning_enabled  = true
    container_access_type    = "private"
    is_manual_connection     = false
    subresource_names        = ["blob"]
    blob_dns_zone_group_name = "blob-dns-zone-group"

    # Environment-specific overrides for bootstrap layer
    # private_subnet_id             = ""      # Dummy value for bootstrap - after infra layer is deployed, please COMMENT OUT this code.
    # private_dns_zone_blob_id      = ""      # Dummy value for bootstrap - after infra layer is deployed, please COMMENT OUT this code.
    # enable_private_endpoint       = false   # Override: Set to "false" for initial deployment - after infra layer is deployed, please COMMENT OUT this code.
    # public_network_access_enabled = true    # Override: Set to "true" for initial deployment - after infra layer is deployed, please COMMENT OUT this code.
    # network_rules_default_action  = "Allow" # Override: Set to "Allow" for initial deployment - after infra layer is deployed, please COMMENT OUT this code.

    # Referencing outputs from infra layer to provide required inputs to bootstrap layer - please UNCOMMENT code below once infra layer is deployed.
    # private_subnet_id        = dependency.infra.outputs.private_subnet_id
    # private_dns_zone_blob_id = dependency.infra.outputs.private_dns_zone_blob_id

    # Please UNCOMMENT code below once infra layer is deployed - this will create a private endpoint for Storage Account.
    enable_private_endpoint = true

    # Please UNCOMMENT code below once infra layer is deployed - this will restrict public network access to Storage Account - this must be done only using one of the self-hosted agents via deployment pipeline.
    public_network_access_enabled = false
    network_rules_default_action  = "Deny"

    tags = merge(
      include.root.locals.common_tags, # This brings in ALL the common tags from root.hcl
      { Environment = "dev" }
    )
  }
)

# ====================================================================
# Dependency on infra layer to reference its outputs - please uncomment the dependency code below to reference infra layer outputs to bootstrap layer
# ====================================================================
# dependency "infra" {
#   config_path = "../../../infra/environments/dev"
# }
