#!/bin/bash

# Parameters
clusterName=$1          # Key Vault name
resourceGroup=$2        # Resource Group name
location=$3             # Azure region
root_password=$4        # Root password secret
user=$5                # User secret
password=$6            # Password secret
Service_Principal_Name=$7

# Check if Key Vault exists
echo "Checking if Key Vault '$clusterName-vault' exists in resource group '$resourceGroup'..."
keyVault=$(az keyvault show --name "$clusterName-vault" --resource-group "$resourceGroup" 2>/dev/null)

if [ -z "$keyVault" ]; then
    echo "Key Vault '$clusterName' does not exist. Creating it..."
    az keyvault create --name "$clusterName-vault" --resource-group "$resourceGroup" --location "$location" --enable-rbac-authorization --enable-managed-identity
else
    echo "Key Vault '$clusterName-vault' already exists."
fi

#Create service principal role asignments
identityObjectId=$(az keyvault show --name "$clusterName-vault" --query "properties.identity.principalId" -o tsv)
az role assignment create \
  --assignee $identityObjectId \
  --role "Key Vault Contributor" \
  --scope "/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$clusterName-vault"

subscription=$(az account show --query "id" -o tsv)
az ad sp create-for-rbac --name "$Service_Principal_Name" --role Contributor --scopes "/subscriptions/$subscription"
id=$(az ad sp create-for-rbac --name "$Service_Principal_Name"  --query "appId" -o tsv)
az role assignment create --assignee-object-id $id  --role "Key Vault Secrets Officer"  --assignee-principal-type ServicePrincipal --scope "/subscriptions/$subscription/resourcegroups/$resourceGroup/providers/microsoft.keyvault/vaults/$clusterName-vault"

# Define secrets
declare -A secrets
secrets=(
    ["root-password"]="$root_password"
    ["user"]="$user"
    ["password"]="$password"
)

# Check and create secrets
echo "Checking and creating secrets in Key Vault '$clusterName-vault'..."
for secretName in "${!secrets[@]}"; do
    secretValue="${secrets[$secretName]}"
    existingSecret=$(az keyvault secret show --vault-name "$clusterName-vault" --name "$secretName" 2>/dev/null)
    
    if [ -z "$existingSecret" ]; then
        echo "Creating secret '$secretName'..."
        az keyvault secret set --vault-name "$clusterName-vault" --name "$secretName" --value "$secretValue"
    else
        echo "Secret '$secretName' already exists."
    fi
done

echo "Key Vault configuration complete."
