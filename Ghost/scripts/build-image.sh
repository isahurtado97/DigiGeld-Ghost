#!/bin/bash

# Input parameters
ACR_NAME=$1                # Azure Container Registry name
IMAGE_PATH=$2              # Path to Dockerfile
TAG=$3                     # Tag for the container image

# Derived variables
CONTAINER_IMAGE="ghost-app:${TAG}"           # Image name with tag
DOCKER_REGISTRY_URL="${ACR_NAME}.azurecr.io" # Full registry URL
DOCKER_IMAGE="${DOCKER_REGISTRY_URL}/${CONTAINER_IMAGE}" # Full image path

# 1. Login to Azure Container Registry
echo "Logging into Azure Container Registry: ${ACR_NAME}"
az acr login --name $ACR_NAME

# 2. Navigate to the image path
echo -e "Changing to image path: $IMAGE_PATH"
cd $IMAGE_PATH || { echo "Directory $IMAGE_PATH not found."; exit 1; }

# 3. Build Docker Image
echo "Building Docker image: ${DOCKER_IMAGE}"
docker build -t $DOCKER_IMAGE .

# 4. Push Docker Image to ACR
echo "Pushing Docker image to ACR: ${DOCKER_IMAGE}"
docker push $DOCKER_IMAGE

echo "Docker image ${DOCKER_IMAGE} successfully pushed to ${DOCKER_REGISTRY_URL}"
