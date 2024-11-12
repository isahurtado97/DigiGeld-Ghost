// Parameters
param deployAll bool = false
param deployAks bool = true
param deployAcr bool = true
param deployLogAnalytics bool = true
param deployKeyVault bool = true
param deployAppGateway bool = true
param location string = 'northeurope'
param aksClusterName string = 'my-aks-cluster'
param acrName string = 'myacrname' // Must be globally unique
param logAnalyticsWorkspaceName string = 'my-log-analytics'
param keyVaultName string = 'my-keyvault' // Must be globally unique
param appGatewayName string = '${aksClusterName}-appgw'

// Networking Parameters
param appGatewayVnetName string = '${aksClusterName}-appgw-vnet'
param aksVnetName string = '${aksClusterName}-aks-vnet'
param appGatewaySubnetName string = 'appgw-subnet'
param aksSubnetName string = 'aks-subnet'
param appGatewayVnetAddressPrefix string = '10.1.0.0/16'
param aksVnetAddressPrefix string = '10.0.0.0/16'
param publicIpName string = '${aksClusterName}-pip'

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
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-04-01' = if (deployLogAnalytics || deployAll) {
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
resource keyVault 'Microsoft.KeyVault/vaults@2023-01-01' = if (deployKeyVault || deployAll) {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}

// Virtual Network for Application Gateway
resource appGatewayVnet 'Microsoft.Network/virtualNetworks@2023-02-01' = if (deployAppGateway || deployAll) {
  name: appGatewayVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        appGatewayVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
}

// Virtual Network for AKS
resource aksVnet 'Microsoft.Network/virtualNetworks@2023-02-01' = if (deployAks || deployAll) {
  name: aksVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        aksVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

// VNet Peering from AKS VNet to Application Gateway VNet
resource aksToAppGatewayPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-02-01' = {
  name: '${aksVnetName}/to-${appGatewayVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: appGatewayVnet.id
    }
  }
  dependsOn: [
    aksVnet
    appGatewayVnet
  ]
}

// VNet Peering from Application Gateway VNet to AKS VNet
resource appGatewayToAksPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-02-01' = {
  name: '${appGatewayVnetName}/to-${aksVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: aksVnet.id
    }
  }
  dependsOn: [
    aksVnet
    appGatewayVnet
  ]
}

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-02-01' = if (deployAppGateway || deployAll) {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Application Gateway
resource appGateway 'Microsoft.Network/applicationGateways@2023-02-01' = if (deployAppGateway || deployAll) {
  name: appGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'gatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewayVnet.properties.subnets[0].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIpConfig'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
  dependsOn: [
    appGatewayVnet
    publicIp
  ]
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
        vnetSubnetID: aksVnet.properties.subnets[0].id
        mode: 'System'
      }
    ]
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
  }
  dependsOn: [
    aksVnet
    logAnalytics
  ]
}

// Outputs
output acrId string = acr.id
output logAnalyticsId string = logAnalytics.id
output keyVaultId string = keyVault.id
output aksId string = aks.id
output appGatewayId string = appGateway.id
