// Parameters
param deployAll bool = false
param deployAks bool = true
param deployAcr bool = true
param deployLogAnalytics bool = true
param deployKeyVault bool = true
param location string = 'northeurope'
param aksClusterName string = 'my-aks-cluster'
param acrName string = 'myacrname' // Must be globally unique
param logAnalyticsWorkspaceName string = 'my-log-analytics'
param keyVaultName string = 'my-keyvault' // Must be globally unique
@description('Permissions for keys')
param keyPermissions array = [
  'get'
  'list'
]

@description('Permissions for secrets')
param secretPermissions array = [
  'get'
  'list'
]

@description('Permissions for certificates')
param certificatePermissions array = [
  'get'
  'list'
]

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
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
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

// AKS Cluster
resource aks 'Microsoft.ContainerService/managedClusters@2023-03-01' = if (deployAks || deployAll) {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: '${aksClusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
      }
    ]
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.2.0/24'
      dnsServiceIP: '10.0.2.10'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
        }
      }
    }
  }
  dependsOn: [
    logAnalytics
  ]
}

// Outputs
output acrId string = acr.id
output logAnalyticsId string = logAnalytics.id
output keyVaultId string = keyVault.id
output aksId string = aks.id
