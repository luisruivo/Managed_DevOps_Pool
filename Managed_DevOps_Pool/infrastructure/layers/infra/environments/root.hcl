# ====================================================================
# Bootstrap Module Source Configuration
# ====================================================================
terraform {
  source = "../../../..//layers/infra"
}

# ====================================================================
# Common input and common tags variables for infra layer - makes them available to all child modules
# ====================================================================
locals {
  env      = get_env("ENVIRONMENT", "dev")         # Environment default set to 'dev' if not provided
  location = get_env("AZURE_LOCATION", "UK South") # Location default set to 'UK South' if not provided

  common_inputs = {
    location             = local.location
    subscription_id      = "6fc684c9-bd7f-420a-b697-ef8b122f4d85"
    devops_org_url       = "https://dev.azure.com/Ruivo21"
    devops_project_name  = "Managed-DevOps-Pools"
    pipeline_names       = ["deployment"]
    pat_value            = get_env("TF_VAR_pat_value", "")
    admin_ssh_public_key = get_env("TF_VAR_admin_ssh_public_key", "")

    # Common Networking settings (not environment-specific)
    managed_devops_pool_subnet_type                    = "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
    managed_devops_pool_subnet_delegation_name         = "devopspooldelegation"
    managed_devops_pool_subnet_delegation_service_name = "Microsoft.DevOpsInfrastructure/pools"
    allocation_method                                  = "Static"
    nat_sku_name                                       = "Standard"

    # OIDC settings (not environment-specific)
    audience = ["api://AzureADTokenExchange"] # https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp

    # More settings:

  }

  common_tags = {
    Project     = "Managed-DevOps-Pools"
    Environment = local.env
  }

  # Networking configurations (can be overridden per environment):
  default_vnets = {
    core = {
      suffix_name   = "core"
      location      = local.location
      address_space = []
      specific_tags = {
        Purpose = "Core Networking"
        Company = "Node4"
      }
      subnets = {
        public = {
          name              = "public-subnet-${local.env}"
          address_prefixes  = []
          service_endpoints = []
          delegations       = []
        }
        private = {
          name              = "private-subnet-${local.env}"
          address_prefixes  = []
          service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
          delegations       = []
        }
      }
      nsg_configs = {
        public = {
          name = "public-nsg-${local.env}"
          rules = [
            {
              name                       = "AllowHttpsInbound"
              priority                   = 1000
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "*"
              source_port_range          = "*"
              destination_port_range     = "443"
              source_address_prefix      = "AzureDevOps"
              destination_address_prefix = "*"
            },
            {
              name                       = "AllowHttpsOutbound"
              priority                   = 1000
              direction                  = "Outbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "*"
              source_address_prefix      = "*"
              destination_address_prefix = "*"
            }
          ]
        }
        private = {
          name = "private-nsg-${local.env}"
          rules = [
            {
              name                       = "AllowVNetInbound"
              priority                   = 1000
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "*"
              source_port_range          = "*"
              destination_port_range     = "*"
              source_address_prefix      = "VirtualNetwork"
              destination_address_prefix = "VirtualNetwork"
            },
            {
              name                       = "DenyAllInbound"
              priority                   = 4000
              direction                  = "Inbound"
              access                     = "Deny"
              protocol                   = "*"
              source_port_range          = "*"
              destination_port_range     = "*"
              source_address_prefix      = "*"
              destination_address_prefix = "*"
            },
            {
              name                       = "AllowAllOutbound"
              priority                   = 1000
              direction                  = "Outbound"
              access                     = "Allow"
              protocol                   = "*"
              source_port_range          = "*"
              destination_port_range     = "*"
              source_address_prefix      = "*"
              destination_address_prefix = "*"
            }
          ]
        }
      }
    }
  }

  # DNS configurations (can be overridden per environment):
  default_dns_configs = {
    blob = {
      private_dns_zone_name = "privatelink.blob.core.windows.net"
      vnet_link_name        = "dns-link-${local.env}-blob"
      vnet_key              = "core"
    }
    vault = {
      private_dns_zone_name = "privatelink.vaultcore.azure.net"
      vnet_link_name        = "dns-link-${local.env}-kv"
      vnet_key              = "core"
    }
  }

  # Key Vault configurations (can be overridden per environment):
  default_key_vault_configs = {
    luiscore = {
      name_prefix                     = "kv"
      private_endpoint_name           = "kv-pep-${local.env}"
      private_service_connection_name = "kv-psc-${local.env}"
      private_dns_zone_group_name     = "kv-dns-zone-group"
      vnet_key                        = "core"
      subnet_key                      = "private"
      dns_key                         = "vault"
      sku_name                        = "standard"
      purge_protection_enabled        = true
      enable_rbac_authorization       = true
      public_network_access_enabled   = false  # Default set to "false" to restrict access to private endpoints - only "true" for initial deployment to add secret to Key Vault - once secrets are in the Key Vault and we move to automation (pipelines) please set it to "false"
      network_acls_default_action     = "Deny" # Default set to "Deny" to restrict access to private endpoints - only "Allow" for initial deployment to add secret to Key Vault - once secrets are in the Key Vault and we move to automation (pipelines) please set it to "Deny"
      network_acls_bypass             = "AzureServices"
      is_manual_connection            = false
      subresource_names               = ["vault"]
      specific_tags = {
        Purpose = "Secrets Management"
      }
    }
  }

  key_vault_secrets = {
    azure_devops_pat = {
      name  = "azure-devops-pat-${local.env}"
      value = get_env("TF_VAR_pat_value", "")
    }
    admin_ssh_public_key = {
      name  = "admin-ssh-public-key-${local.env}"
      value = get_env("TF_VAR_admin_ssh_public_key", "")
    }
  }

  # Managed DevOps Pool configurations (can be overridden per environment):
  default_managed_devops_pool_configs = {
    core = {
      vnet_key              = "core"
      maximum_concurrency   = 2
      open_access           = true
      parallelism           = 2
      prediction_preference = "BestPerformance"
      vm_sku                = "Standard_B2s"
      image_name            = "ubuntu-22.04"
      logon_type            = "Service"
      os_disk_type          = "StandardSSD"
      specific_tags = {
        PoolType = "Managed DevOps Pool"
      }
    }
    # Add more pools if needed:
  }

  # VMSS Agent Pool configurations (can be overridden per environment):
  default_vmss_agent_pool_configs = {
    core = {
      vnet_key             = "core"
      subnet_key           = "private"
      vmss_sku             = "Standard_B2ms"
      vmss_instance_count  = 0
      admin_username       = "adminuser"
      vmss_image_publisher = "Canonical"
      vmss_image_offer     = "0001-com-ubuntu-server-focal"
      vmss_image_sku       = "20_04-lts"
      vmss_image_version   = "20.04.202505200"
      vmss_os_disk_type    = "Standard_LRS"
      specific_tags = {
        PoolType = "VMSS Agent Pool"
      }
    }
    # Add more VMSS pools if needed:
  }

  # # Classic VMSS Agent Pool configurations (can be overridden per environment):
  # default_classic_vmss_agent_pool_configs = {
  #   core = {
  #     vnet_key                     = "core"
  #     subnet_key                   = "private"
  #     classic_vmss_sku             = "Standard_B2ms"
  #     classic_vmss_instance_count  = 1
  #     admin_username               = "adminuser"
  #     classic_vmss_image_publisher = "Canonical"
  #     classic_vmss_image_offer     = "0001-com-ubuntu-server-focal"
  #     classic_vmss_image_sku       = "20_04-lts"
  #     classic_vmss_image_version   = "latest"
  #     classic_vmss_os_disk_type    = "Standard_LRS"
  #     specific_tags = {
  #       PoolType = "VMSS Agent Pool"
  #     }
  #   }
  #   # Add more VMSS pools if needed:
  # }

  # Service Connections configurations (can be overridden per environment):
  default_service_connection_configs = {
    oidc = {
      name_suffix           = "oidc"
      description           = "Managed by Terraform - OIDC Authentication"
      authentication_scheme = "WorkloadIdentityFederation"
      specific_tags = {
        AuthType = "OIDC"
      }
    }
    # Add more Service Connections if needed:
  }

  # Bastion configurations (can be overridden per environment):
  # default_bastion_configs = {
  #   primary = {
  #     name_prefix                  = "bastion"
  #     public_ip_name_prefix        = "public-ip-bastion"
  #     nic_name_prefix              = "nic-bastion-jump"
  #     vnet_key                     = "core"
  #     subnet_key                   = "public"
  #     vm_size                      = "Standard_B1s"
  #     admin_username               = "bastionuser"
  #     os_disk_caching              = "ReadWrite"
  #     os_disk_storage_account_type = "Standard_LRS"
  #     image_publisher              = "Canonical"
  #     image_offer                  = "0001-com-ubuntu-server-focal"
  #     image_sku                    = "20_04-lts"
  #     image_version                = "latest"
  #     specific_tags = {
  #       Purpose = "Bastion Host"
  #     }
  #   }
  # }

  # More configurations:

}

inputs = merge(local.common_inputs, {
  tags                        = local.common_tags
  vnet_configs                = local.default_vnets
  dns_configs                 = local.default_dns_configs
  key_vault_configs           = local.default_key_vault_configs
  key_vault_secrets           = local.key_vault_secrets
  managed_devops_pool_configs = local.default_managed_devops_pool_configs
  vmss_agent_pool_configs     = local.default_vmss_agent_pool_configs
  service_connection_configs  = local.default_service_connection_configs
  # classic_vmss_agent_pool_configs = local.default_classic_vmss_agent_pool_configs
  # bastion_configs                 = local.default_bastion_configs
})

# ====================================================================
# Remote state configuration
# ====================================================================
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-${local.env}-core"
    storage_account_name = "saluis${local.env}tfstate"
    container_name       = "tfstate-${local.env}"
    key                  = "infra.${local.env}.terraform.tfstate"
  }
}
