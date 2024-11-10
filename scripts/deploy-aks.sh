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

# Create AKS Cluster and Attach ACR
echo "Creating AKS Cluster..."
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 3 \
  --node-vm-size "Standard_DS2_v2" \
  --enable-managed-identity \
  --generate-ssh-keys \
  --attach-acr $ACR_NAME \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5
