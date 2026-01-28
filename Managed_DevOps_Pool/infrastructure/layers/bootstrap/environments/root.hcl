# ====================================================================
# Bootstrap Module Source Configuration
# ====================================================================
terraform {
  source = "../../../..//layers/bootstrap"
}

# ====================================================================
# Common input and common tags variables for infra layer - makes them available to all child modules
# ====================================================================
locals {
  env      = get_env("ENVIRONMENT", "dev")         # Environment default set to 'dev' if not provided
  location = get_env("AZURE_LOCATION", "UK South") # Location default set to 'UK South' if not provided

  common_inputs = {
    location        = local.location
    subscription_id = "6fc684c9-bd7f-420a-b697-ef8b122f4d85"
    environment     = local.env
  }

  common_tags = {
    Project     = "Managed-DevOps-Pools"
    Environment = local.env
  }

  # Resource groups configuration (can be overridden per environment)
  default_resource_groups = {
    core = {
      suffix_name = "core"
      location    = local.location
      specific_tags = {
        Purpose = "Core Infrastructure"
        Company = "Node4"
      }
    }

    # ↓ Add more resource groups if needed ↓
    # security   = {
    #   suffix = "security",
    #   location = "West Europe",
    #   specific_tags = {
    #     Purpose = "Security Resources"
    #     CostCenter = "IT-Networking"
    #     SecurityLevel = "High"
    #   }
    # }
  }

  # Storage accounts configuration (can be overridden per environment)
  default_storage_accounts = {
    tfstate = {
      suffix_name        = "tfstate"
      resource_group_key = "core"
      containers = {
        tfstate = {
          name                  = "tfstate-${local.env}"
          container_access_type = "private"
        }
        repo_files = {
          name                  = "repo-files-${local.env}"
          container_access_type = "private"
        }
      }
      private_endpoint_name           = "sa-tfstate-pep-${local.env}"
      private_service_connection_name = "sa-tfstate-psc-${local.env}"
      specific_tags = {
        Purpose = "Terraform State Storage"
      }
    }

    # ↓ Add more storage accounts if needed ↓
    # logs = {
    #   suffix_name        = "logs"
    #   resource_group_key = "core"
    #   containers = {
    #     logs = {
    #       name                  = "logs-${local.env}"
    #       container_access_type = "private"
    #     }
    #   }
    # }
  }
}

inputs = merge(local.common_inputs, {
  tags             = local.common_tags
  resource_groups  = local.default_resource_groups
  storage_accounts = local.default_storage_accounts
})

# ====================================================================
# Remote state configuration - for first run comment out remote backend and run it locally, then uncomment below code and use remote backend
# ====================================================================
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-${local.env}-core"
    storage_account_name = "saluis${local.env}tfstate"
    container_name       = "tfstate-${local.env}"
    key                  = "bootstrap.${local.env}.terraform.tfstate"
  }
}
