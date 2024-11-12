$parameters = @{
    deployAll = $false
    deployAks = $true
    deployAcr = $true
    deployLogAnalytics = $false
    deployKeyVault = $true
    deployAppGateway = $false
    aksClusterName = "myNewAksCluster"
    acrName = "myUniqueAcrName"
    location = "northeurope"
    logAnalyticsWorkspaceName = "myLogAnalytics"
    keyVaultName = "myKeyVault"
}
