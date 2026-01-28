#!/bin/bash

# ------------------------
# 0. Install Azure DevOps CLI extension if missing
# ------------------------
if ! az extension show --name azure-devops &>/dev/null; then
  echo "Azure DevOps CLI extension not found. Installing..."
  az extension add --name azure-devops
else
  echo "Azure DevOps CLI extension already installed."
fi


# ------------------------
# Load .env file if it exists and set AZURE_DEVOPS_PAT from TF_VAR_pat_value
# ------------------------
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi
if [ -z "$AZURE_DEVOPS_PAT" ] && [ -n "$TF_VAR_pat_value" ]; then
  AZURE_DEVOPS_PAT="$TF_VAR_pat_value"
fi

# ------------------------
# CONFIGURATION VARIABLES
# ------------------------
SP_NAME="bootstrap-sp"
SUBSCRIPTION_ID="6fc684c9-bd7f-420a-b697-ef8b122f4d85"
RESOURCE_GROUP="bootstrap-sp-rg"
RG_LOCATION="uksouth"
KV_NAME="bootstrap-sp-kv-luis"
DEVOPS_ORG_URL="https://dev.azure.com/Ruivo21"
DEVOPS_PROJECT="Managed-DevOps-Pools"
DEVOPS_SERVICE_CONNECTION_NAME="ado-bootstrap-sp-connection"
SUBSCRIPTION_NAME="Visual Studio Enterprise Subscription – MPN"

# ------------------------
# 1. Configure defaults for Azure DevOps CLI
# ------------------------
az devops configure --defaults organization=$DEVOPS_ORG_URL project=$DEVOPS_PROJECT

# ------------------------
# 2. Get Project ID (Required for service connection)
# ------------------------
PROJECT_ID=$(az devops project show --project "$DEVOPS_PROJECT" --query id -o tsv)
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Could not retrieve project ID for $DEVOPS_PROJECT"
  exit 1
fi
echo "Project ID: $PROJECT_ID"

# ------------------------
# 3. Detect or create Azure DevOps Service Connection SP
# ------------------------
EXISTING_SC=$(az devops service-endpoint list --query "[?name=='$DEVOPS_SERVICE_CONNECTION_NAME'].id" -o tsv)

