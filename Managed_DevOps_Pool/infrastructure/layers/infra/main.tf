#-------------------------------------
# Data Sources
#------------------------------------
data "azuread_service_principal" "devops_infrastructure" {
  display_name = "DevOpsInfrastructure"
}

#-------------------------------------
# Reusable Modules
#------------------------------------
module "networking" {
  source   = "../../modules/networking"
  for_each = var.vnet_configs

  vnet_name          = "vnet-${var.environment}-${each.value.suffix_name}"
  vnet_address_space = each.value.address_space

  subnets                                            = each.value.subnets
  managed_devops_pool_subnet_name                    = "managed-devops-pool-subnet-${var.environment}"
  managed_devops_pool_subnet_type                    = var.managed_devops_pool_subnet_type
  managed_devops_pool_subnet_address_prefixes        = var.managed_devops_pool_subnet_address_prefixes
  managed_devops_pool_subnet_service_endpoints       = var.managed_devops_pool_subnet_service_endpoints
  managed_devops_pool_subnet_delegation_name         = var.managed_devops_pool_subnet_delegation_name
  managed_devops_pool_subnet_delegation_service_name = var.managed_devops_pool_subnet_delegation_service_name

  nat_gateway_name           = "nat-${var.environment}"
  nat_gateway_public_ip_name = "public-ip-nat-${var.environment}"
  nat_sku_name               = var.nat_sku_name
  idle_timeout_in_minutes    = var.idle_timeout_in_minutes
  zones                      = var.zones
  allocation_method          = var.allocation_method

  nsg_configs = each.value.nsg_configs

  private_subnet_route_table_name = "private-subnet-rt-${var.environment}"

  location            = each.value.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, each.value.specific_tags)
}

module "dns" {
  source   = "../../modules/dns"
  for_each = var.dns_configs

  private_dns_zone_name = each.value.private_dns_zone_name
  vnet_link_name        = each.value.vnet_link_name
  vnet_id               = module.networking[each.value.vnet_key].vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags

  depends_on = [module.networking]
}

module "managed_devops_pool_identity" {
  source = "../../modules/identity/managed-identity"

  managed_identity_name = "id-${var.environment}-managed-devops-pool"
  location              = var.location
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

module "vmss_classic_pool_identity" {
  source = "../../modules/identity/managed-identity"

  managed_identity_name = "id-${var.environment}-vmss-classic-pool"
  location              = var.location
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

module "key_vault" {
  source   = "../../modules/key-vault"
  for_each = var.key_vault_configs

  key_vault_name                  = "${each.value.name_prefix}-${var.environment}-${each.key}"
  private_endpoint_name           = each.value.private_endpoint_name
  private_service_connection_name = each.value.private_service_connection_name
  private_dns_zone_group_name     = each.value.private_dns_zone_group_name

  location                      = var.location
  resource_group_name           = var.resource_group_name
  key_vault_sku_name            = each.value.sku_name
  purge_protection_enabled      = each.value.purge_protection_enabled
  enable_rbac_authorization     = each.value.enable_rbac_authorization
  public_network_access_enabled = each.value.public_network_access_enabled
  network_acls_default_action   = each.value.network_acls_default_action
  network_acls_bypass           = each.value.network_acls_bypass
  is_manual_connection          = each.value.is_manual_connection
  subresource_names             = each.value.subresource_names

  private_subnet_id         = module.networking[each.value.vnet_key].subnet_ids[each.value.subnet_key]
  private_dns_zone_vault_id = module.dns[each.value.dns_key].private_dns_zone_id

  key_vault_secrets = var.key_vault_secrets

  tags = merge(var.tags, each.value.specific_tags)

  depends_on = [
    module.networking,
    module.dns
  ]
}

module "devops_infrastructure_rbac" {
  source   = "../../modules/identity/rbac"
  for_each = var.vnet_configs

  role_assignments = [
    {
      # DevOpsInfrastructure SP: Reader access to VNet
      role_definition_name = "Reader"
      principal_id         = data.azuread_service_principal.devops_infrastructure.object_id
      scope                = module.networking[each.key].vnet_id
    },
    {
      # DevOpsInfrastructure SP: Network Contributor access to VNet
      role_definition_name = "Network Contributor"
      principal_id         = data.azuread_service_principal.devops_infrastructure.object_id
      scope                = module.networking[each.key].vnet_id
    }
  ]

  depends_on = [
    module.networking
  ]
}

module "managed_devops_pool" {
  source   = "../../modules/azure_devops_pools/managed-devops-pool"
  for_each = var.managed_devops_pool_configs

