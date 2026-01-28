#!/bin/bash

# ------------------------
# CONFIGURATION VARIABLES
# ------------------------
BOOTSTRAP_SP_CLIENT_ID="173d14ae-9377-4dd2-8e6c-61930879eb5a" # Replace with your actual clientId
SUBSCRIPTION_ID="6fc684c9-bd7f-420a-b697-ef8b122f4d85"
DEVOPS_ORG_URL="https://dev.azure.com/Ruivo21"
DEVOPS_PROJECT="Managed-DevOps-Pools"
DEVOPS_SERVICE_CONNECTION_NAME="ado-bootstrap-sp-connection"
ADO_BOOTSTRAP_SP_APP_ID="5f9cf2c2-ec78-4a44-983c-e440937392ce" # Replace with your actual appId
RESOURCE_GROUP="bootstrap-sp-rg"
KV_NAME="bootstrap-sp-kv-luis"


# ------------------------
# 1. Confirm before removing Service Connection
# ------------------------
echo " This will remove the service connection ($DEVOPS_SERVICE_CONNECTION_NAME, appId: $ADO_BOOTSTRAP_SP_APP_ID)"
read -p "Are you sure you want to proceed? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 1
fi


# ------------------------
# 1a. Delete the service connection in Azure DevOps by name
# ------------------------
SC_ID=$(az devops service-endpoint list --query "[?name=='$DEVOPS_SERVICE_CONNECTION_NAME'].id" -o tsv)
if [ -n "$SC_ID" ]; then
    echo "Deleting Azure DevOps service connection: $DEVOPS_SERVICE_CONNECTION_NAME (ID: $SC_ID)"
    az devops service-endpoint delete --id "$SC_ID" --yes
    echo "Service connection deleted."
else
    echo "No service connection found with name: $DEVOPS_SERVICE_CONNECTION_NAME"
fi


# ------------------------
# 2. Confirm before removing bootstrap SP and service connection SP
# ------------------------
echo "This will remove the service principal for the bootstrap SP ($BOOTSTRAP_SP_CLIENT_ID) and the service connection ($DEVOPS_SERVICE_CONNECTION_NAME, appId: $ADO_BOOTSTRAP_SP_APP_ID)"
read -p "Are you sure you want to proceed? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 1
fi

echo "Removing service principal for bootstrap SP: $BOOTSTRAP_SP_CLIENT_ID"
echo "Removing service principal for service connection: $DEVOPS_SERVICE_CONNECTION_NAME (appId: $ADO_BOOTSTRAP_SP_APP_ID)"


# ------------------------
# 2a. Removing bootstrap and service connection SP
# ------------------------
# Delete the bootstrap service principal by clientId
if [ -n "$BOOTSTRAP_SP_CLIENT_ID" ]; then
    echo "Deleting bootstrap service principal for clientId: $BOOTSTRAP_SP_CLIENT_ID"
    az ad sp delete --id "$BOOTSTRAP_SP_CLIENT_ID"
    echo "Bootstrap service principal deleted."
else
    echo "No clientId provided for bootstrap service principal deletion."
fi

# Delete the service connection SP by appId
if [ -n "$ADO_BOOTSTRAP_SP_APP_ID" ]; then
    echo "Deleting service principal for appId: $ADO_BOOTSTRAP_SP_APP_ID"
    az ad sp delete --id "$ADO_BOOTSTRAP_SP_APP_ID"
    echo "Service principal deleted."
else
    echo "No appId provided for service principal deletion."
fi


# ------------------------
# 3. Delete Key Vault and its secrets
# ------------------------
read -p "Do you want to delete the Key Vault $KV_NAME and all its secrets? (y/N) " confirm_kv
if [[ "$confirm_kv" == "y" || "$confirm_kv" == "Y" ]]; then
    echo "Deleting Key Vault: $KV_NAME (this will also delete all secrets)"
    az keyvault delete --name $KV_NAME --resource-group $RESOURCE_GROUP
    echo "Key Vault deletion requested."
    # Optionally, purge the Key Vault if soft-delete is enabled
    read -p "Do you want to purge the Key Vault $KV_NAME (permanently delete)? (y/N) " confirm_purge
    if [[ "$confirm_purge" == "y" || "$confirm_purge" == "Y" ]]; then
        az keyvault purge --name $KV_NAME
        echo "Key Vault purged."
    fi
fi


# ------------------------
# 4. Delete Resource Group
# ------------------------
read -p "Do you want to delete the resource group $RESOURCE_GROUP and all its resources? (y/N) " confirm_rg
if [[ "$confirm_rg" == "y" || "$confirm_rg" == "Y" ]]; then
    echo "Deleting resource group: $RESOURCE_GROUP (this will delete all resources in the group)"
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    echo "Resource group deletion requested."
fi

