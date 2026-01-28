#-------------------------------------
# Resource Group Outputs (Required for infra layer)
#------------------------------------
output "resource_group_name" {
  description = "The name of the main resource group"
  value       = module.resource_groups["core"].resource_group_name
}

output "resource_group_id" {
  description = "The ID of the main resource group"
  value       = module.resource_groups["core"].resource_group_id
}

#-------------------------------------
# Storage Account Outputs (Required for infra layer)
#------------------------------------
output "storage_account_name" {
  description = "The name of the main storage account"
  value       = module.storage_accounts["tfstate"].storage_account_name
}

output "storage_account_id" {
  description = "The ID of the main storage account"
  value       = module.storage_accounts["tfstate"].storage_account_id
}
