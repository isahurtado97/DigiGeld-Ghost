// Parameters
param deployAll bool = false
param deployAcr bool = true
param deployLogAnalytics bool = true
param deployKeyVault bool = true
param location string = 'northeurope'
param acrName string = 'myacrname' // Must be globally unique
param logAnalyticsWorkspaceName string = 'my-log-analytics'
param keyVaultName string = 'my-keyvault' // Must be globally unique

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = if (deployAcr || deployAll) {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (deployLogAnalytics || deployAll) {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = if (deployKeyVault || deployAll) {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
    ]
  }
}

// Outputs
output acrId string = acr.id
output logAnalyticsId string = logAnalytics.id
output keyVaultId string = keyVault.id
