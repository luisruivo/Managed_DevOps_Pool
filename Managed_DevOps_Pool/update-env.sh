#!/bin/bash

ENVIRONMENT=${1:-dev}

case "$ENVIRONMENT" in
  dev)
    KV_NAME="kv-dev-luis"
    ;;
  test)
    KV_NAME="kv-test-luis"
    ;;
  prod)
    KV_NAME="kv-prod-luis"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

echo "TF_VAR_pat_value=$(az keyvault secret show --vault-name $KV_NAME --name azure-devops-pat-$ENVIRONMENT --query value -o tsv)" > .env
echo "TF_VAR_admin_ssh_public_key=\"$(az keyvault secret show --vault-name $KV_NAME --name admin-ssh-public-key-$ENVIRONMENT --query value -o tsv)\"" >> .env