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
    az keyvault create --name "$clusterName-vault" --resource-group "$resourceGroup" --location "$location" --enable-rbac-authorization
else
    echo "Key Vault '$clusterName-vault' already exists."
fi

#Create service principal role asignments
subscription=$(az account show --query "id" -o tsv)
id=$(az ad sp create-for-rbac --name "$Service_Principal_Name"  --query "appId" -o tsv)
az role assignment create --assignee-object-id $id  --role "Key Vault Secrets officer"  --assignee-principal-type ServicePrincipal --scope "/subscriptions/$subscription/resourcegroups/$resourceGroup/providers/microsoft.keyvault/vaults/$clusterName-vault"

# Define secrets
existingSecret=$(az keyvault secret show --vault-name "$clusterName-vault" --name "root-password" 2>/dev/null)
if [ -z "$existingSecret" ]; then
    echo "Creating secret 'root-password'"
    az keyvault secret set --vault-name "$clusterName-vault" --name "root-password" --value "$root_password"
fi
existingSecret=$(az keyvault secret show --vault-name "$clusterName-vault" --name "user" 2>/dev/null)
if [ -z "$existingSecret" ]; then
    echo "Creating secret 'user'"
    az keyvault secret set --vault-name "$clusterName-vault" --name "user" --value "$user"
fi
existingSecret=$(az keyvault secret show --vault-name "$clusterName-vault" --name "password" 2>/dev/null)
if [ -z "$existingSecret" ]; then
    echo "Creating secret 'password'"
    az keyvault secret set --vault-name "$clusterName-vault" --name "password" --value "$password"
fi