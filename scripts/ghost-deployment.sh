#!/bin/bash
#Variables
RESOURCE_GROUP=$1
CLUSTER_NAME=$2
IMAGE_YAML=$3
#Script
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
kubectl apply -f $IMAGE_YAML