if [ -z "$EXISTING_SC" ]; then
  echo "Service Connection $DEVOPS_SERVICE_CONNECTION_NAME not found. Creating..."

  # Create SP for DevOps connection
  DEVOPS_SP_JSON=$(az ad sp create-for-rbac --name "$DEVOPS_SERVICE_CONNECTION_NAME" --role Contributor --scopes /subscriptions/$SUBSCRIPTION_ID --sdk-auth)
  DEVOPS_SP_ID=$(echo $DEVOPS_SP_JSON | jq -r .clientId)
  DEVOPS_SP_SECRET=$(echo $DEVOPS_SP_JSON | jq -r .clientSecret)
  DEVOPS_SP_TENANT=$(echo $DEVOPS_SP_JSON | jq -r .tenantId)

  # Create the service connection using REST API with corrected structure
  SERVICE_CONNECTION_JSON=$(cat <<EOF
{
  "data": {
    "subscriptionId": "$SUBSCRIPTION_ID",
    "subscriptionName": "$SUBSCRIPTION_NAME",
    "environment": "AzureCloud",
    "scopeLevel": "Subscription",
    "creationMode": "Manual"
  },
  "name": "$DEVOPS_SERVICE_CONNECTION_NAME",
  "type": "AzureRM",
  "url": "https://management.azure.com/",
  "authorization": {
    "parameters": {
      "tenantid": "$DEVOPS_SP_TENANT",
      "serviceprincipalid": "$DEVOPS_SP_ID",
      "authenticationType": "spnKey",
      "serviceprincipalkey": "$DEVOPS_SP_SECRET"
    },
    "scheme": "ServicePrincipal"
  },
  "isShared": false,
  "isReady": true,
  "serviceEndpointProjectReferences": [
    {
      "projectReference": {
        "id": "$PROJECT_ID",
        "name": "$DEVOPS_PROJECT"
      },
      "name": "$DEVOPS_SERVICE_CONNECTION_NAME"
    }
  ]
}
EOF
)

  # Extract organization name from URL
  ORG_NAME=$(echo $DEVOPS_ORG_URL | sed 's|https://dev.azure.com/||')

  # Create service connection via REST API
  echo "Creating service connection via REST API..."

  # Check authentication status
  echo "Checking Azure DevOps authentication..."
  if ! az devops project show --project "$DEVOPS_PROJECT" &>/dev/null; then
    echo "Error: Not authenticated to Azure DevOps. Please run: az devops login"
    exit 1
  fi

  # Save JSON to temporary file for debugging
  echo "$SERVICE_CONNECTION_JSON" > /tmp/service_connection.json
  echo "Service connection JSON saved to /tmp/service_connection.json for debugging"

  # Create service connection via REST API with explicit resource parameter (https://learn.microsoft.com/en-us/azure/devops/cli/entra-tokens?view=azure-devops&tabs=azure-cli)
  RESPONSE=$(az rest \
    --method POST \
    --uri "https://dev.azure.com/$ORG_NAME/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4" \
    --body "$SERVICE_CONNECTION_JSON" \
    --headers "Content-Type=application/json" \
    --resource "499b84ac-1321-427f-aa17-267ca6975798" \
    --output json 2>/tmp/az_rest_error.log)

  # Check the exit code and response
  REST_EXIT_CODE=$?
  if [ $REST_EXIT_CODE -eq 0 ] && echo "$RESPONSE" | jq . &>/dev/null; then
    SC_ID=$(echo "$RESPONSE" | jq -r '.id // empty')
    if [ -n "$SC_ID" ] && [ "$SC_ID" != "null" ]; then
      echo "Service Connection created successfully with ID: $SC_ID"
      echo "Service Connection $DEVOPS_SERVICE_CONNECTION_NAME created with SP ID $DEVOPS_SP_ID"
    else
      echo "Service connection creation response received but no ID found"
      echo "Response: $RESPONSE"
    fi
  else
    echo "Failed to create service connection via REST API"
    echo "Exit code: $REST_EXIT_CODE"
    echo "Response: $RESPONSE"
    echo "Error log:"
    cat /tmp/az_rest_error.log 2>/dev/null || echo "No error log available"

    # Try alternative method using Azure DevOps CLI
    echo ""
    echo "Attempting alternative method using Azure DevOps CLI..."

    # Create temporary file with service connection details
    TEMP_SC_FILE="/tmp/service_connection_create.json"
    cat > "$TEMP_SC_FILE" <<EOF
{
  "data": {
    "subscriptionId": "$SUBSCRIPTION_ID",
    "subscriptionName": "$SUBSCRIPTION_NAME",
    "environment": "AzureCloud",
    "scopeLevel": "Subscription"
  },
  "name": "$DEVOPS_SERVICE_CONNECTION_NAME",
  "type": "AzureRM",
  "url": "https://management.azure.com/",
  "authorization": {
    "parameters": {
      "tenantid": "$DEVOPS_SP_TENANT",
      "serviceprincipalid": "$DEVOPS_SP_ID",
      "serviceprincipalkey": "$DEVOPS_SP_SECRET"
    },
    "scheme": "ServicePrincipal"
  }
}
EOF

    # Try creating with az devops service-endpoint create
    if az devops service-endpoint azurerm create \
        --azure-rm-service-principal-id "$DEVOPS_SP_ID" \
        --azure-rm-service-principal-key "$DEVOPS_SP_SECRET" \
        --azure-rm-tenant-id "$DEVOPS_SP_TENANT" \
        --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
        --azure-rm-subscription-name "$SUBSCRIPTION_NAME" \
        --name "$DEVOPS_SERVICE_CONNECTION_NAME" &>/dev/null; then
      echo "Service connection created successfully using Azure DevOps CLI"
    else
      echo "Both REST API and CLI methods failed. Manual creation may be required."
      echo ""
      echo "Manual creation details:"
      echo "Service Principal ID: $DEVOPS_SP_ID"
      echo "Service Principal Secret: $DEVOPS_SP_SECRET"
      echo "Tenant ID: $DEVOPS_SP_TENANT"
      echo "Subscription ID: $SUBSCRIPTION_ID"
      echo "Subscription Name: $SUBSCRIPTION_NAME"
    fi

    # Clean up temporary file
    rm -f "$TEMP_SC_FILE"
  fi
