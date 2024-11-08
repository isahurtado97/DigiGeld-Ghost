#!/bin/bash
#Variables
RESOURCE_GROUP=$1
CLUSTER_NAME=$2
IMAGE_YAML=$3
#Script
#sed -i "s/password/${NEW_PASSWORD}/g" "$FILE_PATH"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
kubectl apply -f $IMAGE_YAML