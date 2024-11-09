#!/bin/bash

# Check if the required parameters are passed
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <resource_group> <location> <acr_name> [<cluster_name> <node_count> <vm_size>]"
    echo "Example: $0 dg-rg-prod northeurope dgacrprod dgaksprod 3 Standard_DS2_v2"
    exit 1
fi

# Assign command-line arguments to variables
RESOURCE_GROUP=$1
LOCATION=$2
ACR_NAME=$3
CLUSTER_NAME=${4:-"example"}  # Default value if not provided
NODE_COUNT=${5:-3}           # Default node count if not provided
VM_SIZE=${6:-"Standard_DS2_v2"}  # Default VM size if not provided

# Replace with your subscription ID and workspace details
SUBSCRIPTION_ID="<your-subscription-id>"
WORKSPACE_RESOURCE_GROUP="<workspace-resource-group>"
WORKSPACE_NAME="<workspace-name>"

# Derive the Log Analytics Workspace Resource ID
WORKSPACE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$WORKSPACE_RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE_NAME"

# 1. Create Resource Group if it does not exist
echo "Checking Resource Group..."
az group show --name $RESOURCE_GROUP --output none >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating Resource Group..."
    az group create --name $RESOURCE_GROUP --location $LOCATION --output none
    if [ $? -eq 0 ]; then
        echo "Resource Group $RESOURCE_GROUP created successfully."
    else
        echo "Failed to create Resource Group $RESOURCE_GROUP."
        exit 1
    fi
else
    echo "Resource Group $RESOURCE_GROUP already exists."
fi

# 2. Create Azure Container Registry (ACR) if it does not exist
echo "Checking Azure Container Registry..."
az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --output none >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating Azure Container Registry..."
    az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true --output none
    if [ $? -eq 0 ]; then
        echo "Azure Container Registry $ACR_NAME created successfully."
    else
        echo "Failed to create Azure Container Registry $ACR_NAME."
        exit 1
    fi
else
    echo "Azure Container Registry $ACR_NAME already exists."
fi

# 3. Create AKS Cluster if it does not exist
echo "Checking AKS Cluster..."
az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --output none >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating AKS Cluster..."
    az aks create \
      --resource-group $RESOURCE_GROUP \
      --name $CLUSTER_NAME \
      --node-count $NODE_COUNT \
      --node-vm-size $VM_SIZE \
      --enable-managed-identity \
      --generate-ssh-keys \
      --attach-acr $ACR_NAME \
      --enable-addons monitoring \
      --workspace-resource-id $WORKSPACE_ID \
      --enable-cluster-autoscaler \
      --min-count 1 \
      --max-count 5 \
      --output none
    if [ $? -eq 0 ]; then
        echo "AKS Cluster $CLUSTER_NAME created successfully."
    else
        echo "Failed to create AKS Cluster $CLUSTER_NAME."
        exit 1
    fi
else
    echo "AKS Cluster $CLUSTER_NAME already exists."
fi

# 4. Verify the Azure Monitoring addon
echo "Verifying Azure Monitoring addon..."
az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query "addonProfiles.omsagent.enabled" --output tsv | grep true >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Enabling Azure Monitoring addon..."
    az aks enable-addons --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --addons monitoring --workspace-resource-id $WORKSPACE_ID --output none
    if [ $? -eq 0 ]; then
        echo "Azure Monitoring addon enabled successfully."
    else
        echo "Failed to enable Azure Monitoring addon."
        exit 1
    fi
else
    echo "Azure Monitoring addon is already enabled."
fi

# Additional steps for backup and automation can remain the same as the original script
# ...