else
  DEVOPS_SP_ID=$(az devops service-endpoint show --id $EXISTING_SC --query "authorization.parameters.serviceprincipalid" -o tsv)
  echo "Found existing service connection $DEVOPS_SERVICE_CONNECTION_NAME with SP ID $DEVOPS_SP_ID"
fi

# Verify the service connection was created and is visible
echo "Verifying service connection..."
VERIFY_SC=$(az devops service-endpoint list --query "[?name=='$DEVOPS_SERVICE_CONNECTION_NAME'].{id:id,name:name,type:type}" -o table)
echo "$VERIFY_SC"

# ------------------------
# 4. Create Resource Group if it doesn't exist
# ------------------------
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
  echo "Creating resource group $RESOURCE_GROUP in $RG_LOCATION"
  az group create --name $RESOURCE_GROUP --location $RG_LOCATION
else
  echo "Resource group $RESOURCE_GROUP already exists"
fi

# ------------------------
# 5. Create bootstrap Service Principal
# ------------------------
SP_JSON=$(az ad sp create-for-rbac --name $SP_NAME --skip-assignment --output json)
CLIENT_ID=$(echo $SP_JSON | jq -r .appId)
CLIENT_SECRET=$(echo $SP_JSON | jq -r .password)
TENANT_ID=$(echo $SP_JSON | jq -r .tenant)

echo "Created bootstrap SP: $CLIENT_ID"

# ------------------------
# 6. Assign temporary Owner role to bootstrap SP
# ------------------------
az role assignment create --assignee $CLIENT_ID --role Owner --scope /subscriptions/$SUBSCRIPTION_ID
echo "Temporary Owner assigned to bootstrap SP"

# ------------------------
# 6a. Assign Storage Blob Data Contributor role to bootstrap SP (for storage operations)
# ------------------------
az role assignment create --assignee $CLIENT_ID --role "Storage Blob Data Contributor" --scope /subscriptions/$SUBSCRIPTION_ID
echo "Storage Blob Data Contributor role assigned to bootstrap SP"

# ------------------------
# 6b. Assign Key Vault Secrets Officer role to bootstrap SP (for Key Vault operations)
# ------------------------
az role assignment create --assignee $CLIENT_ID --role "Key Vault Secrets Officer" --scope /subscriptions/$SUBSCRIPTION_ID
echo "Key Vault Secrets Officer role assigned to bootstrap SP"

# ------------------------
# 6c. Assign Privileged Role Administrator directory role to bootstrap SP (for Azure AD operations)
# ------------------------
echo "Assigning Privileged Role Administrator directory role to bootstrap SP..."
BOOTSTRAP_SP_OBJECT_ID=$(az ad sp show --id $CLIENT_ID --query "id" -o tsv)

# Get the Privileged Role Administrator role template ID
PRA_ROLE_ID=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoleTemplates" --query "value[?displayName=='Privileged Role Administrator'].id | [0]" -o tsv)

