#-------------------------------------
# Azure Active Directory OIDC Role  - to registers an application in Azure AD
#------------------------------------
resource "azuread_application" "devops_oidc" {
  display_name = var.oidc_application_display_name

  api {
    requested_access_token_version = 2
  }
}

#-------------------------------------
# Service Principal for the OIDC Role - to enable the app (pipeline) to authenticate and receive permissions in Azure
#------------------------------------
resource "azuread_service_principal" "devops_oidc_sp" {
  client_id = azuread_application.devops_oidc.client_id
}

#-------------------------------------
# Federated Identity Credential - to allow Azure DevOps pipelines to authenticate to Azure AD using OIDC tokens
#------------------------------------
resource "azuread_application_federated_identity_credential" "devops_oidc" {
  count          = var.service_connection_issuer != null && var.service_connection_subject != null ? 1 : 0 # Only create the federated identity credential after the Azure DevOps service connection exists (issuer and subject are known), this prevents circular dependency during initial apply.
  display_name   = var.federated_credential_display_name
  application_id = azuread_application.devops_oidc.id
  audiences      = var.audience
  issuer         = var.service_connection_issuer
  subject        = var.service_connection_subject
}

#-------------------------------------
# Data Source to get Available Directory Roles for pipelines
#------------------------------------
data "azuread_directory_roles" "roles" {}

locals {
  app_admin_role = [for role in data.azuread_directory_roles.roles.roles : role if role.display_name == "Application Administrator"][0]
}

#-------------------------------------
# Grant Application Administrator Role to the Service Principal
#------------------------------------
resource "azuread_directory_role_assignment" "grant_app_admin_to_pipeline" {
  role_id             = local.app_admin_role.template_id
  principal_object_id = azuread_service_principal.devops_oidc_sp.object_id
}
