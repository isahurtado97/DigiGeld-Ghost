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
NODE_COUNT=${5:-3}  # Default node count if not provided
VM_SIZE=${6:-"Standard_DS2_v2"}  # Default VM size if not provided

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
      --enable-cluster-autoscaler \
      --min-count 1 \
      --node-resource-group $CLUSTER_NAME \
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

# 4. Enable Azure Monitoring for observability if not already enabled
echo "Enabling Azure Monitoring for observability..."
az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query "addonProfiles.omsagent.enabled" --output tsv | grep true >/dev/null 2>&1
if [ $? -ne 0 ]; then
    az aks enable-addons --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --addons monitoring --workspace-resource-id "/subscriptions/your-subscription-id/resourcegroups/your-resource-group/providers/Microsoft.OperationalInsights/workspaces/$CLUSTER_NAME-ws" --output none
    az monitor app-insights component create --app $CLUSTER_NAME-ai --location $LOCATION --resource-group $RESOURCE_GROUP --application-type web --output none
else
    echo "Azure Monitoring addon is already enabled."
fi

# 5. Set up Azure Backup Vault if it does not exist
echo "Checking Azure Backup Vault..."
az backup vault show --name $CLUSTER_NAME-bckp-vault --resource-group $RESOURCE_GROUP --output none >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating Azure Backup Vault..."
    az backup vault create --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME-bckp-vault --location $LOCATION --output none
    if [ $? -eq 0 ]; then
        echo "Backup vault $CLUSTER_NAME-bckp-vault created successfully."
    else
        echo "Failed to create backup vault $CLUSTER_NAME-bckp-vault."
        exit 1
    fi
else
    echo "Backup vault $CLUSTER_NAME-bckp-vault already exists."
fi

# Note: Remove the invalid command for enabling AKS cluster protection

# 6. Automated cleanup serverless task
echo "Setting up Azure Automation for cleanup task..."

# Check if Automation Account exists
az automation account show --name $CLUSTER_NAME-automation --resource-group $RESOURCE_GROUP --output none >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating Azure Automation Account..."
    az automation account create --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME-automation --location $LOCATION --output none
    if [ $? -eq 0 ]; then
        echo "Azure Automation Account $CLUSTER_NAME-automation created successfully."
    else
        echo "Failed to create Azure Automation Account $CLUSTER_NAME-automation."
        exit 1
    fi
else
    echo "Azure Automation Account $CLUSTER_NAME-automation already exists."
fi

# Check if Runbook exists
az automation runbook show --automation-account-name $CLUSTER_NAME-automation --resource-group $RESOURCE_GROUP --name DeleteGhostPosts --output none >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating Azure Automation Runbook..."
    az automation runbook create --resource-group $RESOURCE_GROUP --automation-account-name $CLUSTER_NAME-automation --name DeleteGhostPosts --type PowerShell --output none
    if [ $? -eq 0 ]; then
        echo "Azure Automation Runbook DeleteGhostPosts created successfully."
        
        # Upload the PowerShell script content
        az automation runbook update \
          --resource-group $RESOURCE_GROUP \
          --automation-account-name $CLUSTER_NAME-automation \
          --name DeleteGhostPosts \
          --content-url "file://$(pwd)/DeleteGhostPosts.ps1" \
          --output none

        # Publish the runbook
        az automation runbook publish --resource-group $RESOURCE_GROUP --automation-account-name $CLUSTER_NAME-automation --name DeleteGhostPosts --output none
    else
        echo "Failed to create Azure Automation Runbook DeleteGhostPosts."
        exit 1
    fi
else
    echo "Azure Automation Runbook DeleteGhostPosts already exists."
fi


echo "Script completed successfully."
