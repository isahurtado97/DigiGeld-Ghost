#!/bin/bash

# Parameters
clusterName=$1          # Key Vault name
resourceGroup=$2        # Resource Group name
location=$3             # Azure region
root_password=$4        # Root password secret
user=$5                # User secret
password=$6            # Password secret
Service_Principal_Name=$7

#Create service principal role asignment
subscription=$(az account show --query "id" -o tsv)
az ad sp create-for-rbac --name "$Service_Principal_Name" --role Contributor --scopes /subscriptions/$subscription
az ad sp create-for-rbac --name $clusterName --role Contributor --scopes /subscriptions/$subscription
# Check if Key Vault exists
echo "Checking if Key Vault '$clusterName' exists in resource group '$resourceGroup'..."
keyVault=$(az keyvault show --name "$clusterName" --resource-group "$resourceGroup" 2>/dev/null)

if [ -z "$keyVault" ]; then
    echo "Key Vault '$clusterName' does not exist. Creating it..."
    az keyvault create --name "$clusterName" --resource-group "$resourceGroup" --location "$location"
else
    echo "Key Vault '$clusterName' already exists."
fi

# Define secrets
declare -A secrets
secrets=(
    ["root-password"]="$root_password"
    ["user"]="$user"
    ["password"]="$password"
)

# Check and create secrets
echo "Checking and creating secrets in Key Vault '$clusterName'..."
for secretName in "${!secrets[@]}"; do
    secretValue="${secrets[$secretName]}"
    existingSecret=$(az keyvault secret show --vault-name "$clusterName" --name "$secretName" 2>/dev/null)
    
    if [ -z "$existingSecret" ]; then
        echo "Creating secret '$secretName'..."
        az keyvault secret set --vault-name "$clusterName" --name "$secretName" --value "$secretValue"
    else
        echo "Secret '$secretName' already exists."
    fi
done

echo "Key Vault configuration complete."
