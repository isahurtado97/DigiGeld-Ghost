#!/bin/bash

# Check if the required parameters are passed
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <resource_group> <location> <acr_name> [<cluster_name> <node_count> <vm_size>]"
    echo "Example: $0 dg-rg-prod northeurope dgacrprod dgaksprod 3 Standard_DS2_v2"
    exit 1
fi

# Assign command-line arguments to variables
RESOURCE_GROUP=$1
ACR_NAME=$2
CLUSTER_NAME=${3:-"example:dg-aks-acc"} # Default value if not provided

#Workspace Id
WORKSPACEID=$(az monitor log-analytics workspace show \
    --resource-group $RESOURCE_GROUP \
    --workspace-name "$CLUSTER_NAME-Workspace" \
    --query id --output tsv)

echo "Checking if AKS cluster '$CLUSTER_NAME' exists in resource group '$RESOURCE_GROUP'..."
CLUSTER_EXIST=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "name" --output tsv 2>/dev/null)

if [[ -z $CLUSTER_EXIST ]]; then
    echo "AKS cluster '$CLUSTER_NAME' does not exist. Creating it now..."
    # Create AKS Cluster and Attach ACR
    echo "Creating AKS Cluster..."
    az aks create \
      --resource-group $RESOURCE_GROUP \
      --node-resource-group $CLUSTER_NAME \
      --name $CLUSTER_NAME \
      --node-count 3 \
      --node-vm-size "Standard_DS2_v2" \
      --enable-managed-identity \
      --generate-ssh-keys \
      --attach-acr $ACR_NAME \
      --enable-addons monitoring \
      --enable-cluster-autoscaler \
      --min-count 1 \
      --max-count 5 \
      --workspace-resource-id $WORKSPACEID
    echo "AKS cluster '$CLUSTER_NAME' created successfully."
else
    echo "AKS cluster '$CLUSTER_NAME' already exists."
fi
#Deploy akv2k8s 
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
helm repo add spv-charts https://charts.spvapi.no
helm repo update
helm install akv2k8s spv-charts/akv2k8s --namespace akv2k8s --create-namespace
# Get the AKS managed identity object ID
aksIdentity=$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query identityProfile.kubeletidentity.objectId -o tsv)
echo "AKS Managed Identity Object ID: $aksIdentity"

# Get the Key Vault resource ID
keyVaultResourceId=$(az keyvault show --name "$CLUSTER_NAME-vault" --resource-group $RESOURCE_GROUP --query id -o tsv)
echo "Key Vault Resource ID: $keyVaultResourceId"

# Assign the required roles to the AKS identity
# Assign Key Vault Secrets User Role
az role assignment create --assignee $aksIdentity --role "Key Vault Secrets User" --scope $keyVaultResourceId
echo "Key Vault Secrets User Role assigned to AKS Managed Identity."