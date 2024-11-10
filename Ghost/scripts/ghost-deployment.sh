#!/bin/bash
#Variables
RESOURCE_GROUP=$1
CLUSTER_NAME=$2
IMAGE_YAML=$3
NAMESPACE="ghost"
#Script
#sed -i "s/password/${NEW_PASSWORD}/g" "$FILE_PATH"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
# Create Namespace
if [ -z "$NAMESPACE" ]; then
  echo "Namespace name not provided."
  exit 1
fi
# Check if the namespace exists
kubectl get namespace $NAMESPACE >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Namespace '$NAMESPACE' does not exist. Creating namespace..."
  kubectl create namespace $NAMESPACE

  if [ $? -eq 0 ]; then
    echo "Namespace '$NAMESPACE' created successfully."
  else
    echo "Failed to create namespace '$NAMESPACE'."
    exit 1
  fi
else
  echo "Namespace '$NAMESPACE' already exists."
fi
#Configure and create ghost deployment
kubectl apply -f $IMAGE_YAML
appGatewayId=$(az network application-gateway show --name "$CLUSTER_NAME-appgw" --resource-group "$CLUSTER_NAME" --query "id" -o tsv)
az aks enable-addons --resource-group $RESOURCE_GROUP --name "$CLUSTER_NAME" --addons ingress-appgw --appgw-id $appGatewayId