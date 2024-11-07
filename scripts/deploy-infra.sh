# Variables
RESOURCE_GROUP="dg-rg-prod"
LOCATION="northeurope" # e.g., eastus, westus
APP_SERVICE_PLAN="dg-asp-prod-neu"
WEBAPP_NAME="dg-web-prod-neu"
SQL_SERVER_NAME="dg-sql-prod-neu"
SQL_DATABASE_NAME="ghostdb"
SQL_ADMIN_USER="dg-admin-sql"
SQL_ADMIN_PASSWORD="jpX6FRy8GwCx6ZErcZcs"
GHOST_URL="dg-web-prod-neu.azurewebsites.net" # e.g., https://<YOUR_APP_NAME>.azurewebsites.net

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create App Service Plan
az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --sku P1v2 --is-linux

# Create Azure SQL Server
az sql server create --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --admin-user $SQL_ADMIN_USER --admin-password $SQL_ADMIN_PASSWORD

# Create Azure SQL Database
az sql db create --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --name $SQL_DATABASE_NAME --service-objective S0

# Create Azure App Service
az webapp create --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --name $WEBAPP_NAME --runtime "NODE:16-lts"

# Configure App Settings
az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME --settings DATABASE_URL="Server=tcp:${SQL_SERVER_NAME}.database.windows.net,1433;Initial Catalog=${SQL_DATABASE_NAME};Persist Security Info=False;User ID=${SQL_ADMIN_USER};Password=${SQL_ADMIN_PASSWORD};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" GHOST_URL=$GHOST_URL NODE_ENV=production
az webapp deployment source config --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --repo-url https://github.com/isahurtado97/Ghost.git --branch main --manual-integration

# Enable Managed Identity (if required)
az webapp identity assign --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME

# Optional: Configure CORS if needed
az webapp cors add --resource-group $RESOURCE_GROUP --name $WEBAPP_NAME --allowed-origins "*"

# Output the Ghost URL
echo "Ghost deployed successfully at: https://$WEBAPP_NAME.azurewebsites.net"
