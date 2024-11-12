#!/bin/bash
#Variables
RESOURCE_GROUP=$1
CLUSTER_NAME=$2
GHOST_YAML=$3
$MONITORING_YAML =$4
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
helm repo add spv-charts https://charts.spvapi.no
helm repo update
helm install akv2k8s spv-charts/akv2k8s --namespace akv2k8s --create-namespace
kubectl apply -f $GHOST_YAML
kubectl apply -f $MONITORING_YAML
