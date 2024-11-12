param vaults_dg_aks_prod_vault_name string = 'dg-aks-prod-vault'
param registries_dgacrprod_name string = 'dgacrprod'
param managedClusters_dg_aks_prod_name string = 'dg-aks-prod'
param applicationGateways_dg_aks_prod_appgw_externalid string = ''
param workspaces_dg_aks_prod_Workspace_externalid string = ''
param publicIPAddresses_bd1aec30_36bc_48ef_8301_435ccbf0d11f_externalid string = ''
param resourceGroupName string = ''

resource registries_dgacrprod_name_resource 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: registries_dgacrprod_name
  location: 'northeurope'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
      azureADAuthenticationAsArmPolicy: {
        status: 'enabled'
      }
      softDeletePolicy: {
        retentionDays: 7
        status: 'disabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
    metadataSearch: 'Disabled'
  }
}

resource managedClusters_dg_aks_prod_name_resource 'Microsoft.ContainerService/managedClusters@2024-06-02-preview' = {
  name: managedClusters_dg_aks_prod_name
  location: 'northeurope'
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.29'
    dnsPrefix: '${managedClusters_dg_aks_prod_name}-dns'
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        maxCount: 5
        minCount: 1
        enableAutoScaling: true
        orchestratorVersion: '1.29'
        enableNodePublicIP: false
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        upgradeSettings: {
          maxSurge: '10%'
        }
        enableFIPS: false
        powerState: {
          code: 'Running'
        }
        enableUltraSSD: false
        enableEncryptionAtHost: false
      }
    ]
    linuxProfile: {
      adminUsername: 'azureuser'
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXBsTl2i8/iqntE64XapRpSyqxRbRaaw7mxbeHlUiPLZrGnHXIzKlc2YkT0XPMt9+Xh5jRjztpTsx45FrZ06O0qMlf4A9eVoRTp738nHOOrdWBeWa5I2rm09XVp9kCWAaMLsSovKHpWy5PNpTvMr/PiafossNar0yLmKhwBFdVz0HMzX/7h7EYZpey37zr4JLh23L+E/gNmyPeAVpbpAULQUKrr7+6SENbqIFIqM59vMhco2nFyLPdOhMjwPot0lmLsboIgcTDGi3ySfE+Qb2ThXgQ3MjlGTFIc79PKS5/1xipjg61H+jXb0iDEWYQiWtN6234FqHWwugY/RTKYfp7'
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azurepolicy: {
        enabled: true
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: applicationGateways_dg_aks_prod_appgw_externalid
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspaces_dg_aks_prod_Workspace_externalid
        }
      }
    }
    nodeResourceGroup: '${resourceGroupName}'
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
      }
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      outboundType: 'loadBalancer'
    }
    autoScalerProfile: {
      'balance-similar-node-groups': 'true'
      'expander': 'random'
      'scale-down-delay-after-add': '10m'
      'scale-down-unneeded-time': '10m'
      'scale-down-utilization-threshold': '0.5'
    }
    autoUpgradeProfile: {
      nodeOSUpgradeChannel: 'NodeImage'
    }
    oidcIssuerProfile: {
      enabled: true
    }
    workloadIdentityProfile: {
      enabled: true // Enable Workload Identity
    }
    storageProfile: {
      diskCSIDriver: {
        enabled: true
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
      }
    }
    azureMonitorProfile: {
      metrics: {
        enabled: true
      }
      containerInsights: {
        enabled: true
        logAnalyticsWorkspaceResourceId: workspaces_dg_aks_prod_Workspace_externalid
      }
    }
  }
}


resource vaults_dg_aks_prod_vault_name_resource 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: vaults_dg_aks_prod_vault_name
  location: 'northeurope'
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: 'd3aff2ea-62b8-4b8e-819f-fbb80455d597'
    accessPolicies: []
    enabledForDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    vaultUri: 'https://${vaults_dg_aks_prod_vault_name}.vault.azure.net/'
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

resource registries_dgacrprod_name_repositories_admin 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-11-01-preview' = {
  parent: registries_dgacrprod_name_resource
  name: '_repositories_admin'
  properties: {
    description: 'Can perform all read, write and delete operations on the registry'
    actions: [
      'repositories/*/metadata/read'
      'repositories/*/metadata/write'
      'repositories/*/content/read'
      'repositories/*/content/write'
      'repositories/*/content/delete'
    ]
  }
}

resource registries_dgacrprod_name_repositories_pull 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-11-01-preview' = {
  parent: registries_dgacrprod_name_resource
  name: '_repositories_pull'
  properties: {
    description: 'Can pull any repository of the registry'
    actions: [
      'repositories/*/content/read'
    ]
  }
}

resource registries_dgacrprod_name_repositories_pull_metadata_read 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-11-01-preview' = {
  parent: registries_dgacrprod_name_resource
  name: '_repositories_pull_metadata_read'
  properties: {
    description: 'Can perform all read operations on the registry'
    actions: [
      'repositories/*/content/read'
      'repositories/*/metadata/read'
    ]
  }
}

resource registries_dgacrprod_name_repositories_push 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-11-01-preview' = {
  parent: registries_dgacrprod_name_resource
  name: '_repositories_push'
  properties: {
    description: 'Can push to any repository of the registry'
    actions: [
      'repositories/*/content/read'
      'repositories/*/content/write'
    ]
  }
}

resource registries_dgacrprod_name_repositories_push_metadata_write 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-11-01-preview' = {
  parent: registries_dgacrprod_name_resource
  name: '_repositories_push_metadata_write'
  properties: {
    description: 'Can perform all read and write operations on the registry'
    actions: [
      'repositories/*/metadata/read'
      'repositories/*/metadata/write'
      'repositories/*/content/read'
      'repositories/*/content/write'
    ]
  }
}

resource managedClusters_dg_aks_prod_name_nodepool1 'Microsoft.ContainerService/managedClusters/agentPools@2024-06-02-preview' = {
  parent: managedClusters_dg_aks_prod_name_resource
  name: 'nodepool1'
  properties: {
    count: 3
    vmSize: 'Standard_DS2_v2'
    osDiskSizeGB: 128
    osDiskType: 'Managed'
    kubeletDiskType: 'OS'
    maxPods: 110
    type: 'VirtualMachineScaleSets'
    maxCount: 5
    minCount: 1
    enableAutoScaling: true
    powerState: {
      code: 'Stopped'
    }
    orchestratorVersion: '1.29'
    enableNodePublicIP: false
    mode: 'System'
    enableEncryptionAtHost: false
    enableUltraSSD: false
    osType: 'Linux'
    osSKU: 'Ubuntu'
    upgradeSettings: {
      maxSurge: '10%'
    }
    enableFIPS: false
    securityProfile: {
      sshAccess: 'LocalUser'
      enableVTPM: false
      enableSecureBoot: false
    }
  }
}
