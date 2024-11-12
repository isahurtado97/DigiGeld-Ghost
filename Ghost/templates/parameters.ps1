$parameters = @{
    deployAll = $true
    deployAks = $true
    deployAcr = $true
    deployLogAnalytics = $true
    deployKeyVault = $true
    deployAppGateway = $true
    acrName="dgacrprod"
    aksClusterName="dg-aks-prod"
    location="northeurope"
    logAnalyticsWorkspaceName="dg-rg-prod-Workspace"
    KeyvaultName="dg-rg-prod-vault"
}
