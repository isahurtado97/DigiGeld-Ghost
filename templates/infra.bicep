param location string = 'northeurope'
param aksClusterName string = 'dg-aks-prod'
param cosmosDbAccountName string = 'dg-cosmosDbAccount'
param frontDoorName string = 'dg-fd-prod'

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

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: cosmosDbAccountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
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
              id: frontDoor.id
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
              id: frontDoor.properties.backendPools[0].id
            }
          }
        }
      }
    ]
  }
}