  devcenter_name                            = "devcenter-${var.environment}"
  devcenter_project_name                    = "devcenter-project-${var.environment}"
  devcenter_project_display_name            = "DevCenter Project ${var.environment}"
  devcenter_project_description             = "Project for Managed DevOps Pools in ${var.environment}"
  managed_devops_pool_name                  = "devops-agent-pool-${var.environment}-${each.key}"
  managed_devops_pool_maximum_concurrency   = each.value.maximum_concurrency
  managed_devops_pool_open_access           = each.value.open_access
  managed_devops_pool_parallelism           = each.value.parallelism
  managed_devops_pool_prediction_preference = each.value.prediction_preference
  managed_devops_pool_vm_sku                = each.value.vm_sku
  managed_devops_pool_image_name            = each.value.image_name
  managed_devops_pool_logon_type            = each.value.logon_type
  managed_devops_pool_os_disk_type          = each.value.os_disk_type

  location                      = var.location
  resource_group_id             = var.resource_group_id
  managed_devops_pool_subnet_id = module.networking[each.value.vnet_key].managed_devops_pool_subnet_id
  managed_identity_id           = module.managed_devops_pool_identity.managed_identity_id
  managed_identity_principal_id = module.managed_devops_pool_identity.managed_identity_principal_id
  devops_org_url                = var.devops_org_url
  devops_project_name           = var.devops_project_name
  tags                          = merge(var.tags, each.value.specific_tags)

  depends_on = [
    module.networking,
    module.managed_devops_pool_identity
  ]
}

module "vmss_agent_pool" {
  source   = "../../modules/azure_devops_pools/vmss-agent-pool"
  for_each = var.vmss_agent_pool_configs

  vmss_agent_pool_name = "vmss-agent-pool-${var.environment}-${each.key}"
  vmss_name            = "vmss-devops-agents-${var.environment}-${each.key}"
  vmss_sku             = each.value.vmss_sku
  vmss_instance_count  = each.value.vmss_instance_count
  admin_username       = each.value.admin_username
  vmss_image_publisher = each.value.vmss_image_publisher
  vmss_image_offer     = each.value.vmss_image_offer
  vmss_image_sku       = each.value.vmss_image_sku
  vmss_image_version   = each.value.vmss_image_version
  vmss_os_disk_type    = each.value.vmss_os_disk_type

  location             = var.location
  resource_group_name  = var.resource_group_name
  private_subnet_id    = module.networking[each.value.vnet_key].subnet_ids[each.value.subnet_key]
  devops_project_name  = var.devops_project_name
  admin_ssh_public_key = var.admin_ssh_public_key
  tags                 = merge(var.tags, each.value.specific_tags)

  depends_on = [module.networking]
}

# module "vmss_classic_pool" {
#   source = "./modules/azure_devops_pools/vmss-classic"
#   for_each = var.classic_vmss_agent_pool_configs

#   classic_agent_pool_queue     = "classic-vmss-agent-pool-${var.environment}-${each.key}"
#   classic_vmss_name            = "classic-vmss-agent-pool-${var.environment}-${each.key}"
#   classic_vmss_sku             = each.value.classic_vmss_sku
#   classic_vmss_instance_count  = each.value.classic_vmss_instance_count
#   admin_username               = each.value.admin_username
#   classic_vmss_image_publisher = each.value.classic_vmss_image_publisher
#   classic_vmss_image_offer     = each.value.classic_vmss_image_offer
#   classic_vmss_image_sku       = each.value.classic_vmss_image_sku
#   classic_vmss_image_version   = each.value.classic_vmss_image_version
#   classic_vmss_os_disk_type    = each.value.classic_vmss_os_disk_type

#   location                  = var.location
#   resource_group_name       = var.resource_group_name
#   private_subnet_id         = module.networking["core"].subnet_ids["private"]
#   devops_project_name       = var.devops_project_name
#   admin_ssh_public_key      = var.admin_ssh_public_key
#   environment               = var.environment
#
#   devops_org_url            = var.devops_org_url
#   pat_secret_name           = module.key_vault.pat_secret_name
#   key_vault_name            = module.key_vault.key_vault_name
#   storage_account_name      = var.storage_account_name
#   agent_pool_name           = var.agent_pool_name
#   user_assigned_identity_id = module.managed_identity.managed_identity_id
#   tags                      = merge(var.tags, each.value.specific_tags)
#
#   depends_on = [
#     module.networking,
#     module.managed_identity,
#     module.key_vault
#   ]
# }

module "oidc_role" {
  source = "../../modules/identity/oidc-role"

  oidc_application_display_name     = "OIDC-Application-${var.environment}"
  federated_credential_display_name = "devops-oidc-${var.environment}"
  audience                          = var.audience
  devops_project_name               = var.devops_project_name

  # service_connection_id      = null # Overridden: Set to null to break circular dependency - once service connection is created please comment out this line and use code below
  # service_connection_issuer  = null # Overridden: Set to null to break circular dependency - once service connection is created please comment out this line and use code below
  # service_connection_subject = null # Overridden: Set to null to break circular dependency - once service connection is created please comment out this line and use code below

