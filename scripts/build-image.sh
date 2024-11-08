ACR_NAME=$1
IMAGE_PATH = $2
DOCKER_REGISTRY_URL="${ACR_NAME}.azurecr.io"
DOCKER_IMAGE="${DOCKER_REGISTRY_URL}/${CONTAINER_IMAGE}"
CONTAINER_IMAGE="ghost-app:$3"

# 3. Login en Azure Container Registry
az acr login --name $ACR_NAME

# 4. Construir imagen Docker (ojo con el path)
echo -e "Changing to image path $IMAGE_PATH"
cd $IMAGE_PATH
docker build -t $DOCKER_IMAGE .
# 5. Subir imagen a ACR
docker push $DOCKER_IMAGE