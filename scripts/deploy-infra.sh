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
CLUSTER_NAME=${4:-"example"}          # Default value if not provided
NODE_COUNT=${5:-3}                      # Default node count if not provided
VM_SIZE=${6:-"Standard_DS2_v2"}         # Default VM size if not provided

# 1. Create Resource Group
echo "Creating Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# 2. Create Azure Container Registry (ACR)
echo "Creating Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

# 3. Create AKS Cluster and Attach ACR
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
  --max-count 5