  # Once Service Connection is created uncomment code below:
  service_connection_id      = module.service_connection["oidc"].service_connection_id
  service_connection_issuer  = module.service_connection["oidc"].service_connection_issuer
  service_connection_subject = module.service_connection["oidc"].service_connection_subject
}

module "service_connection" {
  source   = "../../modules/service-connection"
  for_each = var.service_connection_configs

  service_endpoint_name        = "azure-${each.value.name_suffix}-${var.environment}"
  service_endpoint_description = each.value.description
  authentication_scheme        = each.value.authentication_scheme

  service_principal_id  = module.oidc_role.client_id_oidc
  service_principal_key = null

  devops_project_name = var.devops_project_name
  subscription_id     = var.subscription_id
  pipeline_names      = var.pipeline_names
}

module "rbac_oidc_sp" {
  source = "../../modules/identity/rbac"

  role_assignments = [
    {
      # OIDC SP: Contributor role to allow Terraform via pipeline to have full resource CRUD (create, update, delete Azure resources)
      role_definition_name = "Contributor"
      principal_id         = module.oidc_role.service_principal_object_id
      scope                = "/subscriptions/${var.subscription_id}"
    },
    {
      # OIDC SP: User Access Administrator role at RG scope to allow pipeline to assign roles to other identities
      role_definition_name = "User Access Administrator"
      principal_id         = module.oidc_role.service_principal_object_id
      scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
    },
    {
      # Allow OIDC SP to access blobs in any Storage Account in this RG
      role_definition_name = "Storage Blob Data Contributor"
      principal_id         = module.oidc_role.service_principal_object_id
      scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
    },
    {
      # Allow OIDC SP to read/add/delete secrets in any Key Vault in this RG
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = module.oidc_role.service_principal_object_id
      scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
    }
  ]
}

module "rbac_vmss" {
  source   = "../../modules/identity/rbac"
  for_each = var.vmss_agent_pool_configs

  role_assignments = concat(
    [
      {
        # VMSS system-assigned identity: Storage Blob Data Reader role to allow VMSS agents to read application files from blob storage during execution
        role_definition_name = "Storage Blob Data Reader"
        principal_id         = module.vmss_agent_pool[each.key].vmss_identity
        scope                = var.storage_account_id
      }
    ],
    [
      for kv_key, kv in module.key_vault : {
        # VMSS system-assigned identity: Key Vault Secrets User role to allow VMSS agents to retrieve secrets from Key Vault at runtime
        role_definition_name = "Key Vault Secrets User"
        principal_id         = module.vmss_agent_pool[each.key].vmss_identity
        scope                = kv.key_vault_id
      }
    ]
  )
}

module "rbac_managed_devops_pool" {
  source   = "../../modules/identity/rbac"
  for_each = var.managed_devops_pool_configs

  role_assignments = concat(
    [
      {
        # Managed DevOps Pool user-assigned identity: Storage Blob Data Reader role to allow the agents to read application files from blob storage during execution
        role_definition_name = "Storage Blob Data Reader"
        principal_id         = module.managed_devops_pool[each.key].managed_identity_principal_id
        scope                = var.storage_account_id
      }
    ],
    [
      for kv_key, kv in module.key_vault : {
        # Managed DevOps Pool user-assigned identity: Key Vault Secrets User role to allow the agents to retrieve secrets from Key Vault at runtime
        role_definition_name = "Key Vault Secrets User"
        principal_id         = module.managed_devops_pool[each.key].managed_identity_principal_id
        scope                = kv.key_vault_id
      }
    ]
  )
}

# module "bastion_jump" {
#   source   = "../../modules/bastion-jump"
#   for_each = var.bastion_configs

#   bastion_name                         = "${each.value.name_prefix}-${var.environment}-${each.key}"
#   bastion_public_ip_name               = "${each.value.public_ip_name_prefix}-${var.environment}-${each.key}"
#   bastion_network_interface_name       = "${each.value.nic_name_prefix}-${var.environment}-${each.key}"
#   bastion_vm_size                      = each.value.vm_size
#   bastion_admin_username               = each.value.admin_username
#   bastion_os_disk_caching              = each.value.os_disk_caching
#   bastion_os_disk_storage_account_type = each.value.os_disk_storage_account_type
#   bastion_image_publisher              = each.value.image_publisher
#   bastion_image_offer                  = each.value.image_offer
#   bastion_image_sku                    = each.value.image_sku
#   bastion_image_version                = each.value.image_version

#   location             = var.location
#   environment          = var.environment
#   admin_ssh_public_key = var.admin_ssh_public_key
#   resource_group_name  = var.resource_group_name
#   public_subnet_id     = module.networking[each.value.vnet_key].subnet_ids[each.value.subnet_key]
#   tags                 = merge(var.tags, each.value.specific_tags)
# }
