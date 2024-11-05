@description('The location for all resources.')
param location string = 'northeurope'

@description('The name of the AKS cluster.')
param aksClusterName string = 'dg-aks-prod'

@description('The name of the Cosmos DB account.')
param cosmosDbAccountName string = 'DGCosmosDBAccount'

@description('The name of the Azure Front Door.')
param frontDoorName string = 'dg-fd-prod'

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
    servicePrincipalProfile: {
      clientId: '<ServicePrincipalClientID>'
      secret: '<ServicePrincipalSecret>'
    }
  }
}

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: frontDoorName
  location: location
  properties: {
    backendPools: [
      {
        name: 'myBackendPool'
        properties: {
          backends: [
            {
              address: 'myapp.azurewebsites.net'
              httpPort: 80
              httpsPort: 443
            }
          ]
        }
      }
    ]
    frontendEndpoints: [
      {
        name: 'myFrontEnd'
        properties: {
          hostName: '${frontDoorName}.azurefd.net'
        }
      }
    ]
    routingRules: [
      {
        name: 'route1'
        properties: {
          frontendEndpoints: [
            {
              id: '${frontDoor.id}/frontendEndpoints/myFrontEnd'
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            odataType: '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            backendPool: {
              id: '${frontDoor.id}/backendPools/myBackendPool'
            }
          }
        }
      }
    ]
  }
}
