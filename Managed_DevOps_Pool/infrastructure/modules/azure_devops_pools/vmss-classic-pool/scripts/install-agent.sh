#!/bin/bash

set -euo pipefail # Exit/Fail on error or unset variable

# --- Variables (injected via Terraform templatefile) ---
AZP_URL="${devops_org_url}"
PAT_SECRET_NAME="${pat_secret_name}"
KEYVAULT_NAME="${key_vault_name}"
AZP_POOL="${classic_agent_pool_queue}"
AGENT_USER="${admin_username}"

# --- Agent Directory Variables ---
AGENT_DIR="/opt/azdo/agent"
AGENT_NAME="$(hostname)"

# --- Install required packages ---
sudo apt-get update -y
sudo apt-get install -y curl jq unzip apt-transport-https lsb-release gnupg uuid-runtime

# --- Install Azure CLI if missing ---
if ! command -v az &>/dev/null; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# --- Login with Managed Identity ---
az login --identity --allow-no-subscriptions >/dev/null

# --- Retrieve PAT from Key Vault ---
AZP_TOKEN=$(az keyvault secret show \
  --vault-name "$KEYVAULT_NAME" \
  --name "$PAT_SECRET_NAME" \
  --query value -o tsv)

if [[ -z "$AZP_TOKEN" ]]; then
    echo "ERROR: Failed to retrieve PAT from Key Vault"
    exit 1
fi

# --- Get latest agent version ---
AGENT_VERSION=$(curl -s https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest \
  | jq -r '.tag_name' | sed 's/v//')

AGENT_URL="https://download.agent.dev.azure.com/agent/$AGENT_VERSION/vsts-agent-linux-x64-$AGENT_VERSION.tar.gz"

# --- Create agent directory ---
sudo mkdir -p "$AGENT_DIR"
sudo chown "$AGENT_USER:$AGENT_USER" "$AGENT_DIR"

# --- Download and extract agent ---
cd "$AGENT_DIR"
curl -LsS --fail "$AGENT_URL" | sudo tar zx --no-same-owner
sudo chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_DIR"
chmod +x config.sh run.sh

# --- Install agent dependencies ---
sudo ./bin/installdependencies.sh

# --- Configure the agent ---
sudo -u "$AGENT_USER" ./config.sh --unattended \
  --url "$AZP_URL" \
  --auth pat \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --agent "$AGENT_NAME" \
  --replace \
  --acceptTeeEula \
  --work _work

# --- Install and start as service ---
sudo ./svc.sh install "$AGENT_USER"
sudo ./svc.sh start

echo "✅ Azure DevOps agent installed and running."
