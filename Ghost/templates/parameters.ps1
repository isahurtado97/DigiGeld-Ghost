$parameters = @{
    deployAll = $false
    deployAks = $true
    deployAcr = $true
    deployLogAnalytics = $false
    deployKeyVault = $true
    deployAppGateway = $false
    $parameters.acrName=""
    $parameters.aksClusterName=""
    $parameters.location=""
    $parameters.logAnalyticsWorkspaceName=""
    $parameters.KeyvaultName=""
}