if [ -n "$PRA_ROLE_ID" ]; then
    # Check if directory role is activated
    PRA_DIRECTORY_ROLE_ID=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoles" --query "value[?roleTemplateId=='$PRA_ROLE_ID'].id | [0]" -o tsv)

    if [ -z "$PRA_DIRECTORY_ROLE_ID" ] || [ "$PRA_DIRECTORY_ROLE_ID" = "null" ]; then
        echo "Activating Privileged Role Administrator directory role..."
        PRA_DIRECTORY_ROLE_ID=$(az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles" --body "{\"roleTemplateId\":\"$PRA_ROLE_ID\"}" --query "id" -o tsv)
    fi

    # Check if SP is already a member of this role
    EXISTING_PRA_MEMBER=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoles/$PRA_DIRECTORY_ROLE_ID/members" --query "value[?id=='$BOOTSTRAP_SP_OBJECT_ID'].id | [0]" -o tsv)

    if [ -n "$EXISTING_PRA_MEMBER" ] && [ "$EXISTING_PRA_MEMBER" != "null" ]; then
        echo "Privileged Role Administrator role already assigned to bootstrap SP"
    else
        # Assign the role to the service principal
        if az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles/$PRA_DIRECTORY_ROLE_ID/members/\$ref" --body "{\"@odata.id\":\"https://graph.microsoft.com/v1.0/directoryObjects/$BOOTSTRAP_SP_OBJECT_ID\"}" &>/dev/null; then
            echo "Privileged Role Administrator role assigned to bootstrap SP"
        else
            echo "Privileged Role Administrator role assignment failed (may already exist)"
        fi
    fi
else
    echo "Warning: Could not find Privileged Role Administrator role template ID"
    echo "Please manually assign Privileged Role Administrator role to SP: $CLIENT_ID"
fi

# ------------------------
# 6d. Assign Directory Readers directory role to bootstrap SP (for Azure AD read operations)
# ------------------------
echo "Assigning Directory Readers directory role to bootstrap SP..."

# Get the Directory Readers role template ID
DIR_READERS_ROLE_ID=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoleTemplates" --query "value[?displayName=='Directory Readers'].id | [0]" -o tsv)

if [ -n "$DIR_READERS_ROLE_ID" ]; then
    # Check if directory role is activated
    DIR_READERS_DIRECTORY_ROLE_ID=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoles" --query "value[?roleTemplateId=='$DIR_READERS_ROLE_ID'].id | [0]" -o tsv)

    if [ -z "$DIR_READERS_DIRECTORY_ROLE_ID" ] || [ "$DIR_READERS_DIRECTORY_ROLE_ID" = "null" ]; then
        echo "Activating Directory Readers directory role..."
        DIR_READERS_DIRECTORY_ROLE_ID=$(az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles" --body "{\"roleTemplateId\":\"$DIR_READERS_ROLE_ID\"}" --query "id" -o tsv)
    fi

    # Check if SP is already a member of this role
    EXISTING_DIR_READER=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoles/$DIR_READERS_DIRECTORY_ROLE_ID/members" --query "value[?id=='$BOOTSTRAP_SP_OBJECT_ID'].id | [0]" -o tsv)

    if [ -n "$EXISTING_DIR_READER" ] && [ "$EXISTING_DIR_READER" != "null" ]; then
        echo "Directory Readers role already assigned to bootstrap SP"
    else
        # Assign the role to the service principal
        if az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles/$DIR_READERS_DIRECTORY_ROLE_ID/members/\$ref" --body "{\"@odata.id\":\"https://graph.microsoft.com/v1.0/directoryObjects/$BOOTSTRAP_SP_OBJECT_ID\"}" &>/dev/null; then
            echo "Directory Readers role assigned to bootstrap SP"
        else
            echo "Directory Readers role assignment failed (may already exist)"
        fi
    fi
else
    echo "Warning: Could not find Directory Readers role template ID"
    echo "Please manually assign Directory Readers role to SP: $CLIENT_ID"
fi

# ------------------------
# 6e. Assign Application Administrator role to bootstrap SP (for Azure AD read operations)
# ------------------------
echo "Assigning Application Administrator directory role to bootstrap SP..."

# Get the Application Administrator role template ID
APP_ADMIN_ROLE_ID=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoleTemplates" --query "value[?displayName=='Application Administrator'].id | [0]" -o tsv)

if [ -n "$APP_ADMIN_ROLE_ID" ]; then
    # Check if directory role is activated
    APP_ADMIN_DIRECTORY_ROLE_ID=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoles" --query "value[?roleTemplateId=='$APP_ADMIN_ROLE_ID'].id | [0]" -o tsv)

    if [ -z "$APP_ADMIN_DIRECTORY_ROLE_ID" ] || [ "$APP_ADMIN_DIRECTORY_ROLE_ID" = "null" ]; then
        echo "Activating Application Administrator directory role..."
        APP_ADMIN_DIRECTORY_ROLE_ID=$(az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles" --body "{\"roleTemplateId\":\"$APP_ADMIN_ROLE_ID\"}" --query "id" -o tsv)
    fi

    # Check if SP is already a member of this role
    EXISTING_APP_ADMIN=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoles/$APP_ADMIN_DIRECTORY_ROLE_ID/members" --query "value[?id=='$BOOTSTRAP_SP_OBJECT_ID'].id | [0]" -o tsv)

    if [ -n "$EXISTING_APP_ADMIN" ] && [ "$EXISTING_APP_ADMIN" != "null" ]; then
        echo "Application Administrator role already assigned to bootstrap SP"
    else
        # Assign the role to the service principal
        if az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles/$APP_ADMIN_DIRECTORY_ROLE_ID/members/\$ref" --body "{\"@odata.id\":\"https://graph.microsoft.com/v1.0/directoryObjects/$BOOTSTRAP_SP_OBJECT_ID\"}" &>/dev/null; then
            echo "Application Administrator role assigned to bootstrap SP"
        else
            echo "Application Administrator role assignment failed (may already exist)"
        fi
    fi
else
    echo "Warning: Could not find Application Administrator role template ID"
    echo "Please manually assign Application Administrator role to SP: $CLIENT_ID"
fi

# ------------------------
# 7. Create Key Vault if it doesn't exist
# ------------------------
if ! az keyvault show --name $KV_NAME &>/dev/null; then
  echo "Creating Key Vault $KV_NAME in resource group $RESOURCE_GROUP"
  az keyvault create \
    --name $KV_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $RG_LOCATION \
    --sku standard
else
  echo "Key Vault $KV_NAME already exists"
fi

# ------------------------
# 8. Store bootstrap SP secrets in Key Vault
# ------------------------
az keyvault secret set --vault-name $KV_NAME --name "ARM-CLIENT-ID" --value "$CLIENT_ID"
az keyvault secret set --vault-name $KV_NAME --name "ARM-CLIENT-SECRET" --value "$CLIENT_SECRET"
az keyvault secret set --vault-name $KV_NAME --name "ARM-TENANT-ID" --value "$TENANT_ID"
az keyvault secret set --vault-name $KV_NAME --name "ARM-SUBSCRIPTION-ID" --value "$SUBSCRIPTION_ID"

echo "Bootstrap SP credentials stored in Key Vault: $KV_NAME"

# ------------------------
# 8a. Store Azure DevOps PAT in Key Vault
# ------------------------
if [ -z "$AZURE_DEVOPS_PAT" ]; then
  read -s -p "Enter your Azure DevOps PAT: " AZURE_DEVOPS_PAT
  echo
fi
az keyvault secret set --vault-name $KV_NAME --name "azure-devops-pat-bootstrap" --value "$AZURE_DEVOPS_PAT"
echo "Azure DevOps PAT stored in Key Vault: $KV_NAME"

# ------------------------
# 9. Ensure ~/.ssh directory exists
# ------------------------
SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
  echo "Creating ~/.ssh directory..."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
else
  echo "~/.ssh directory already exists. Using existing directory."
fi

# ------------------------
# 9a. Generate SSH key pair for VMSS
# ------------------------
SSH_KEY_NAME="managed-devops-pools-key"
SSH_KEY_PATH="$SSH_DIR/$SSH_KEY_NAME"

# Generate SSH key (overwrite if exists)
ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "DevOps Infrastructure Shared Key (VMSS & Bastion)"

# ------------------------
# 10. Store public key in Key Vault
# ------------------------
az keyvault secret set --vault-name $KV_NAME --name "devops-infrastructure-key-public" --value "$(cat $SSH_KEY_PATH.pub)"
echo "Public key stored in Key Vault: $KV_NAME"

# ------------------------
# 11. Add public key to .env file for Terraform
# ------------------------
echo "TF_VAR_admin_ssh_public_key=\"$(cat ${SSH_KEY_PATH}.pub)\"" >> .env
echo "Public key added to .env file as TF_VAR_admin_ssh_public_key"

# ------------------------
# 12. Grant DevOps Service Connection SP access to Key Vault
# ------------------------
az role assignment create \
  --assignee $DEVOPS_SP_ID \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME"
echo "DevOps service connection granted access to Key Vault"

# ------------------------
# 13. Store environment-specific PAT and SSH public key secrets in Key Vault
# ------------------------
for ENV in dev test prod; do
  # Prompt for PAT for each environment
  read -s -p "Enter Azure DevOps PAT for $ENV: " PAT
  echo
  az keyvault secret set --vault-name $KV_NAME --name "azure-devops-pat-$ENV" --value "$PAT"
  echo "Azure DevOps PAT for $ENV stored in Key Vault: $KV_NAME"

  # Store SSH public key for each environment (reuse the generated one, or customize as needed)
  az keyvault secret set --vault-name $KV_NAME --name "managed-devops-pool-ssh-public-key-$ENV" --value "$(cat $SSH_KEY_PATH.pub)"
  echo "SSH public key for $ENV stored in Key Vault: $KV_NAME"
done

# ------------------------
# 14. Add Bootstrap SP to Azure DevOps Organization and Project
# ------------------------
echo ""
echo "========================================="
echo "Adding Bootstrap SP to Azure DevOps"
echo "========================================="

# Get the service principal's Object ID
BOOTSTRAP_SP_OBJECT_ID=$(az ad sp show --id $CLIENT_ID --query "id" -o tsv)

echo "Bootstrap SP Client ID: $CLIENT_ID"
echo "Bootstrap SP Object ID: $BOOTSTRAP_SP_OBJECT_ID"

# For service principals, Azure DevOps requires the format: appid@tenantid
SP_EMAIL_FORMAT="${CLIENT_ID}@${TENANT_ID}"

echo "Using email format for SP: $SP_EMAIL_FORMAT"

# Check if SP is already in Azure DevOps
EXISTING_SP_USER=$(az devops user list \
  --query "members[?user.principalName contains '$CLIENT_ID'].user.principalName" \
  -o tsv 2>/dev/null || echo "")

if [ -n "$EXISTING_SP_USER" ]; then
  echo "✓ Bootstrap SP is already a member of Azure DevOps"
else
  echo "Adding Bootstrap SP to Azure DevOps organization..."

  # Try adding with the appid@tenantid format
  az devops user add \
    --email-id "$SP_EMAIL_FORMAT" \
    --license-type express \
    --send-email-invite false 2>&1 | grep -q "cannot be invited"

  if [ $? -eq 0 ]; then
    echo "⚠ Service Principal from your tenant must be added via Azure DevOps UI"
  else
    # Check again if it was added successfully
    VERIFY_SP_USER=$(az devops user list \
      --query "members[?user.principalName contains '$CLIENT_ID'].user.principalName" \
      -o tsv 2>/dev/null || echo "")

    if [ -n "$VERIFY_SP_USER" ]; then
      echo "✓ Successfully added Bootstrap SP to Azure DevOps"
    else
      echo "⚠ Failed to add Bootstrap SP automatically"
    fi
  fi

  # Regardless of CLI result, show manual steps
  if [ -z "$VERIFY_SP_USER" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 MANUAL STEP 1: Add Bootstrap SP to Azure DevOps"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Open: $DEVOPS_ORG_URL/_settings/users"
    echo ""
    echo "2. Click 'Add users' button"
    echo ""
    echo "3. In the search box, enter:"
    echo "   $CLIENT_ID"
    echo ""
    echo "4. Select the service principal 'bootstrap-sp' from dropdown"
    echo ""
    echo "5. Access level: Select 'Basic'"
    echo ""
    echo "6. Click 'Add'"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Wait for user confirmation
    read -p "Press ENTER after completing the above step..."
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 MANUAL STEP 2: Grant Agent Pool Permissions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The Bootstrap SP needs Administrator permissions on Agent Pools"
echo "to allow pipelines to create Managed DevOps Pools."
echo ""
echo "1. Open: $DEVOPS_ORG_URL/_settings/agentpools"
echo ""
echo "2. Click 'Security' tab (top right, organization-level)"
echo ""
echo "3. Click 'Add' button"
echo ""
echo "4. Search for the service principal:"
echo "   • By Client ID: $CLIENT_ID"
echo "   • Or by name: bootstrap-sp"
echo ""
echo "5. Select role: 'Administrator'"
echo ""
echo "6. Click 'Save'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Wait for user confirmation
read -p "Press ENTER after completing the above step..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 MANUAL STEP 3: Grant Project-Level Permissions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The Bootstrap SP needs project-level permissions to create"
echo "and manage agent pools within the project."
echo ""
echo "1. Open: $DEVOPS_ORG_URL/$DEVOPS_PROJECT/_settings/permissions"
echo ""
echo "2. Click on 'Project Administrators' group"
echo ""
echo "3. Click 'Members' tab"
echo ""
echo "4. Click 'Add' button"
echo ""
echo "5. In the search box, enter:"
echo "   $CLIENT_ID"
echo ""
echo "6. Select the service principal 'bootstrap-sp' from dropdown"
echo ""
echo "7. Click 'Save'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Alternative: Grant specific Agent Queue permissions"
echo ""
echo "If you prefer minimal permissions instead of Project Administrator:"
echo ""
echo "1. Open: $DEVOPS_ORG_URL/$DEVOPS_PROJECT/_settings/agentqueues"
echo ""
echo "2. Click 'Security' tab"
echo ""
echo "3. Click 'Add' button"
echo ""
echo "4. Search for: $CLIENT_ID"
echo ""
echo "5. Select the service principal 'bootstrap-sp'"
echo ""
echo "6. Assign role: 'Administrator'"
echo ""
echo "7. Click 'Save'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Wait for user confirmation
read -p "Press ENTER after completing the above step..."

# Verify the SP is now in Azure DevOps
echo ""
echo "Verifying Bootstrap SP membership..."
FINAL_CHECK=$(az devops user list \
  --query "members[?user.principalName contains '$CLIENT_ID'].{name:user.displayName,email:user.principalName,access:accessLevel.accountLicenseType}" \
  -o table 2>/dev/null)

if [ -n "$FINAL_CHECK" ]; then
  echo "✓ Bootstrap SP verified in Azure DevOps:"
  echo "$FINAL_CHECK"
else
  echo "⚠ Warning: Could not verify Bootstrap SP membership"
  echo "Please ensure the SP was added correctly before proceeding"
fi

# Verify the SP is now in project membership
echo ""
echo "Attempting to verify project-level permissions..."
PROJECT_ADMINS=$(az devops security group membership list \
  --id "[$DEVOPS_PROJECT]\\Project Administrators" \
  --relationship members \
  --query "members[?contains(mailAddress, '$CLIENT_ID')].displayName" \
  -o tsv 2>/dev/null || echo "")

if [ -n "$PROJECT_ADMINS" ]; then
  echo "✓ Bootstrap SP verified as Project Administrator"
else
  echo "⚠ Could not automatically verify project permissions"
  echo "  Please ensure you completed MANUAL STEP 3"
fi

# Store the SP details in Key Vault for reference
az keyvault secret set --vault-name $KV_NAME --name "BOOTSTRAP-SP-CLIENT-ID" --value "$CLIENT_ID" --output none
az keyvault secret set --vault-name $KV_NAME --name "BOOTSTRAP-SP-OBJECT-ID" --value "$BOOTSTRAP_SP_OBJECT_ID" --output none
echo ""
echo "✓ Stored Bootstrap SP details in Key Vault"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Bootstrap Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary of completed steps:"
echo "✓ Bootstrap Service Principal created"
echo "✓ Azure RBAC roles assigned"
echo "✓ Key Vault created and credentials stored"
echo "✓ SSH keys generated and stored"
echo "✓ Azure DevOps service connection configured"
echo ""
echo "Required manual verifications:"
echo "1. Bootstrap SP added to Azure DevOps organization (MANUAL STEP 1)"
echo "2. Agent Pool Administrator permissions granted (MANUAL STEP 2)"
echo "3. Project-level permissions granted (MANUAL STEP 3)"
echo ""
echo "Key Vault: $KV_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo "Bootstrap SP Client ID: $CLIENT_ID"
echo "Bootstrap SP Object ID: $BOOTSTRAP_SP_OBJECT_ID"
echo ""
echo "Next steps:"
echo "1. Verify all manual steps were completed"
echo "2. Run your pipeline"
echo ""
