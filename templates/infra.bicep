@description('The location for all resources.')
param location string = 'eastus'

@description('The name of the AKS cluster.')
param aksClusterName string = 'dg-aks-prod'

@description('The name of the Cosmos DB account.')
param cosmosDbAccountName string = 'dgcosmosdbaccount'

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: cosmosDbAccountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    createMode: 'Default'
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-03-01' = {
  name: aksClusterName
  location: location
  properties: {
    kubernetesVersion: '1.25.2'
    dnsPrefix: '${aksClusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 2
        vmSize: 'Standard_DS2_v2'
      }
    ]
  }
}
