# Variables de configuración
RESOURCE_GROUP="dg-rg-prod"
LOCATION="northeurope" 
ACR_NAME="dgacrprod"
CONTAINER_IMAGE="ghost-app:latest"
DOCKER_REGISTRY_URL="${ACR_NAME}.azurecr.io"
DOCKER_IMAGE="${DOCKER_REGISTRY_URL}/${CONTAINER_IMAGE}"

# 1. Crear grupo de recursos
az group create --name $RESOURCE_GROUP --location $LOCATION

# 2. Crear Azure Container Registry (ACR)
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

# 3. Login en Azure Container Registry
az acr login --name $ACR_NAME

# 4. Construir imagen Docker (ojo con el path)
docker build -t $DOCKER_IMAGE .

# 5. Subir imagen a ACR
docker push $DOCKER_IMAGE
 
# 13 Configurar autoescalado (opcional según tus necesidades)
az monitor autoscale create --resource-group $RESOURCE_GROUP --resource $WEB_APP_NAME \
  --resource-type Microsoft.Web/sites --name "AutoScale" --min-count 1 --max-count 5 --count 1

# 14 Configurar una regla de escalado basada en el uso de CPU
az monitor autoscale rule create --resource-group $RESOURCE_GROUP --autoscale-name "AutoScale" \
  --condition "Percentage CPU > 70" --scale out 1 --cooldown 5

az monitor autoscale rule create --resource-group $RESOURCE_GROUP --autoscale-name "AutoScale" \
  --condition "Percentage CPU < 30" --scale in 1 --cooldown 5

# 15. Habilitar Application Insights en la Web App para monitoreo
az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME --settings \
  APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show --app $WEB_APP_NAME --resource-group $RESOURCE_GROUP --query instrumentationKey -o tsv)

# 16. Crear el recurso Function App
az functionapp create --resource-group $RESOURCE_GROUP --consumption-plan-location $LOCATION \
  --name DigiGeldDeletePosts --storage-account $STORAGE_ACCOUNT --runtime node

# 16. Desplegar la función que usa la API de Ghost para borrar publicaciones
# (Este script asume que tienes un archivo `deletePosts.zip` que contiene el código de la función)

az functionapp deployment source config-zip --name DigiGeldDeletePosts --resource-group $RESOURCE_GROUP \
  --src deletePosts.zip
#>